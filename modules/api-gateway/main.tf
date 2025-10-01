# Creates the private link between API Gateway and your VPC (only if needed)
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

# Creates the integration that connects the API to the backend
resource "aws_apigatewayv2_integration" "this" {
  api_id             = aws_apigatewayv2_api.this.id
  integration_type   = var.integration_type
  integration_method = var.integration_type == "AWS_PROXY" ? "POST" : "ANY"
  integration_uri    = var.integration_uri

  # Conditional configuration based on integration type
  connection_type        = var.integration_type == "HTTP_PROXY" ? "VPC_LINK" : null
  connection_id          = var.integration_type == "HTTP_PROXY" ? one(aws_apigatewayv2_vpc_link.this[*].id) : null
  payload_format_version = var.integration_type == "AWS_PROXY" ? "2.0" : null
  timeout_milliseconds   = 30000
}

resource "aws_apigatewayv2_integration" "lambda_fallback" {
  count              = var.lambda_fallback_arn != null ? 1 : 0
  api_id             = aws_apigatewayv2_api.this.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = var.lambda_fallback_arn
}
# Creates a default route that sends all traffic to our integration
resource "aws_apigatewayv2_route" "this" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.this.id}"
}

resource "aws_apigatewayv2_route_response" "default" {
  api_id             = aws_apigatewayv2_api.this.id
  route_id           = aws_apigatewayv2_route.this.id
  route_response_key = "$default"
}

resource "aws_apigatewayv2_integration_response" "ecs_503" {
  api_id                   = aws_apigatewayv2_api.this.id
  integration_id           = aws_apigatewayv2_integration.this.id
  integration_response_key = "/503/"
  response_templates = {
    "503" = "{\"error\": \"No target endpoints, triggering Lambda\"}"
  }
}

resource "aws_apigatewayv2_route" "fallback" {
  count              = aws_apigatewayv2_integration.lambda_fallback != "" ? 1 : 0
  api_id             = aws_apigatewayv2_api.this.id
  route_key          = "ANY /{proxy+}"
  target             = var.lambda_fallback_arn != "" ? "integrations/${aws_apigatewayv2_integration.lambda_fallback[0].id}" : null
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route_response" "fallback_response" {
  count              = aws_apigatewayv2_integration.lambda_fallback != "" ? 1 : 0
  api_id             = aws_apigatewayv2_api.this.id
  route_id           = var.lambda_fallback_arn != "" ? aws_apigatewayv2_route.fallback[0].id : null
  route_response_key = "$default"
}

resource "aws_lambda_permission" "apigw" {
  count         = var.lambda_fallback_arn != null ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_fallback_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

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
      logging_level            = "INFO" # Or "ERROR" to reduce noise
      data_trace_enabled       = true   # Full request/response logging
      throttling_burst_limit   = 10000  # Increase from default 5000
      throttling_rate_limit    = 5000   # Increase from default 2500
    }
  }

  depends_on = [aws_cloudwatch_log_group.this]
}

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
