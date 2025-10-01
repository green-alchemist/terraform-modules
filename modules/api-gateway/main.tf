module "lambda_scale_up" {
  count                     = var.enable_lambda_proxy ? 1 : 0
  source                    = "git@github.com:green-alchemist/terraform-modules.git//modules/lambda-scale-up"
  cluster_name              = var.cluster_name # Pass from parent vars
  service_name              = var.service_name
  service_connect_namespace = var.service_connect_namespace
  cloud_map_service_id      = var.cloud_map_service_id
  target_port               = var.target_port
}

resource "aws_lambda_permission" "apigw" {
  count         = var.enable_lambda_proxy ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_scale_up[0].lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

# Creates the private link between API Gateway and your VPC (only for HTTP_PROXY)
resource "aws_apigatewayv2_vpc_link" "this" {
  count = var.integration_type == "HTTP_PROXY" ? 1 : 0

  name               = "${var.name}-vpc-link"
  security_group_ids = var.vpc_link_security_group_ids
  subnet_ids         = var.subnet_ids
}

# Creates the API Gateway itself
resource "aws_apigatewayv2_api" "this" {
  name          = var.name
  protocol_type = "HTTP"
}

# Creates the integration that connects the API to the backend (conditional based on type)
resource "aws_apigatewayv2_integration" "this" {
  api_id             = aws_apigatewayv2_api.this.id
  integration_type   = var.integration_type
  integration_method = var.integration_type == "AWS_PROXY" ? "POST" : "ANY"
  integration_uri    = var.integration_uri

  # VPC Link settings only for HTTP_PROXY
  connection_type        = var.integration_type == "HTTP_PROXY" ? "VPC_LINK" : null
  connection_id          = var.integration_type == "HTTP_PROXY" ? one(aws_apigatewayv2_vpc_link.this[*].id) : null
  payload_format_version = var.integration_type == "AWS_PROXY" ? "2.0" : null
  timeout_milliseconds   = var.integration_timeout_millis
}

# Creates the Lambda fallback integration for scale-up (only for HTTP_PROXY)
resource "aws_apigatewayv2_integration" "lambda_fallback" {
  count              = var.integration_type == "HTTP_PROXY" && var.enable_lambda_fallback ? 1 : 0
  api_id             = aws_apigatewayv2_api.this.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = module.lambda_scale_up[0].lambda_arn
}

# Creates routes based on route_keys (e.g., "ANY /{proxy+}" for passthrough)
resource "aws_apigatewayv2_route" "this" {
  for_each = toset(var.route_keys)

  api_id             = aws_apigatewayv2_api.this.id
  route_key          = each.key
  target             = "integrations/${aws_apigatewayv2_integration.this.id}"
  authorization_type = "NONE"
}

# Creates /scale-up route for manual Lambda trigger (only for HTTP_PROXY + enable_lambda_fallback)
resource "aws_apigatewayv2_route" "scale_up" {
  count              = var.integration_type == "HTTP_PROXY" && var.enable_lambda_fallback ? 1 : 0
  api_id             = aws_apigatewayv2_api.this.id
  route_key          = "POST /scale-up"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_fallback[0].id}"
  authorization_type = "NONE"
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