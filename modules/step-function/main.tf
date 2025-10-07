# IAM Role for the Step Function
resource "aws_iam_role" "step_function_role" {
  name = "${var.state_machine_name}-role"

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

# IAM Policy to allow the Step Function to invoke your Lambda
resource "aws_iam_role_policy" "step_function_policy" {
  name = "${var.state_machine_name}-policy"
  role = aws_iam_role.step_function_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = "lambda:InvokeFunction",
      Effect   = "Allow",
      Resource = var.lambda_function_arn
    }]
  })
}

# The State Machine Definition
resource "aws_sfn_state_machine" "this" {
  name     = var.state_machine_name
  role_arn = aws_iam_role.step_function_role.arn
  type     = "EXPRESS" # Express Sync workflow is required for API Gateway integration

  # This is the workflow logic
  definition = jsonencode({
    Comment = "Orchestrates the scale-up, health check, and proxying for a serverless ECS task",
    StartAt = "ScaleUpEcsTask",
    States = {
      ScaleUpEcsTask = {
        Type     = "Task",
        Resource = var.lambda_function_arn,
        Parameters = {
          "action" = "scaleUp"
        },
        Next = "Wait"
      },
      Wait = {
        Type    = "Wait",
        Seconds = 30, # Wait for 30 seconds before the first health check
        Next    = "CheckHealth"
      },
      CheckHealth = {
        Type     = "Task",
        Resource = var.lambda_function_arn,
        Parameters = {
          "action" = "checkHealth"
        },
        Next       = "IsTaskHealthy",
        ResultPath = "$.health_status"
      },
      IsTaskHealthy = {
        Type = "Choice",
        Choices = [
          {
            Variable     = "$.health_status.body.status",
            StringEquals = "READY",
            Next         = "ProxyRequest"
          }
        ],
        Default = "Wait" # If not ready, loop back to the Wait state
      },
      ProxyRequest = {
        Type     = "Task",
        Resource = var.lambda_function_arn,
        Parameters = {
          "action"           = "proxy",
          "original_request" = "$", # Pass the entire original API request to the proxy step
          "target"           = "$.health_status.body"
        },
        End = true
      }
    }
  })
}