resource "aws_lambda_function" "scale_trigger" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = "${var.service_name}-scale-trigger"
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = 60

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

  vpc_config {
    subnet_ids         = [var.subnet_ids[1]]
    security_group_ids = var.security_group_ids
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
          "servicediscovery:ListInstances",
          "servicediscovery:GetInstancesHealthStatus"
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
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
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
    filename = "index.mjs"
  }
}

locals {
  lambda_code = <<-EOF
import http from 'http';
import { ECSClient, UpdateServiceCommand, DescribeServicesCommand } from '@aws-sdk/client-ecs';
import { ServiceDiscoveryClient, ListInstancesCommand, GetInstancesHealthStatusCommand } from '@aws-sdk/client-servicediscovery';

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
        const ecsClient = new ECSClient({ requestTimeout: 10000 });
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

async function getHealthyInstance(serviceId, requestId) {
    try {
        const sdClient = new ServiceDiscoveryClient({ requestTimeout: 10000 });
        
        // Step 1: List all instances
        log('DEBUG', 'Starting ListInstances call', { requestId });
        const listCommand = new ListInstancesCommand({ ServiceId: serviceId });
        const listResponse = await sdClient.send(listCommand);
        const instances = listResponse.Instances || [];
        log('DEBUG', 'ListInstances response', { requestId, totalInstances: instances.length, instances: instances.map(inst => ({ id: inst.Id, attributes: inst.Attributes })) }); // Log full details for debug

        if (instances.length === 0) {
            return null;
        }

        // Step 2: Get health statuses for the instances
        log('DEBUG', 'Starting GetInstancesHealthStatus call', { requestId });
        const healthCommand = new GetInstancesHealthStatusCommand({
            ServiceId: serviceId,
            Instances: instances.map(inst => inst.Id) // Get health for all listed instances
        });
        const healthResponse = await sdClient.send(healthCommand);
        const healthMap = healthResponse.Status || {};
        log('DEBUG', 'Health statuses', { requestId, healthMap });

        // Step 3: Filter healthy instances
        const healthyInstances = instances.filter(inst => healthMap[inst.Id] === 'HEALTHY');
        log('DEBUG', 'Filtered healthy instances', { requestId, healthyCount: healthyInstances.length });

        if (healthyInstances.length > 0) {
            const instance = healthyInstances[0]; // Pick first healthy
            const ip = instance.Attributes.AWS_INSTANCE_IPV4;
            const port = instance.Attributes.AWS_INSTANCE_PORT || process.env.TARGET_PORT;
            log('INFO', 'Selected healthy instance', { requestId, ip: ip.substring(0, ip.lastIndexOf('.')) + '.xxx', port });
            return { ip, port: parseInt(port) };
        }
        return null;
    } catch (error) {
        log('ERROR', 'Failed to discover healthy instances', { requestId, error: error.message });
        throw error;
    }
}

export const handler = async (event, context) => {
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

        // --- Step 2: Discover target instance ---
        const serviceId = process.env.CLOUD_MAP_SERVICE_ID;
        let target = await getHealthyInstance(serviceId, requestId);
        let scaleUpAttempted = false;

        if (!target) {
            log('WARN', 'No healthy instances found, attempting to scale up ECS', { requestId });
            await scaleUpEcsService(process.env.ECS_CLUSTER, process.env.ECS_SERVICE, requestId);
            scaleUpAttempted = true;
        }

        // --- Step 3: Retry loop if no instances or after scale-up ---
        let retryAttempts = 0;
        const maxRetryAttempts = 12; // 60s total
        while (!target && retryAttempts < maxRetryAttempts) {
            log('DEBUG', 'Polling for healthy instances', { requestId, attempt: retryAttempts + 1 });
            await new Promise(resolve => setTimeout(resolve, 5000));
            target = await getHealthyInstance(serviceId, requestId);
            retryAttempts++;
        }

        if (!target) {
            log('ERROR', 'Timeout waiting for healthy instances', { requestId });
            return {
                statusCode: 503,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ error: 'No healthy service instances available', requestId })
            };
        }

        log('INFO', 'Proxying request to discovered instance', {
            requestId,
            target: `http://$${target.ip}:$${target.port}$${fullPath}`,
            method: httpMethod
        });

        // --- Step 4: Prepare the request for forwarding ---
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

        cleanHeaders['Host'] = target.ip;

        if (requestBody) {
            cleanHeaders['Content-Length'] = Buffer.byteLength(requestBody);
        }
        log('DEBUG', 'Forwarding request with cleaned headers', { requestId, headers: cleanHeaders });

        // --- Step 5: Make the outbound HTTP request ---
        const response = await makeHttpRequest({
            hostname: target.ip,
            port: target.port,
            path: fullPath,
            method: httpMethod,
            headers: cleanHeaders,
            body: requestBody,
            timeout: (context.getRemainingTimeInMillis() - 1000)
        });
        
        log('INFO', 'Received response from target service', { requestId, statusCode: response.statusCode, headers: response.headers });

        // --- Step 6: Return the response to API Gateway ---
        const finalResponse = {
            statusCode: response.statusCode,
            headers: response.headers,
            body: response.body,
            isBase64Encoded: false
        };
        log('INFO', 'Request completed successfully', { requestId, statusCode: finalResponse.statusCode });
        return finalResponse;

    } catch (error) {
        log('ERROR', 'Request processing failed', { requestId, error: error.name, errorMessage: error.message, errorCode: error.code, errorStack: error.stack });

        let statusCode = 500;
        let errorMessage = 'Internal Server Error';

        if (error.code === 'ECONNREFUSED') {
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