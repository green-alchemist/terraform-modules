resource "null_resource" "python_package_layer" {
  for_each = { for cfg in var.lambda_configs : cfg.name => cfg if length(coalesce(cfg.python_packages, [])) > 0 }

  triggers = {
    packages = join(",", each.value.python_packages)
  }

  provisioner "local-exec" {
    command = <<EOC
mkdir -p $${path.module}/lambda/$${each.key}-layer/python
echo "$${join("\n", each.value.python_packages)}" > $${path.module}/lambda/$${each.key}-layer/requirements.txt
pip install -r $${path.module}/lambda/$${each.key}-layer/requirements.txt -t $${path.module}/lambda/$${each.key}-layer/python
cd $${path.module}/lambda/$${each.key}-layer
zip -r $${path.module}/lambda/$${each.key}-layer.zip python
EOC
  }
}

resource "local_file" "layer_hash" {
  for_each = { for cfg in var.lambda_configs : cfg.name => cfg if length(coalesce(cfg.python_packages, [])) > 0 }

  content  = "" # Will be overwritten by null_resource
  filename = "${path.module}/lambda/${each.key}-layer.hash"

  depends_on = [null_resource.python_package_layer]
}

# Lambda Layer for Python packages
resource "aws_lambda_layer_version" "python_packages" {
  for_each = { for cfg in var.lambda_configs : cfg.name => cfg if length(coalesce(cfg.python_packages, [])) > 0 }

  layer_name          = "${var.lambda_name}-${each.key}-layer"
  description         = "Python dependencies for ${each.key}"
  compatible_runtimes = ["python3.12"] # Adjust to your Python version
  filename            = "${path.module}/lambda/${each.key}-layer.zip"
  source_code_hash    = chomp(file("${path.module}/lambda/${each.key}-layer.hash"))

  depends_on = [
    null_resource.python_package_layer,
    local_file.layer_hash
  ]
}

# Create a ZIP file in memory for each Lambda
data "archive_file" "lambda_package" {
  for_each = { for cfg in var.lambda_configs : cfg.name => cfg }

  type        = "zip"
  output_path = "${path.module}/lambda/${each.key}.zip"

  source {
    content  = each.value.code != null ? each.value.code : file(each.value.filename)
    filename = "index.py"
  }

  dynamic "source" {
    for_each = length(coalesce(each.value.python_packages, [])) > 0 ? [1] : []
    content {
      content  = join("\n", each.value.python_packages)
      filename = "requirements.txt"
    }
  }
}

resource "aws_lambda_function" "this" {
  for_each = { for idx, cfg in var.lambda_configs : cfg.name => cfg }

  filename         = data.archive_file.lambda_package[each.key].output_path
  source_code_hash = data.archive_file.lambda_package[each.key].output_base64sha256
  role             = aws_iam_role.this[each.key].arn
  layers           = length(coalesce(each.value.python_packages, [])) > 0 ? [aws_lambda_layer_version.python_packages[each.key].arn] : []
  function_name    = "${var.lambda_name}-${each.value.name}"
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

# data "archive_file" "lambda_zip" {
#   for_each    = { for cfg in var.lambda_configs : cfg.name => cfg }
#   type        = "zip"
#   output_path = "${path.module}/.terraform/lambda-${each.key}.zip"
#   source {
#     content  = each.value.code
#     filename = "index.py"
#   }
# }
