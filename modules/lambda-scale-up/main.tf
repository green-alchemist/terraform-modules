resource "aws_lambda_function" "scale_trigger" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "${var.service_name}-scale-trigger"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 60

  environment {
    variables = {
      ECS_CLUSTER               = var.cluster_name
      ECS_SERVICE               = var.service_name
      TARGET_SERVICE_NAME       = var.service_name
      SERVICE_CONNECT_NAMESPACE = var.service_connect_namespace
      TARGET_PORT               = var.target_port
      LOG_LEVEL                 = "DEBUG"
      CLOUD_MAP_SERVICE_ID      = var.cloud_map_service_id
    }
  }
}

resource "aws_iam_role" "lambda" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "servicediscovery:ListInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/.terraform/lambda-${var.service_name}.zip"

  source {
    content  = local.lambda_code
    filename = "index.js"
  }
}

locals {
  lambda_code = <<-EOF
const http = require('http');
const { ECSClient, UpdateServiceCommand, DescribeServicesCommand } = require('@aws-sdk/client-ecs');

const LOG_LEVEL = process.env.LOG_LEVEL || 'INFO';
const LOG_LEVELS = { ERROR: 0, WARN: 1, INFO: 2, DEBUG: 3 };

function log(level, message, data = {}) {
    if (LOG_LEVELS[level] <= LOG_LEVELS[LOG_LEVEL]) {
        console.log(JSON.stringify({
            level,
            message,
            timestamp: new Date().toISOString(),
            ...data
        }));
    }
}

async function scaleUpEcsService(cluster, service, requestId) {
    try {
        const ecsClient = new ECSClient();
        const describeCommand = new DescribeServicesCommand({ cluster, services: [service] });
        const serviceDesc = await ecsClient.send(describeCommand);
        const desiredCount = serviceDesc.services[0].desiredCount;
        if (desiredCount === 0) {
            log('INFO', 'No tasks running, scaling up to 1', { requestId, cluster, service });
            const updateCommand = new UpdateServiceCommand({ cluster, service, desiredCount: 1 });
            await ecsClient.send(updateCommand);
        } else {
            log('DEBUG', 'Tasks already running', { requestId, desiredCount });
        }
    } catch (error) {
        log('ERROR', 'Failed to scale up ECS service', { requestId, error: error.message });
        throw error;
    }
}

function makeHttpRequest(options) {
    return new Promise((resolve, reject) => {
        log('DEBUG', 'Making outbound HTTP request', { options: { ...options, body: '...' } });
        const req = http.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => { body += chunk; });
            res.on('end', () => resolve({ statusCode: res.statusCode, headers: res.headers, body: body }));
        });
        req.on('error', reject);
        req.on('timeout', () => { req.destroy(); reject(new Error('Request timeout')); });
        if (options.body) {
            req.write(options.body);
        }
        req.end();
    });
}

exports.handler = async (event, context) => {
    const requestId = context.awsRequestId;
    log('DEBUG', 'Full incoming request event', { requestId, event });

    try {
        // --- Step 1: Parse incoming request ---
        const requestPath = event.path || event.rawPath || '/';
        const queryStringParameters = event.queryStringParameters || {};
        const httpMethod = event.httpMethod || event.requestContext?.http?.method || 'GET';
        const headers = event.headers || {};
        const body = event.body;
        const isBase64 = event.isBase64Encoded || false;
        log('INFO', 'Parsed incoming request details', { requestId, httpMethod, requestPath });

        const queryString = Object.entries(queryStringParameters)
            .map(([key, value]) => `$${key}=$${encodeURIComponent(value)}`)
            .join('&');

        const fullPath = queryString ? `$${requestPath}?$${queryString}` : requestPath;

        // --- Step 2: Determine target endpoint ---
        const serviceEndpoint = `$${process.env.TARGET_SERVICE_NAME}.$${process.env.SERVICE_CONNECT_NAMESPACE}`;
        const port = parseInt(process.env.TARGET_PORT || '1337');
        log('INFO', 'Determined target endpoint', { requestId, targetHost: serviceEndpoint, targetPort: port });

        log('INFO', 'Proxying request via DNS lookup', {
            requestId,
            target: `http://$${serviceEndpoint}:$${port}$${fullPath}`,
            method: httpMethod
        });

        // --- Step 3: Prepare the request for forwarding ---
        let requestBody = body;
        if (body && isBase64) {
            requestBody = Buffer.from(body, 'base64').toString('utf-8');
        }

        const cleanHeaders = Object.entries(headers).reduce((acc, [key, value]) => {
            const lowerKey = key.toLowerCase();
            if (!['host', 'x-forwarded-for', 'x-forwarded-port', 'x-forwarded-proto', 'x-amzn-trace-id', 'x-amz-cf-id'].includes(lowerKey)) {
                acc[key] = value;
            }
            return acc;
        }, {});

        cleanHeaders['Host'] = serviceEndpoint;

        if (requestBody) {
            cleanHeaders['Content-Length'] = Buffer.byteLength(requestBody);
        }
        log('DEBUG', 'Forwarding request with cleaned headers', { requestId, headers: cleanHeaders });

        // --- Step 4: Make the outbound HTTP request ---
        try {
            const response = await makeHttpRequest({
                hostname: serviceEndpoint,
                port: port,
                path: fullPath,
                method: httpMethod,
                headers: cleanHeaders,
                body: requestBody,
                timeout: (context.getRemainingTimeInMillis() - 1000)
            });

            log('INFO', 'Received response from target service', { requestId, statusCode: response.statusCode, headers: response.headers });

            // --- Step 5: Return the response to API Gateway ---
            const finalResponse = {
                statusCode: response.statusCode,
                headers: response.headers,
                body: response.body,
                isBase64Encoded: false
            };
            log('INFO', 'Request completed successfully', { requestId, statusCode: finalResponse.statusCode });
            return finalResponse;

        } catch (error) {
            if (error.code === 'ENOTFOUND') {
                log('WARN', 'No service endpoints found, attempting to scale up ECS', { requestId });
                await scaleUpEcsService(process.env.ECS_CLUSTER, process.env.ECS_SERVICE, requestId);

                // Retry the request after scale-up
                let retryAttempts = 0;
                const maxRetryAttempts = 12; // 60s total
                while (retryAttempts < maxRetryAttempts) {
                    try {
                        const retryResponse = await makeHttpRequest({
                            hostname: serviceEndpoint,
                            port: port,
                            path: fullPath,
                            method: httpMethod,
                            headers: cleanHeaders,
                            body: requestBody,
                            timeout: (context.getRemainingTimeInMillis() - 1000)
                        });
                        log('INFO', 'Retry succeeded after scale-up', { requestId, statusCode: retryResponse.statusCode });
                        return {
                            statusCode: retryResponse.statusCode,
                            headers: retryResponse.headers,
                            body: retryResponse.body,
                            isBase64Encoded: false
                        };
                    } catch (retryError) {
                        if (retryError.code !== 'ENOTFOUND') {
                            throw retryError;
                        }
                        log('DEBUG', 'Retry attempt failed, waiting', { requestId, attempt: retryAttempts + 1 });
                        await new Promise(resolve => setTimeout(resolve, 5000));
                        retryAttempts++;
                    }
                }

                log('ERROR', 'Timeout waiting for service after scale-up', { requestId });
                return {
                    statusCode: 503,
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ error: 'Service unavailable after scale-up attempt', requestId })
                };
            }
            throw error;
        }

    } catch (error) {
        log('ERROR', 'Request processing failed', { requestId, error: error.name, errorMessage: error.message, errorCode: error.code, errorStack: error.stack });

        let statusCode = 500;
        let errorMessage = 'Internal Server Error';

        if (error.code === 'ENOTFOUND') {
            statusCode = 503;
            errorMessage = 'Service Discovery Failed: The target service could not be found via DNS.';
        } else if (error.code === 'ECONNREFUSED') {
            statusCode = 503;
            errorMessage = 'Service Unavailable: Connection was refused by the target service.';
        } else if (error.code === 'ETIMEDOUT' || error.message === 'Request timeout') {
            statusCode = 504;
            errorMessage = 'Gateway Timeout: The request to the target service timed out.';
        }

        return {
            statusCode: statusCode,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ error: errorMessage, details: error.message, requestId })
        };
    }
};

function makeHttpRequest(options) {
    return new Promise((resolve, reject) => {
        log('DEBUG', 'Making outbound HTTP request', { options: { ...options, body: '...' } });
        const req = http.request(options, (res) => {
            let body = '';
            res.on('data', (chunk) => { body += chunk; });
            res.on('end', () => resolve({ statusCode: res.statusCode, headers: res.headers, body: body }));
        });
        req.on('error', reject);
        req.on('timeout', () => { req.destroy(); reject(new Error('Request timeout')); });
        if (options.body) {
            req.write(options.body);
        }
        req.end();
    });
}
EOF
}