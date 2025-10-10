data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
locals {
  strapi_loader = <<-EOF
    import json

    def handler(event, context):
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "text/html"},
            "body": f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Loading Strapi Admin</title>
        <style>
            body {{ display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; font-family: Arial; }}
            .spinner {{ font-size: 24px; }}
        </style>
    </head>
    <body>
        <div class="spinner">Loading Strapi Admin...</div>
        <script>
            async function fetchWithWake(url) {{
                try {{
                    let response = await fetch(url);
                    if (response.status === 202) {{
                        const {{ executionArn, pollUrl }} = await response.json();
                        console.log(`ECS waking up, polling $${pollUrl}...`);
                        while (true) {{
                            const statusRes = await fetch(`$${process.env.API_GATEWAY_URL}$${pollUrl}`);
                            const {{ status, output }} = await statusRes.json();
                            if (status === 'SUCCEEDED') {{
                                console.log('ECS ready, redirecting to $${event['rawPath']}');
                                window.location.href = url; // Redirect to original Strapi path
                                return;
                            }}
                            if (['FAILED', 'TIMED_OUT', 'ABORTED'].includes(status)) {{
                                throw new Error(`Step Functions failed: $${status}, $${output}`);
                            }}
                            await new Promise(resolve => setTimeout(resolve, 5000));
                        }}
                    }} else {{
                        window.location.href = url; // Already warm, redirect
                    }}
                }} catch (error) {{
                    console.error('Error:', error);
                    document.body.innerHTML = `<div>Error: $${error.message}</div>`;
                }}
            }}
            fetchWithWake('$${event['rawPath'] || '/admin'}');
        </script>
    </body>
    </html>
    """
        }
    EOF

  status_poller = <<-EOF
    import json
    import boto3
    def handler(event, context):
        sfn_client = boto3.client('stepfunctions')
        execution_id = event['pathParameters']['executionId']
        execution_arn = f"arn:aws:states:$${event['requestContext']['region']}:$${event['requestContext']['accountId']}:execution:$${event['requestContext']['stage']}:$${execution_id}"
        try:
            resp = sfn_client.describe_execution(executionArn=execution_arn)
            return {
                "statusCode": 200,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"status": resp['status'], "output": resp.get('output', '')})
            }
        except Exception as e:
            return {"statusCode": 400, "body": json.dumps({"error": str(e)})}
    EOF

  wake_proxy = <<-EOF
import json
import logging
import os
import time
import boto3
from botocore.exceptions import ClientError
import requests

# Setup logging
LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')
logging.basicConfig(level=LOG_LEVEL)
logger = logging.getLogger(__name__)

ecs_client = boto3.client('ecs')
sd_client = boto3.client('servicediscovery')

def scale_up_ecs_service(cluster, service, request_id, execution_arn):
    try:
        desc = ecs_client.describe_services(cluster=cluster, services=[service])
        desired_count = desc['services'][0]['desiredCount']
        if desired_count == 0:
            logger.info(f"No tasks running, scaling up to 1 - request_id: {request_id}")
            ecs_client.update_service(cluster=cluster, service=service, desiredCount=1)
        else:
            logger.debug(f"Tasks already running: {desired_count} - request_id: {request_id}")
        return {
            "status": "Accepted",
            "executionArn": execution_arn,
            "pollUrl": f"/status/$${execution_arn.split(':')[-1]}"
        }
    except ClientError as e:
        logger.error(f"Failed to scale up: {e} - request_id: {request_id}")
        raise

def get_healthy_instance(service_id, request_id, max_attempts=12, delay=10):
    try:
        for attempt in range(1, max_attempts + 1):
            list_resp = sd_client.list_instances(ServiceId=service_id)
            instances = list_resp.get('Instances', [])
            logger.debug(f"Listed {len(instances)} instances - attempt: {attempt}, request_id: {request_id}")

            if not instances:
                time.sleep(delay)
                continue

            health_resp = sd_client.get_instances_health_status(
                ServiceId=service_id,
                Instances=[inst['Id'] for inst in instances]
            )
            health_map = health_resp.get('Status', {})
            healthy = [inst for inst in instances if health_map.get(inst['Id']) == 'HEALTHY']

            if healthy:
                inst = healthy[0]
                ip = inst['Attributes']['AWS_INSTANCE_IPV4']
                port = int(inst['Attributes'].get('AWS_INSTANCE_PORT', os.environ['TARGET_PORT']))
                logger.info(f"Healthy instance found: {ip.rsplit('.', 1)[0]}.xxx:{port} - request_id: {request_id}")
                return {'status': 'READY', 'ip': ip, 'port': port}
            
            logger.debug(f"No healthy instances yet - attempt: {attempt}, request_id: {request_id}")
            time.sleep(delay)
        
        return {'status': 'PENDING'}
    except ClientError as e:
        logger.error(f"Failed to get healthy instance: {e} - request_id: {request_id}")
        raise

def proxy_request(event, request_id):
    try:
        req_ctx = event['requestContext']
        path = event['rawPath']
        query = event['rawQueryString']
        body = event.get('body')
        headers = event.get('headers', {})
        is_base64 = event.get('isBase64Encoded', False)
        target = event['target']

        full_path = f"{path}?{query}" if query else path
        method = req_ctx['http']['method']

        clean_headers = {k: v for k, v in headers.items() if k.lower() not in ['host', 'x-forwarded-for', 'x-forwarded-port', 'x-forwarded-proto', 'x-amzn-trace-id', 'x-amz-cf-id']}
        clean_headers['Host'] = target['ip']

        req_body = None
        if body:
            req_body = base64.b64decode(body) if is_base64 else body.encode('utf-8')
            clean_headers['Content-Length'] = str(len(req_body))

        logger.debug(f"Proxying {method} to {target['ip']}:{target['port']}{full_path} - request_id: {request_id}")

        resp = requests.request(
            method=method,
            url=f"http://{target['ip']}:{target['port']}{full_path}",
            headers=clean_headers,
            data=req_body,
            timeout=110
        )
        return {
            'statusCode': resp.status_code,
            'headers': dict(resp.headers),
            'body': resp.text
        }
    except Exception as e:
        logger.error(f"Proxy failed: {e} - request_id: {request_id}")
        raise

def handler(event, context):
    request_id = context.aws_request_id
    action = event.get('action')
    execution_arn = context.invoked_function_arn  # Use Lambda's ARN or pass executionArn from Step Function
    logger.info(f"Invoked with action: {action} - request_id: {request_id}")

    if action == 'scaleUp':
        return scale_up_ecs_service(os.environ['ECS_CLUSTER'], os.environ['ECS_SERVICE'], request_id, execution_arn)
    
    elif action == 'checkHealth':
        return {'body': get_healthy_instance(os.environ['CLOUD_MAP_SERVICE_ID'], request_id)}
    
    elif action == 'proxy':
        return proxy_request(event, request_id)
    
    else:
        raise ValueError(f"Unknown action: {action}")
EOF
}

resource "null_resource" "wake_proxy_dependencies" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<EOC
mkdir -p lambda/wake-proxy
cat << EOF > lambda/wake-proxy/index.py
$#{local.wake_proxy}
EOF
echo "requests" > lambda/wake-proxy/requirements.txt
pip install -r lambda/wake-proxy/requirements.txt -t lambda/wake-proxy
cd lambda/wake-proxy
zip -r ../../wake-proxy.zip .
EOC
  }
}

data "local_file" "wake_proxy_zip" {
  filename   = "${path.module}/wake-proxy.zip"
  depends_on = [null_resource.wake_proxy_dependencies]
}

module "lambdas" {
  source = "git@github.com:green-alchemist/terraform-modules.git//modules/lambda"
  count  = var.enable_lambda_proxy ? 1 : 0

  lambda_name = var.service_name
  lambda_configs = [
    {
      name        = "wake-proxy"
      code        = local.wake_proxy
      timeout     = 120
      memory_size = 256
      permissions = [
        { Effect = "Allow", Action = "ecs:UpdateService", Resource = "*" },
        { Effect = "Allow", Action = "ecs:DescribeServices", Resource = "*" },
        { Effect = "Allow", Action = "servicediscovery:ListInstances", Resource = "*" },
        { Effect = "Allow", Action = "servicediscovery:GetInstancesHealthStatus", Resource = "*" }
      ]
      environment = {
        ECS_CLUSTER               = var.cluster_name
        ECS_SERVICE               = var.service_name
        TARGET_SERVICE_NAME       = var.service_name
        SERVICE_CONNECT_NAMESPACE = var.service_connect_namespace
        TARGET_PORT               = var.target_port
        CLOUD_MAP_SERVICE_ID      = var.cloud_map_service_id
        LOG_LEVEL                 = "DEBUG"
      }

      vpc_config = {
        subnet_ids         = var.subnet_ids
        security_group_ids = var.vpc_link_security_group_ids
      }
    },
    {
      name        = "status-poller"
      code        = local.status_poller
      timeout     = 10
      memory_size = 128
      permissions = [{ Effect = "Allow", Action = "states:DescribeExecution", Resource = "*" }]
      environment = {} # No env vars needed
      vpc_config = {
        subnet_ids         = []
        security_group_ids = []
      }
    },
    {
      name        = "strapi-loader"
      code        = local.strapi_loader
      timeout     = 10
      memory_size = 128
      permissions = [
        { Effect = "Allow", Action = "logs:CreateLogStream", Resource = "arn:aws:logs:*:*:*" },
        { Effect = "Allow", Action = "logs:PutLogEvents", Resource = "arn:aws:logs:*:*:*" }
      ]
      environment = {
        API_GATEWAY_URL = aws_apigatewayv2_api.this.api_endpoint
      }
      vpc_config = {
        subnet_ids         = []
        security_group_ids = []
      }
    }
  ]
}

# Ensure API Gateway route for strapi-loader
resource "aws_lambda_permission" "loader_apigw" {
  statement_id  = "AllowExecutionFromAPIGatewayLoader"
  action        = "lambda:InvokeFunction"
  function_name = module.lambdas[0].lambda_function_names["strapi-loader"]
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "loader" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.lambdas[0].lambda_invoke_arns["strapi-loader"]
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "loader_admin" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /admin/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.loader.id}"
}





module "step_function" {
  count  = var.enable_lambda_proxy ? 1 : 0
  source = "git@github.com:green-alchemist/terraform-modules.git//modules/step-function"

  state_machine_name  = "${var.name}-orchestrator"
  lambda_function_arn = module.lambdas[0].lambda_arns["wake-proxy"]
  tags                = var.tags
  enable_logging      = true
}

resource "aws_iam_role" "api_gateway_sfn_role" {
  count = var.enable_lambda_proxy ? 1 : 0
  name  = "${var.name}-apigw-sfn-invoke-role"
  tags  = var.tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "apigateway.amazonaws.com" }
    }]
  })
}


resource "aws_iam_role_policy" "api_gateway_sfn_policy" {
  count = var.enable_lambda_proxy ? 1 : 0
  name  = "${var.name}-apigw-sfn-invoke-policy"
  role  = aws_iam_role.api_gateway_sfn_role[0].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Action = "states:StartSyncExecution", Effect = "Allow", Resource = module.step_function[0].state_machine_arn },
      { Action = "states:StartExecution", Effect = "Allow", Resource = module.step_function[0].state_machine_arn },
      { Action = "states:DescribeExecution", Effect = "Allow", Resource = "*" }
    ]
  })
}

# Creates the private link between API Gateway and your VPC (only for HTTP_PROXY mode)
resource "aws_apigatewayv2_vpc_link" "this" {
  count = var.enable_lambda_proxy ? 0 : 1 # Disabled for Lambda proxy

  name               = "${var.name}-vpc-link"
  security_group_ids = var.vpc_link_security_group_ids
  subnet_ids         = var.subnet_ids
}

# Creates the API Gateway itself
resource "aws_apigatewayv2_api" "this" {
  name          = var.name
  protocol_type = "HTTP"
}







# Integration for async start
resource "aws_apigatewayv2_integration" "sfn_start" {
  api_id              = aws_apigatewayv2_api.this.id
  integration_type    = var.enable_lambda_proxy ? "AWS_PROXY" : var.integration_type
  integration_subtype = var.enable_lambda_proxy ? "StepFunctions-StartExecution" : null
  integration_method  = var.enable_lambda_proxy ? null : var.integration_method
  integration_uri     = var.enable_lambda_proxy ? null : var.integration_uri
  connection_type     = var.enable_lambda_proxy ? null : "VPC_LINK"
  connection_id       = var.enable_lambda_proxy ? null : (var.integration_type == "HTTP_PROXY" ? aws_apigatewayv2_vpc_link.this[0].id : null)

  payload_format_version = var.enable_lambda_proxy ? "1.0" : "2.0"
  timeout_milliseconds   = var.enable_lambda_proxy ? null : var.integration_timeout_millis
  credentials_arn        = var.enable_lambda_proxy ? aws_iam_role.api_gateway_sfn_role[0].arn : null

  request_parameters = var.enable_lambda_proxy ? {
    "StateMachineArn" = module.step_function[0].state_machine_arn
    "Input"           = "$request.body"
    "Name"            = "$context.requestId"
  } : {}
}

resource "aws_apigatewayv2_route" "proxy_any" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.sfn_start.id}"
}

# # Response for 202
# resource "aws_apigatewayv2_integration_response" "start_202" {
#   api_id                   = aws_apigatewayv2_api.this.id
#   integration_id           = aws_apigatewayv2_integration.sfn_start.id
#   integration_response_key = "/200/"
#   response_templates = {
#     "application/json" = "{\"status\": \"Accepted\", \"executionArn\": \"$input.json('$.executionArn')\", \"pollUrl\": \"/status/$util.escapeJavaScript($input.json('$.executionArn').split(':').pop())\"}"
#   }
# }

# Polling integration (DescribeExecution)
resource "aws_apigatewayv2_integration" "sfn_status" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.lambdas[0].lambda_invoke_arns["status-poller"]
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "status_get" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /status/{executionId}"
  target    = "integrations/${aws_apigatewayv2_integration.sfn_status.id}"
}

# resource "aws_apigatewayv2_integration_response" "status_200" {
#   api_id                   = aws_apigatewayv2_api.this.id
#   integration_id           = aws_apigatewayv2_integration.sfn_status.id
#   integration_response_key = "/200/"
#   response_templates = {
#     "application/json" = "{\"status\": \"$input.json('$.status')\", \"output\": \"$util.escapeJavaScript($input.json('$.output'))\"}"
#   }
# }










# Creates the integration that connects the API to the backend (conditional on mode)
# resource "aws_apigatewayv2_integration" "this" {
#   api_id              = aws_apigatewayv2_api.this.id
#   integration_type    = var.enable_lambda_proxy ? "AWS_PROXY" : var.integration_type
#   integration_subtype = var.enable_lambda_proxy ? "StepFunctions-StartSyncExecution" : null
#   integration_method  = var.enable_lambda_proxy ? null : var.integration_method
#   integration_uri     = var.enable_lambda_proxy ? null : var.integration_uri
#   connection_type     = var.enable_lambda_proxy ? null : "VPC_LINK"
#   connection_id       = var.enable_lambda_proxy ? null : (var.integration_type == "HTTP_PROXY" ? aws_apigatewayv2_vpc_link.this[0].id : null)

#   payload_format_version = var.enable_lambda_proxy ? "1.0" : "2.0"
#   timeout_milliseconds   = var.enable_lambda_proxy ? null : var.integration_timeout_millis
#   credentials_arn        = var.enable_lambda_proxy ? aws_iam_role.api_gateway_sfn_role[0].arn : null

#   request_parameters = var.enable_lambda_proxy ? {
#     "Input" = jsonencode({
#       "body"        = "$request.body",
#       "headers"     = "$request.headers",
#       "httpMethod"  = "$context.http.method",
#       "path"        = "$context.http.path",
#       "queryString" = "$context.http.querystring"
#     })
#     "StateMachineArn" = one(module.step_function[*].state_machine_arn)
#   } : {}
# }

# Creates routes based on route_keys (e.g., "ANY /{proxy+} for passthrough)
# resource "aws_apigatewayv2_route" "this" {
#   for_each = toset(var.route_keys)

#   api_id             = aws_apigatewayv2_api.this.id
#   route_key          = each.value
#   target             = "integrations/${aws_apigatewayv2_integration.this.id}"
#   authorization_type = "NONE"
# }

# Lambda permission (internal, conditional)
resource "aws_lambda_permission" "status_apigw" {
  count         = var.enable_lambda_proxy ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambdas[0].lambda_function_names["status-poller"]
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

# CloudWatch log group for access logging
resource "aws_cloudwatch_log_group" "this" {
  count = var.enable_access_logging ? 1 : 0

  name              = "/aws/api-gateway/${var.name}"
  retention_in_days = var.log_retention_in_days
}

# Deploys the API to a stage
resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = true

  dynamic "access_log_settings" {
    for_each = var.enable_access_logging ? [1] : []
    content {
      destination_arn = one(aws_cloudwatch_log_group.this[*].arn)
      format = jsonencode({
        requestId        = "$context.requestId"
        ip               = "$context.identity.sourceIp"
        requestTime      = "$context.requestTime"
        httpMethod       = "$context.httpMethod"
        routeKey         = "$context.routeKey"
        status           = "$context.status"
        protocol         = "$context.protocol"
        integrationError = "$context.integrationErrorMessage"
        responseLength   = "$context.responseLength"
      })
    }
  }

  dynamic "default_route_settings" {
    for_each = var.enable_access_logging ? [1] : []
    content {
      detailed_metrics_enabled = true
      logging_level            = "INFO"
      data_trace_enabled       = true
      throttling_burst_limit   = var.throttling_burst_limit
      throttling_rate_limit    = var.throttling_rate_limit
    }
  }

  depends_on = [aws_cloudwatch_log_group.this]
}

# Custom domain for the API
resource "aws_apigatewayv2_domain_name" "this" {
  domain_name = var.domain_name

  domain_name_configuration {
    certificate_arn = var.acm_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

# Maps the API to the custom domain
resource "aws_apigatewayv2_api_mapping" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  domain_name = aws_apigatewayv2_domain_name.this.id
  stage       = aws_apigatewayv2_stage.this.id
}