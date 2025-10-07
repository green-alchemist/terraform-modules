# CloudWatch Log Group for the State Machine
resource "aws_cloudwatch_log_group" "sfn_log_group" {
  count = var.enable_logging ? 1 : 0
  name  = "/aws/vendedlogs/states/${var.state_machine_name}"
  tags  = var.tags
}

# IAM Role for the Step Function to assume
resource "aws_iam_role" "sfn_role" {
  name = "${var.state_machine_name}-role"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })
}

# IAM Policy allowing the Step Function to invoke your Lambda
resource "aws_iam_role_policy" "sfn_policy" {
  name = "${var.state_machine_name}-invoke-lambda-policy"
  role = aws_iam_role.sfn_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = "lambda:InvokeFunction",
      Effect   = "Allow",
      Resource = var.lambda_function_arn
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ],
        Resource = "*" # As required by AWS for logging setup
    }]
  })
}

# The State Machine Definition
resource "aws_sfn_state_machine" "this" {
  name     = var.state_machine_name
  role_arn = aws_iam_role.sfn_role.arn
  type     = "EXPRESS" # Express Sync workflow is required for the API Gateway integration
  tags     = var.tags

  definition = jsonencode({
    Comment = "Orchestrates the scale-up, health check, and proxying for a serverless ECS task",
    StartAt = "CheckIfHealthy", # Start by checking if the service is already running
    States = {
      CheckIfHealthy = {
        Type       = "Task",
        Resource   = var.lambda_function_arn,
        Parameters = { "action" = "checkHealth" },
        ResultPath = "$.health_status",
        Next       = "IsAlreadyHealthy"
      },
      IsAlreadyHealthy = {
        Type = "Choice",
        Choices = [
          {
            Variable     = "$.health_status.body.status",
            StringEquals = "READY",
            Next         = "ProxyRequest" # If already healthy, go straight to proxying
          }
        ],
        Default = "ScaleUpEcsTask" # Otherwise, start the scale-up process
      },
      ScaleUpEcsTask = {
        Type       = "Task",
        Resource   = var.lambda_function_arn,
        Parameters = { "action" = "scaleUp" },
        Next       = "Wait"
      },
      Wait = {
        Type    = "Wait",
        Seconds = 30, # Wait 30 seconds before polling
        Next    = "PollHealth"
      },
      PollHealth = {
        Type       = "Task",
        Resource   = var.lambda_function_arn,
        Parameters = { "action" = "checkHealth" },
        ResultPath = "$.health_status",
        Next       = "IsTaskHealthyNow"
      },
      IsTaskHealthyNow = {
        Type = "Choice",
        Choices = [
          {
            Variable     = "$.health_status.body.status",
            StringEquals = "READY",
            Next         = "ProxyRequest"
          }
        ],
        Default = "Wait" # If still not ready, loop back and wait again
      },
      ProxyRequest = {
        Type     = "Task",
        Resource = var.lambda_function_arn,
        Parameters = {
          "action"           = "proxy",
          "original_request" = "$", # Pass the original API request payload
          "target"           = "$.health_status.body"
        },
        End = true
      }
    }
  })
}