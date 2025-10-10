# This data source runs an external script to build the layer package in memory.
data "external" "python_lambda_layer" {
  for_each = { for cfg in var.lambda_configs : cfg.name => cfg if length(coalesce(cfg.python_packages, [])) > 0 }

  program = ["bash", "-c", <<-EOT
    set -e
    # Create a self-cleaning temporary directory
    TMP_DIR=$(mktemp -d)
    trap 'rm -rf -- "$TMP_DIR"' EXIT

    PACKAGE_DIR="$TMP_DIR/python"
    mkdir -p "$PACKAGE_DIR"

    # Read packages from stdin (passed via input attribute)
    PACKAGES=$(jq -r '.packages | join(" ")' -)

    # Install packages if any exist
    if [ -n "$PACKAGES" ]; then
      pip install $PACKAGES -t "$PACKAGE_DIR" >&2
    fi

    # Create zip file in the temp directory
    ZIP_FILE="$TMP_DIR/layer.zip"
    cd "$PACKAGE_DIR" && zip -r "$ZIP_FILE" . >&2

    # CRITICAL STEP: Base64 encode the zip file and output as JSON
    # This is captured by the 'result' attribute of the data source.
    BASE64_CONTENT=$(base64 -w 0 "$ZIP_FILE")
    jq -n --arg content "$BASE64_CONTENT" '{"content_base64": $content}'
  EOT
  ]

  query = {
    # Pass the list of packages to the script's standard input.
    packages = jsonencode(each.value.python_packages)
  }
}

# This resource now creates the layer directly from the base64-encoded content.
resource "aws_lambda_layer_version" "python_packages" {
  for_each = { for cfg in var.lambda_configs : cfg.name => cfg if length(coalesce(cfg.python_packages, [])) > 0 }

  layer_name          = "${var.lambda_name}-${each.key}-layer"
  description         = "Python dependencies for ${each.key}"
  compatible_runtimes = ["python3.12"]

  # THE FIX: No filename or hash. Content is provided directly.
  content = data.external.python_lambda_layer[each.key].result.content_base64
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
