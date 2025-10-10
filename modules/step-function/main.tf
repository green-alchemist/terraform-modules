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

  definition = var.definition != "" ? jsonencode(var.definition) : jsonencode({
    Comment = "Orchestrates the scale-up, health check, and proxying for a serverless ECS task",
    StartAt = "CheckIfHealthy", # We can start here since API Gateway input is not being used
    States = {
      CheckIfHealthy = {
        Type       = "Task",
        Resource   = "arn:aws:states:::lambda:invoke",
        Parameters = { "FunctionName" = var.lambda_function_arn, "Payload" = { "action" = "checkHealth" } },
        ResultPath = "$.health_status",
        Next       = "IsAlreadyHealthy"
      },
      IsAlreadyHealthy = {
        Type = "Choice",
        Choices = [
          {
            # THIS IS THE FIX: Correctly path into the nested Payload object
            "Variable"     = "$.health_status.Payload.body.status",
            "StringEquals" = "READY",
            "Next"         = "ProxyRequest"
          }
        ],
        Default = "ScaleUpEcsTask"
      },
      ScaleUpEcsTask = {
        Type       = "Task",
        Resource   = "arn:aws:states:::lambda:invoke",
        Parameters = { "FunctionName" = var.lambda_function_arn, "Payload" = { "action" = "scaleUp" } },
        ResultPath = "$.scale_up_result",
        Next       = "Wait"
      },
      Wait = { "Type" = "Wait", "Seconds" = 30, "Next" = "PollHealth" },
      PollHealth = {
        Type       = "Task",
        Resource   = "arn:aws:states:::lambda:invoke",
        Parameters = { "FunctionName" = var.lambda_function_arn, "Payload" = { "action" = "checkHealth" } },
        ResultPath = "$.health_status",
        Next       = "IsTaskHealthyNow"
      },
      IsTaskHealthyNow = {
        Type = "Choice",
        Choices = [
          {
            # THIS IS THE FIX: Correctly path into the nested Payload object
            "Variable"     = "$.health_status.Payload.body.status",
            "StringEquals" = "READY",
            "Next"         = "ProxyRequest"
          }
        ],
        Default = "Wait"
      },
      ProxyRequest = {
        Type     = "Task",
        Resource = "arn:aws:states:::lambda:invoke",
        # We need to define the 'preserved' object here since we removed the first state
        "Parameters" = {
          "FunctionName" = var.lambda_function_arn,
          "Payload" = {
            "action" : "proxy",
            "original_request" : { "path" : "from-step-function" }, # Placeholder
            "target.$" : "$.health_status.Payload.body"
          }
        },
        End = true
      }
    }
  })

  depends_on = [aws_iam_role_policy.sfn_policy]
}