resource "aws_lambda_function" "this" {
  for_each = { for idx, cfg in var.lambda_configs : cfg.name => cfg }

  filename         = "${path.module}/.terraform/lambda-${each.key}.zip"
  source_code_hash = data.archive_file.lambda_zip[each.key].output_base64sha256
  function_name    = "${var.lambda_name}-${each.key}"
  role             = aws_iam_role.this[each.key].arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = each.value.timeout

  dynamic "environment" {
    for_each = length(each.value.environment) > 0 ? [1] : []
    content {
      variables = each.value.environment
    }
  }

  dynamic "vpc_config" {
    for_each = each.value.vpc_config.subnet_ids != null && each.value.vpc_config.security_group_ids != null ? [1] : []
    content {
      subnet_ids         = each.value.vpc_config.subnet_ids
      security_group_ids = each.value.vpc_config.security_group_ids
    }
  }
}

resource "aws_iam_role" "this" {
  for_each = { for cfg in var.lambda_configs : cfg.name => cfg }

  name = "${var.lambda_name}-${each.key}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "this" {
  for_each = { for cfg in var.lambda_configs : cfg.name => cfg }

  role = aws_iam_role.this[each.key].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      each.value.permissions,
      [
        {
          Effect   = "Allow"
          Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
          Resource = "arn:aws:logs:*:*:*"
        },
        {
          Effect = "Allow"
          Action = [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface"
          ]
          Resource = "*"
        }
      ]
    )
  })
}

data "archive_file" "lambda_zip" {
  for_each    = { for cfg in var.lambda_configs : cfg.name => cfg }
  type        = "zip"
  output_path = "${path.module}/.terraform/lambda-${each.key}.zip"
  source {
    content  = each.value.code
    filename = "index.py"
  }
}

# resource "aws_lambda_function" "wake_proxy" {
#   filename         = data.archive_file.lambda_zip.output_path
#   source_code_hash = data.archive_file.lambda_zip.output_base64sha256
#   function_name    = "${var.service_name}-wake-proxy"
#   role             = aws_iam_role.lambda.arn
#   handler          = "index.handler"
#   runtime          = "python3.12"
#   timeout          = 120 # Longer for proxy/polling
#   memory_size      = 256 # Adjustable

#   environment {
#     variables = {
#       ECS_CLUSTER               = var.cluster_name
#       ECS_SERVICE               = var.service_name
#       TARGET_SERVICE_NAME       = var.service_name
#       SERVICE_CONNECT_NAMESPACE = var.service_connect_namespace
#       TARGET_PORT               = var.target_port
#       CLOUD_MAP_SERVICE_ID      = var.cloud_map_service_id
#       LOG_LEVEL                 = "DEBUG"
#     }
#   }

#   vpc_config {
#     subnet_ids         = var.subnet_ids
#     security_group_ids = var.security_group_ids
#   }
# }

# resource "aws_iam_role_policy" "lambda_policy" {
#   role = aws_iam_role.lambda.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "ecs:UpdateService",
#           "ecs:DescribeServices",
#           "servicediscovery:ListInstances",
#           "servicediscovery:GetInstancesHealthStatus"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ]
#         Resource = "arn:aws:logs:*:*:*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "ec2:CreateNetworkInterface",
#           "ec2:DescribeNetworkInterfaces",
#           "ec2:DeleteNetworkInterface"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# data "archive_file" "lambda_zip" {
#   type        = "zip"
#   output_path = "${path.module}/.terraform/lambda-${var.service_name}.zip"

#   source {
#     content  = var.lambda_code 
#     filename = "index.py"
#   }
# }