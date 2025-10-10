resource "null_resource" "python_package_layer" {
  for_each = { for cfg in var.lambda_configs : cfg.name => cfg if length(coalesce(cfg.python_packages, [])) > 0 }

  # Trigger a re-provision when the list of packages changes.
  triggers = {
    packages_hash = sha256(join(",", each.value.python_packages))
  }

  provisioner "local-exec" {
    # NOTE: This command requires 'pip' and 'zip' to be installed on the machine running Terraform.
    # The paths are now consistent and use the module's root.
    command = <<-EOC
      set -e
      LAYER_DIR="${path.module}/.terraform/lambda_layers/${each.key}"
      REQUIREMENTS_FILE="$${LAYER_DIR}/requirements.txt"
      PACKAGE_DIR="$${LAYER_DIR}/python"
      OUTPUT_ZIP="${path.module}/.terraform/lambda_layers/${each.key}_layer.zip"

      mkdir -p $${PACKAGE_DIR}
      echo '${join("\n", each.value.python_packages)}' > $${REQUIREMENTS_FILE}
      pip install -r $${REQUIREMENTS_FILE} -t $${PACKAGE_DIR}
      cd $${LAYER_DIR}
      zip -r $${OUTPUT_ZIP} python
    EOC
  }
}

# This resource creates the Lambda Layer from the ZIP file created by the local-exec provisioner.
resource "aws_lambda_layer_version" "python_packages" {
  for_each = { for cfg in var.lambda_configs : cfg.name => cfg if length(coalesce(cfg.python_packages, [])) > 0 }

  # This ensures the layer is created only after the ZIP file exists.
  depends_on = [null_resource.python_package_layer]

  layer_name          = "${var.lambda_name}-${each.key}-layer"
  description         = "Python dependencies for ${each.key}"
  compatible_runtimes = ["python3.12"]
  filename            = "${path.module}/.terraform/lambda_layers/${each.key}_layer.zip"

  # The hash is now correctly calculated from the ZIP file itself, ensuring updates.
  source_code_hash    = filebase64sha256("${path.module}/.terraform/lambda_layers/${each.key}_layer.zip")
}

# --- LAMBDA FUNCTION CREATION ---

# Create a ZIP file for each Lambda's handler code.
data "archive_file" "lambda_package" {
  for_each = { for cfg in var.lambda_configs : cfg.name => cfg }

  type        = "zip"
  output_path = "${path.module}/.terraform/lambda_packages/${each.key}.zip"
  source {
    content  = each.value.code != null ? each.value.code : file(each.value.filename)
    filename = "index.py"
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
