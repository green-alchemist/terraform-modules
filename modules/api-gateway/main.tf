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
  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "HTTP_PROXY"

  # This is the crucial change: point to the Fargate service's private DNS
  integration_uri = "http://${var.private_dns_name}:${var.container_port}"

  connection_type = "VPC_LINK"
  connection_id   = aws_apigatewayv2_vpc_link.this.id
}

# Creates a default route that sends all traffic to our integration
resource "aws_apigatewayv2_route" "this" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.this.id}"
}

# Deploys the API to a stage
resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = true
}

