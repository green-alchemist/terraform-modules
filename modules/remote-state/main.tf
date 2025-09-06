# locals {
#   define_lifecycle_rule = var.noncurrent_version_expiration != null || length(var.noncurrent_version_transitions) > 0
# }

#---------------------------------------------------------------------------------------------------
# KMS Key to Encrypt S3 Bucket
#---------------------------------------------------------------------------------------------------

# resource "aws_kms_key" "this" {
#   description             = var.kms_key_description
#   deletion_window_in_days = var.kms_key_deletion_window_in_days
#   enable_key_rotation     = var.kms_key_enable_key_rotation

#   tags = var.tags
# }

# resource "aws_kms_alias" "this" {
#   name          = "alias/${var.kms_key_alias}"
#   target_key_id = aws_kms_key.this.key_id
# }
#---------------------------------------------------------------------------------------------------
# Bucket Policies
#---------------------------------------------------------------------------------------------------


data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid    = "EnforceSSL"
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # dynamic "statement" {
  #   for_each = var.iam_access_principals
  #   content {
  #     sid    = "AllowTerraformActions"
  #     effect = "Allow"
  #     principals {
  #       type        = "AWS"
  #       identifiers = [statement.value]
  #     }
  #     actions = [
  #       "s3:ListBucket",
  #     ]
  #     resources = [
  #       aws_s3_bucket.state.arn
  #     ]
  #   }
  # }

  # dynamic "statement" {
  #   for_each = var.iam_access_principals
  #   content {
  #     sid    = "AllowTerraformStateActions"
  #     effect = "Allow"
  #     principals {
  #       type        = "AWS"
  #       identifiers = [statement.value]
  #     }
  #     actions = [
  #       "s3:GetObject",
  #       "s3:PutObject",
  #       "s3:DeleteObject"
  #     ]
  #     resources = [
  #       "${aws_s3_bucket.state.arn}/*"
  #     ]
  #   }
  # }
}

#---------------------------------------------------------------------------------------------------
# Bucket
#---------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "state" {
  bucket_prefix = var.override_s3_bucket_name ? null : var.state_bucket_prefix
  bucket        = var.override_s3_bucket_name ? var.s3_bucket_name : null
  force_destroy = var.s3_bucket_force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.s3_policy.json

  depends_on = [aws_s3_bucket_public_access_block.state]
}

# resource "aws_s3_bucket_acl" "state" {
#   bucket = aws_s3_bucket.state.id
#   acl    = "private"
# }
resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "state" {
  count = var.s3_logging_target_bucket != null ? 1 : 0

  bucket        = aws_s3_bucket.state.id
  target_bucket = var.s3_logging_target_bucket
  target_prefix = var.s3_logging_target_prefix
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
      # kms_master_key_id = aws_kms_key.this.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = rule.value.prefix
      }

      # Add a dynamic block for the new transition rule
      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transitions
        content {
          noncurrent_days = noncurrent_version_transition.value.noncurrent_days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      noncurrent_version_expiration {
        noncurrent_days = rule.value.noncurrent_version_expiration_days
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


#---------------------------------------------------------------------------------------------------
# DynamoDB Table for State Locking
#---------------------------------------------------------------------------------------------------

locals {
  # The table must have a primary key named LockID.
  # See below for more detail.
  # https://www.terraform.io/docs/backends/types/s3.html#dynamodb_table
  lock_key_id = "LockID"
}

resource "aws_dynamodb_table" "lock" {
  name         = var.dynamodb_table_name
  billing_mode = var.dynamodb_table_billing_mode
  hash_key     = local.lock_key_id

  attribute {
    name = local.lock_key_id
    type = "S"
  }

  server_side_encryption {
    enabled = var.dynamodb_enable_server_side_encryption
    # kms_key_arn = aws_kms_key.this.arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = var.tags
}