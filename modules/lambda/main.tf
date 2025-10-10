resource "null_resource" "python_package_layer" {
  for_each = { for cfg in var.lambda_configs : cfg.name => cfg if length(coalesce(cfg.python_packages, [])) > 0 }

  # Trigger a re-provision only when the list of packages changes.
  triggers = {
    packages_hash = sha256(join(",", each.value.python_packages))
  }

  provisioner "local-exec" {
    # NOTE: This requires 'pip', 'zip', and 'shasum' (or 'sha256sum') on the machine running Terraform.
    command = <<-EOC
      set -e
      LAYER_DIR="${path.module}/.terraform/lambda_layers/${each.key}"
      REQUIREMENTS_FILE="$${LAYER_DIR}/requirements.txt"
      PACKAGE_DIR="$${LAYER_DIR}/python"
      OUTPUT_ZIP="$${LAYER_DIR}_layer.zip"
      HASH_FILE="$${LAYER_DIR}_layer.hash"

      # Clean up previous build artifacts to ensure a fresh build
      rm -rf $${LAYER_DIR} $${OUTPUT_ZIP} $${HASH_FILE}

      # Create directories
      mkdir -p $${PACKAGE_DIR}

      # Install packages
      echo '${join("\n", each.value.python_packages)}' > $${REQUIREMENTS_FILE}
      pip install -r $${REQUIREMENTS_FILE} -t $${PACKAGE_DIR}

      # Create the zip file
      cd $${LAYER_DIR}
      zip -r $${OUTPUT_ZIP} python

      # Calculate the hash of the zip and save it to the hash file
      shasum -a 256 $${OUTPUT_ZIP} | awk '{print $1}' | xxd -r -p | base64 > $${HASH_FILE}
    EOC
  }
}

# This resource creates the Lambda Layer from the ZIP file.
resource "aws_lambda_layer_version" "python_packages" {
  for_each = { for cfg in var.lambda_configs : cfg.name => cfg if length(coalesce(cfg.python_packages, [])) > 0 }

  # This dependency ensures the local-exec script has finished before this resource is created.
  depends_on = [null_resource.python_package_layer]

  layer_name          = "${var.lambda_name}-${each.key}-layer"
  description         = "Python dependencies for ${each.key}"
  compatible_runtimes = ["python3.12"]
  filename            = "${path.module}/.terraform/lambda_layers/${each.key}_layer.zip"

  # THE FIX: Read the pre-calculated hash from the file instead of trying to calculate it.
  source_code_hash    = file("${path.module}/.terraform/lambda_layers/${each.key}_layer.hash")
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
