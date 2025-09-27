# modules/lambda-proxy/main.tf

# Lambda function for proxying requests
resource "aws_lambda_function" "proxy" {
  function_name = "${var.project_prefix}-${var.service_name}-proxy"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = merge(
      {
        TARGET_SERVICE_NAME       = var.target_service_name
        SERVICE_CONNECT_NAMESPACE = var.service_connect_namespace
        TARGET_PORT               = var.target_port
        LOG_LEVEL                 = var.log_level
      },
      var.additional_environment_variables
    )
  }

  tracing_config {
    mode = var.xray_tracing_enabled ? "Active" : "PassThrough"
  }

  reserved_concurrent_executions = var.reserved_concurrent_executions

  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc,
    aws_cloudwatch_log_group.lambda,
  ]

  tags = var.tags
}

# Package Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/.terraform/lambda-${var.service_name}.zip"

  source {
    content  = local.lambda_code
    filename = "index.js"
  }
}

# Enhanced Lambda function code
locals {
  lambda_code = var.custom_lambda_code != null ? var.custom_lambda_code : <<-EOF
const http = require('http');
const https = require('https');

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

exports.handler = async (event, context) => {
    const requestId = context.requestId;
    
    log('DEBUG', 'Incoming request', { requestId, event });
    
    try {
        // Parse request details
        const requestPath = event.path || event.rawPath || '/';
        const queryStringParameters = event.queryStringParameters || {};
        const httpMethod = event.httpMethod || event.requestContext?.http?.method || 'GET';
        const headers = event.headers || {};
        const body = event.body;
        const isBase64 = event.isBase64Encoded || false;
        
        // Build query string
        const queryString = Object.entries(queryStringParameters)
            .map(([key, value]) => `$${key}=$${encodeURIComponent(value)}`)
            .join('&');
        
        const fullPath = queryString ? `$${requestPath}?$${queryString}` : requestPath;
        
        // Service Connect endpoint
        const serviceEndpoint = `$${process.env.TARGET_SERVICE_NAME}.$${process.env.SERVICE_CONNECT_NAMESPACE}`;
        const port = parseInt(process.env.TARGET_PORT || '80');
        
        log('INFO', 'Proxying request', {
            requestId,
            target: `http://$${serviceEndpoint}:$${port}$${fullPath}`,
            method: httpMethod
        });
        
        // Prepare request body
        let requestBody = body;
        if (body && isBase64) {
            requestBody = Buffer.from(body, 'base64').toString('utf-8');
        }
        
        // Clean and forward headers
        const cleanHeaders = Object.entries(headers).reduce((acc, [key, value]) => {
            const lowerKey = key.toLowerCase();
            // Skip API Gateway specific headers
            if (!['x-forwarded-for', 'x-forwarded-port', 'x-forwarded-proto', 
                  'x-amzn-trace-id', 'x-amz-cf-id'].includes(lowerKey)) {
                acc[key] = value;
            }
            return acc;
        }, {});
        
        // Set proper host header
        cleanHeaders['Host'] = `$${serviceEndpoint}:$${port}`;
        
        // Add content-length if body exists
        if (requestBody) {
            cleanHeaders['Content-Length'] = Buffer.byteLength(requestBody);
        }
        
        // Forward the request
        const response = await makeHttpRequest({
            hostname: serviceEndpoint,
            port: port,
            path: fullPath,
            method: httpMethod,
            headers: cleanHeaders,
            body: requestBody,
            timeout: (context.getRemainingTimeInMillis() - 1000) // Leave 1s buffer
        });
        
        log('INFO', 'Request completed', {
            requestId,
            statusCode: response.statusCode,
            responseSize: response.body ? response.body.length : 0
        });
        
        // Prepare response headers
        const responseHeaders = {
            ...response.headers,
            'X-Request-Id': requestId
        };
        
        // Add CORS headers if configured
        if (process.env.CORS_ENABLED === 'true') {
            responseHeaders['Access-Control-Allow-Origin'] = process.env.CORS_ORIGIN || '*';
            responseHeaders['Access-Control-Allow-Methods'] = process.env.CORS_METHODS || 'GET,POST,PUT,DELETE,OPTIONS,PATCH';
            responseHeaders['Access-Control-Allow-Headers'] = process.env.CORS_HEADERS || 'Content-Type,Authorization,X-Requested-With';
            responseHeaders['Access-Control-Max-Age'] = process.env.CORS_MAX_AGE || '86400';
            
            if (process.env.CORS_CREDENTIALS === 'true') {
                responseHeaders['Access-Control-Allow-Credentials'] = 'true';
            }
        }
        
        return {
            statusCode: response.statusCode,
            headers: responseHeaders,
            body: response.body,
            isBase64Encoded: false
        };
        
    } catch (error) {
        log('ERROR', 'Request failed', {
            requestId,
            error: error.message,
            stack: error.stack
        });
        
        // Determine error response
        let statusCode = 500;
        let errorMessage = 'Internal Server Error';
        
        if (error.code === 'ECONNREFUSED') {
            statusCode = 503;
            errorMessage = 'Service Unavailable';
        } else if (error.code === 'ETIMEDOUT') {
            statusCode = 504;
            errorMessage = 'Gateway Timeout';
        }
        
        return {
            statusCode: statusCode,
            headers: {
                'Content-Type': 'application/json',
                'X-Request-Id': requestId,
                ...(process.env.CORS_ENABLED === 'true' && {
                    'Access-Control-Allow-Origin': process.env.CORS_ORIGIN || '*'
                })
            },
            body: JSON.stringify({
                error: errorMessage,
                message: error.message,
                requestId: requestId
            })
        };
    }
};

function makeHttpRequest(options) {
    return new Promise((resolve, reject) => {
        const timeout = options.timeout || 30000;
        const protocol = options.port === 443 ? https : http;
        
        const req = protocol.request({
            hostname: options.hostname,
            port: options.port,
            path: options.path,
            method: options.method,
            headers: options.headers,
            timeout: timeout
        }, (res) => {
            let body = '';
            
            res.on('data', (chunk) => {
                body += chunk;
            });
            
            res.on('end', () => {
                resolve({
                    statusCode: res.statusCode,
                    headers: res.headers,
                    body: body
                });
            });
        });
        
        req.on('error', reject);
        req.on('timeout', () => {
            req.destroy();
            reject(new Error('Request timeout'));
        });
        
        if (options.body) {
            req.write(options.body);
        }
        
        req.end();
    });
}
EOF
}

# IAM role for Lambda
resource "aws_iam_role" "lambda" {
  name = "${var.project_prefix}-${var.service_name}-lambda-proxy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# Basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC execution policy
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# X-Ray tracing policy (optional)
resource "aws_iam_role_policy_attachment" "lambda_xray" {
  count      = var.xray_tracing_enabled ? 1 : 0
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# Service discovery policy for ECS Service Connect
resource "aws_iam_role_policy" "service_discovery" {
  count = var.enable_service_discovery_permissions ? 1 : 0
  name  = "${var.project_prefix}-${var.service_name}-service-discovery"
  role  = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "servicediscovery:DiscoverInstances",
          "servicediscovery:GetInstance",
          "servicediscovery:ListInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeServices"
        ]
        Resource = "*"
      }
    ]
  })
}

# Additional IAM policies
resource "aws_iam_role_policy" "additional" {
  for_each = var.additional_iam_policies

  name   = each.key
  role   = aws_iam_role.lambda.id
  policy = each.value
}

# Security group for Lambda
resource "aws_security_group" "lambda" {
  name        = "${var.project_prefix}-${var.service_name}-lambda-proxy"
  description = "Security group for ${var.service_name} Lambda proxy"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_prefix}-${var.service_name}-lambda-proxy"
    }
  )
}

# Egress rule for target service
resource "aws_security_group_rule" "lambda_egress_target" {
  type              = "egress"
  from_port         = var.target_port
  to_port           = var.target_port
  protocol          = "tcp"
  cidr_blocks       = var.target_service_cidr_blocks
  security_group_id = aws_security_group.lambda.id
  description       = "Allow outbound to target service"
}

# Egress rule for HTTPS (AWS services)
resource "aws_security_group_rule" "lambda_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lambda.id
  description       = "Allow HTTPS for AWS services"
}

# Egress rule for DNS
resource "aws_security_group_rule" "lambda_egress_dns" {
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lambda.id
  description       = "Allow DNS resolution"
}

# Additional egress rules
resource "aws_security_group_rule" "lambda_egress_additional" {
  for_each = var.additional_egress_rules

  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = lookup(each.value, "cidr_blocks", null)
  security_group_id = aws_security_group.lambda.id
  description       = lookup(each.value, "description", "Additional egress rule")
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_prefix}-${var.service_name}-proxy"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags
}

# Lambda permission for API Gateway (if API Gateway is being used)
resource "aws_lambda_permission" "api_gateway" {
  count = var.api_gateway_execution_arn != null ? 1 : 0

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.proxy.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}

# Lambda permission for custom invokers
resource "aws_lambda_permission" "custom" {
  for_each = var.lambda_permissions

  statement_id  = each.key
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.proxy.function_name
  principal     = each.value.principal
  source_arn    = lookup(each.value, "source_arn", null)
}

# CloudWatch alarm for Lambda errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.project_prefix}-${var.service_name}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.error_threshold
  alarm_description   = "Lambda function error rate is too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.proxy.function_name
  }

  alarm_actions = var.alarm_actions
  tags          = var.tags
}

# CloudWatch alarm for Lambda throttles
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.project_prefix}-${var.service_name}-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.throttle_threshold
  alarm_description   = "Lambda function is being throttled"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.proxy.function_name
  }

  alarm_actions = var.alarm_actions
  tags          = var.tags
}