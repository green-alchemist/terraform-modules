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

// ==============================================================================
// === SECTION 1: ADDED - The missing makeHttpRequest function ===================
// ==============================================================================
// This function wraps Node's native http.request in a Promise, making it
// easy to use with async/await. It's responsible for making the outbound
// call to the target ECS service.
// ------------------------------------------------------------------------------
function makeHttpRequest(options) {
    return new Promise((resolve, reject) => {
        const req = http.request(options, (res) => {
            const chunks = [];
            res.on('data', (chunk) => chunks.push(chunk));
            res.on('end', () => {
                resolve({
                    statusCode: res.statusCode,
                    headers: res.headers,
                    body: Buffer.concat(chunks).toString('utf8'),
                });
            });
        });

        req.on('error', (error) => {
            log('ERROR', 'Outbound request failed', { error: error.message, code: error.code });
            reject(error);
        });

        req.on('timeout', () => {
            req.destroy();
            reject(new Error('Request timed out'));
        });

        if (options.body) {
            req.write(options.body);
        }
        req.end();
    });
}

async function scaleUpEcsService(cluster, service, requestId) {
    try {
        const ecsClient = new ECSClient();
        const describeCommand = new DescribeServicesCommand({ cluster, services: [service] });
        const serviceDesc = await ecsClient.send(describeCommand);

        if (serviceDesc.services && serviceDesc.services.length > 0) {
            const desiredCount = serviceDesc.services[0].desiredCount;
            if (desiredCount === 0) {
                log('INFO', 'No tasks running, scaling up to 1', { requestId, cluster, service });
                const updateCommand = new UpdateServiceCommand({ cluster, service, desiredCount: 1 });
                await ecsClient.send(updateCommand);
            } else {
                log('DEBUG', 'Tasks already running', { requestId, desiredCount });
            }
        } else {
             throw new Error('ECS Service not found');
        }
    } catch (error) {
        log('ERROR', 'Failed to scale up ECS service', { requestId, error: error.message });
        throw error;
    }
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

        const requestOptions = {
            hostname: serviceEndpoint,
            port: port,
            path: fullPath,
            method: httpMethod,
            headers: cleanHeaders,
            body: requestBody,
            timeout: (context.getRemainingTimeInMillis() - 1000)
        };

        // --- Step 4: Make the outbound HTTP request ---
        try {
            const response = await makeHttpRequest(requestOptions);
            log('INFO', 'Received response from target service', { requestId, statusCode: response.statusCode });

            // --- Step 5: Return the response to API Gateway ---
            return {
                statusCode: response.statusCode,
                headers: response.headers,
                body: response.body,
                isBase64Encoded: false
            };

        } catch (error) {
            if (error.code === 'ENOTFOUND') {
                log('WARN', 'No service endpoints found, attempting to scale up ECS', { requestId });
                await scaleUpEcsService(process.env.ECS_CLUSTER, process.env.ECS_SERVICE, requestId);

                // --- Retry the request after scale-up ---
                const maxRetryAttempts = 12;
                const retryDelayMs = 5000; // 5 seconds

                for (let attempt = 1; attempt <= maxRetryAttempts; attempt++) {
                    log('INFO', `Waiting $${retryDelayMs}ms before retry attempt $${attempt}/$${maxRetryAttempts}`, { requestId });
                    // ===============================================================
                    // === SECTION 2: ADDED - Delay between retries ==================
                    // ===============================================================
                    await new Promise(resolve => setTimeout(resolve, retryDelayMs));

                    try {
                        const retryResponse = await makeHttpRequest(requestOptions);
                        log('INFO', 'Retry succeeded after scale-up', { requestId, statusCode: retryResponse.statusCode });
                        // ===============================================================
                        // === SECTION 3: COMPLETED - The rest of the return object ======
                        // ===============================================================
                        return {
                            statusCode: retryResponse.statusCode,
                            headers: retryResponse.headers,
                            body: retryResponse.body,
                            isBase64Encoded: false,
                        };
                    } catch (retryError) {
                        log('WARN', `Retry attempt $${attempt} failed`, { requestId, error: retryError.message });
                        if (attempt === maxRetryAttempts) {
                            // If all retries fail, return a Gateway Timeout error.
                            log('ERROR', 'All retry attempts failed after scale-up.', { requestId });
                            return {
                                statusCode: 504,
                                headers: { 'Content-Type': 'application/json' },
                                body: JSON.stringify({ message: 'Service unavailable. Could not connect after scale-up.' }),
                            };
                        }
                    }
                }
            }
            // If the error was not ENOTFOUND, re-throw to be caught by the outer catch block.
            throw error;
        }
    } catch (error) {
        // Final catch-all for any unhandled errors
        log('ERROR', 'An unhandled error occurred in the handler', { requestId, error: error.message });
        return {
            statusCode: 500,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ message: 'Internal Server Error' })
        };
    }
}EOF
}