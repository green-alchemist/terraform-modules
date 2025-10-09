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
    for_each = length(each.value.vpc_config.subnet_ids) > 0 && length(each.value.vpc_config.security_group_ids) > 0 ? [1] : []
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
      [
        for perm in each.value.permissions : {
          Effect   = "Allow"
          Action   = perm.Action
          Resource = perm.Resource
        }
      ],
      [
        {
          Effect   = "Allow"
          Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
          Resource = "arn:aws:logs:*:*:*"
        }
      ],
      length(each.value.vpc_config.subnet_ids) > 0 && length(each.value.vpc_config.security_group_ids) > 0 ? [
        {
          Effect = "Allow"
          Action = [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface"
          ]
          Resource = "*"
        }
      ] : []
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
