data "aws_caller_identity" "current" {}

# --- S3 BUCKET FOR LAMBDA ARTIFACTS ---
# It's best practice to have a dedicated, versioned bucket for code artifacts.
resource "aws_s3_bucket" "lambda_artifacts" {
  bucket        = "${var.lambda_name}-artifacts-${data.aws_caller_identity.current.account_id}" # A unique name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "lambda_artifacts" {
  bucket = aws_s3_bucket.lambda_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}


# --- LAMBDA LAYER CREATION ---

# This data source runs an external script to build the layer, upload it to S3,
# and output the S3 object's key and version ID.
data "external" "python_lambda_layer_s3" {
  for_each = { for cfg in var.lambda_configs : cfg.name => cfg if length(coalesce(cfg.python_packages, [])) > 0 }

  program = ["bash", "-c", <<-EOT
    set -e
    # Read inputs from stdin
    eval "$(jq -r '@sh "S3_BUCKET=\(.bucket) PACKAGES=\(.packages)"')"

    # Create a self-cleaning temporary directory
    TMP_DIR=$(mktemp -d)
    trap 'rm -rf -- "$TMP_DIR"' EXIT

    PACKAGE_DIR="$TMP_DIR/python"
    REQUIREMENTS_FILE="$TMP_DIR/requirements.txt"
    mkdir -p "$PACKAGE_DIR"

    # Install packages
    echo "$PACKAGES" | jq -r '.[]' > "$REQUIREMENTS_FILE"
    pip install -r "$REQUIREMENTS_FILE" -t "$PACKAGE_DIR" >&2

    # Create the zip file
    ZIP_FILE="$TMP_DIR/layer.zip"
    cd "$TMP_DIR"
    zip -r "$ZIP_FILE" python >&2

    # Upload to S3 and get the VersionId from the output
    S3_KEY="layers/${each.key}/$(date +%s).zip"
    UPLOAD_RESULT=$(aws s3api put-object --bucket "$S3_BUCKET" --key "$S3_KEY" --body "$ZIP_FILE" --output json)
    VERSION_ID=$(echo "$UPLOAD_RESULT" | jq -r '.VersionId')

    # CRITICAL: Output the S3 key and version as a JSON object to stdout
    jq -n --arg key "$S3_KEY" --arg version_id "$VERSION_ID" \
      '{"s3_key": $key, "s3_object_version_id": $version_id}'
  EOT
  ]

  query = {
    bucket   = aws_s3_bucket.lambda_artifacts.id,
    packages = jsonencode(each.value.python_packages)
  }
}

# This resource now creates the layer directly from the S3 object.
resource "aws_lambda_layer_version" "python_packages" {
  for_each = { for cfg in var.lambda_configs : cfg.name => cfg if length(coalesce(cfg.python_packages, [])) > 0 }

  layer_name          = "${var.lambda_name}-${each.key}-layer"
  description         = "Python dependencies for ${each.key}"
  compatible_runtimes = ["python3.12"]

  # THE FIX: Point to the object uploaded by the external script.
  s3_bucket         = aws_s3_bucket.lambda_artifacts.id
  s3_key            = data.external.python_lambda_layer_s3[each.key].result.s3_key
  s3_object_version = data.external.python_lambda_layer_s3[each.key].result.s3_object_version_id
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
          Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
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
