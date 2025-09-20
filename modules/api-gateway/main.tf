# Creates the private link between API Gateway and your VPC
resource "aws_apigatewayv2_vpc_link" "this" {
  name               = "${var.name}-vpc-link"
  security_group_ids = var.security_group_ids
  subnet_ids         = var.subnet_ids
}

# Creates the API Gateway itself
resource "aws_apigatewayv2_api" "this" {
  name          = var.name
  protocol_type = "HTTP"
}

# Creates the integration that connects the API to the VPC Link
resource "aws_apigatewayv2_integration" "this" {
  api_id             = aws_apigatewayv2_api.this.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"

  # This is the crucial change: point to the Fargate service's private DNS
  integration_uri = var.target_uri

  connection_type = "VPC_LINK"
  connection_id   = aws_apigatewayv2_vpc_link.this.id
  depends_on = [
    var.fargate_service_arn
  ]
}

# Creates a default route that sends all traffic to our integration
resource "aws_apigatewayv2_route" "this" {
  for_each = toset(var.route_keys) # Create a route for each key in the list

  api_id    = aws_apigatewayv2_api.this.id
  route_key = each.value # Use the value from the list (e.g., "GET /admin/{proxy+}")
  target    = "integrations/${aws_apigatewayv2_integration.this.id}"
}

# Deploys the API to a stage
resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = true
}

resource "aws_apigatewayv2_domain_name" "this" {
  domain_name = var.domain_name

  domain_name_configuration {
    certificate_arn = var.acm_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

# ADD THIS RESOURCE TO MAP THE API TO THE CUSTOM DOMAIN
resource "aws_apigatewayv2_api_mapping" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  domain_name = aws_apigatewayv2_domain_name.this.id
  stage       = aws_apigatewayv2_stage.this.id
}

