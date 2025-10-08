data "aws_partition" "current" {}
data "aws_region" "current" {}

# Conditional nested Lambda proxy module
module "lambda_scale_up" {
  count = var.enable_lambda_proxy ? 1 : 0

  source                    = "git@github.com:green-alchemist/terraform-modules.git//modules/lambda-scale-up"
  cluster_name              = var.cluster_name
  service_name              = var.service_name
  service_connect_namespace = var.service_connect_namespace
  cloud_map_service_id      = var.cloud_map_service_id
  target_port               = var.target_port
  subnet_ids                = var.subnet_ids
  security_group_ids        = var.vpc_link_security_group_ids
}

module "step_function" {
  count  = var.enable_lambda_proxy ? 1 : 0
  source = "git@github.com:green-alchemist/terraform-modules.git//modules/step-function"

  state_machine_name  = "${var.name}-orchestrator"
  lambda_function_arn = module.lambda_scale_up[0].lambda_arn
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
    Statement = [{
      Action   = "states:StartSyncExecution",
      Effect   = "Allow",
      Resource = module.step_function[0].state_machine_arn
    }]
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

# Creates the integration that connects the API to the backend (conditional on mode)
resource "aws_apigatewayv2_integration" "this" {
  api_id              = aws_apigatewayv2_api.this.id
  integration_type    = var.enable_lambda_proxy ? "AWS_PROXY" : var.integration_type
  integration_subtype = var.enable_lambda_proxy ? "StepFunctions-StartSyncExecution" : null
  integration_method  = var.enable_lambda_proxy ? null : var.integration_method
  integration_uri     = var.enable_lambda_proxy ? null : var.integration_uri
  connection_type     = var.enable_lambda_proxy ? null : "VPC_LINK"
  connection_id       = var.enable_lambda_proxy ? null : (var.integration_type == "HTTP_PROXY" ? aws_apigatewayv2_vpc_link.this[0].id : null)

  payload_format_version = var.enable_lambda_proxy ? "1.0" : "2.0"
  timeout_milliseconds   = var.enable_lambda_proxy ? 29000 : var.integration_timeout_millis
  credentials_arn        = var.enable_lambda_proxy ? aws_iam_role.api_gateway_sfn_role[0].arn : null

  request_parameters = var.enable_lambda_proxy ? {
    "Input"           = "$request.body"
    "StateMachineArn" = one(module.step_function[*].state_machine_arn)
  } : {}
}

# Creates routes based on route_keys (e.g., "ANY /{proxy+} for passthrough)
resource "aws_apigatewayv2_route" "this" {
  for_each = toset(var.route_keys)

  api_id             = aws_apigatewayv2_api.this.id
  route_key          = each.value
  target             = "integrations/${aws_apigatewayv2_integration.this.id}"
  authorization_type = "NONE"
}

# Lambda permission (internal, conditional)
resource "aws_lambda_permission" "apigw" {
  count         = var.enable_lambda_proxy ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_scale_up[0].lambda_function_name
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