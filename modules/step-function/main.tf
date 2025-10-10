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

# IAM Policy allowing the Step Function to invoke your Lambda and write logs
resource "aws_iam_role_policy" "sfn_policy" {
  name = "${var.state_machine_name}-invoke-lambda-policy"
  role = aws_iam_role.sfn_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
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
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Log Group for the State Machine
resource "aws_cloudwatch_log_group" "sfn_log_group" {
  count = var.enable_logging ? 1 : 0
  name  = "/aws/vendedlogs/states/${var.state_machine_name}"
  tags  = var.tags
}

# The State Machine Definition
resource "aws_sfn_state_machine" "this" {
  name     = var.state_machine_name
  role_arn = aws_iam_role.sfn_role.arn
  tags     = var.tags

  logging_configuration {
    log_destination        = var.enable_logging ? "${one(aws_cloudwatch_log_group.sfn_log_group[*].arn)}:*" : null
    include_execution_data = var.include_execution_data
    level                  = var.log_level
  }

  type = "STANDARD" # For async executions >30s

  definition = jsonencode({
    Comment = "Orchestrates wake and proxy for ECS",
    StartAt = "CheckIfHealthy",
    States = {
      CheckIfHealthy = {
        Type       = "Task",
        Resource   = "arn:aws:states:::lambda:invoke",
        Parameters = { "Payload" = { "action" = "checkHealth" }, "FunctionName" = var.lambda_function_arn },
        ResultSelector = {
          "body.$" = "$.Payload.body"
        },
        ResultPath = "$.health_status",
        Next       = "IsAlreadyHealthy"
      },
      IsAlreadyHealthy = {
        Type    = "Choice",
        Choices = [{ Variable = "$.health_status.body.status", StringEquals = "READY", Next = "ProxyRequest" }],
        Default = "ScaleUpEcsTask"
      },
      ScaleUpEcsTask = {
        Type       = "Task",
        Resource   = "arn:aws:states:::lambda:invoke",
        Parameters = { "Payload" = { "action" = "scaleUp" }, "FunctionName" = var.lambda_function_arn },
        ResultPath = "$.scale_up_result",
        Next       = "PollHealth"
      },
      PollHealth = {
        Type       = "Task",
        Resource   = "arn:aws:states:::lambda:invoke",
        Parameters = { "Payload" = { "action" = "checkHealth" }, "FunctionName" = var.lambda_function_arn },
        ResultSelector = {
          "body.$" = "$.Payload.body"
        },
        ResultPath = "$.health_status",
        Retry      = [{ ErrorEquals = ["States.ALL"], IntervalSeconds = 10, MaxAttempts = 9, BackoffRate = 1.5 }],
        Next       = "IsTaskHealthyNow"
      },
      IsTaskHealthyNow = {
        Type    = "Choice",
        Choices = [{ Variable = "$.health_status.body.status", StringEquals = "READY", Next = "ProxyRequest" }],
        Default = "PollHealth"
      },
      ProxyRequest = {
        Type     = "Task",
        Resource = "arn:aws:states:::lambda:invoke",
        Parameters = {
          "FunctionName" = var.lambda_function_arn,
          "Payload" = {
            "action"            = "proxy",
            "requestContext.$"  = "$.input.requestContext",
            "rawPath.$"         = "$.input.rawPath",
            "rawQueryString.$"  = "$.input.rawQueryString",
            "body.$"            = "$.input.body",
            "headers.$"         = "$.input.headers",
            "isBase64Encoded.$" = "$.input.isBase64Encoded",
            "target.$"          = "$.health_status.body"
          }
        },
        ResultPath = "$.proxy_result",
        End        = true
      }
    }
  })

  depends_on = [aws_iam_role_policy.sfn_policy]
}