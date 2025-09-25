data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ------------------------------------------------------------------------------
# Role 1: ECS Task Execution Role
#
# Responsibilities:
# - Pulled by the ECS Agent to start the task.
# - Pulls the container image from ECR.
# - Fetches secrets from SSM/Secrets Manager (if configured).
# - Sends logs to CloudWatch.
# ------------------------------------------------------------------------------
resource "aws_iam_role" "execution_role" {
  name = var.execution_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
      }
    ]
  })
}

# Standard AWS managed policy for basic execution capabilities.
resource "aws_iam_role_policy_attachment" "execution_role_managed_policy" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Optional policy for fetching secrets.
data "aws_iam_policy_document" "ecs_execution_ssm_policy" {
  count = var.attach_ssm_secrets_policy ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "secretsmanager:GetSecretValue",
      "kms:Decrypt"
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter${var.secrets_ssm_path}",
      "arn:aws:secretsmanager:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:secret:*" # Adjust if needed
    ]
  }
}

resource "aws_iam_policy" "ecs_execution_ssm_policy" {
  count  = var.attach_ssm_secrets_policy ? 1 : 0
  name   = "${var.execution_role_name}-ssm-policy"
  policy = data.aws_iam_policy_document.ecs_execution_ssm_policy[0].json
}

resource "aws_iam_role_policy_attachment" "execution_ssm_attachment" {
  count      = var.attach_ssm_secrets_policy ? 1 : 0
  role       = aws_iam_role.execution_role.name
  policy_arn = aws_iam_policy.ecs_execution_ssm_policy[0].arn
}

resource "aws_iam_policy" "execution_role_custom_policies" {
  for_each = var.execution_role_policy_jsons
  name     = "${var.execution_role_name}-${each.key}"
  policy   = each.value
}

# Attachment 3: The additional custom policies.
resource "aws_iam_role_policy_attachment" "execution_role_custom_attachments" {
  for_each   = aws_iam_policy.execution_role_custom_policies
  role       = aws_iam_role.execution_role.name
  policy_arn = each.value.arn
}


# ------------------------------------------------------------------------------
# Role 2: ECS Task Role
#
# Responsibilities:
# - Assumed by the application code running INSIDE the container.
# - Grants permissions for your application to talk to other AWS services
#   (e.g., S3, Service Discovery, ECS Exec).
# ------------------------------------------------------------------------------
resource "aws_iam_role" "task_role" {
  name = var.task_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_policy" "task_policy" {
  count = var.task_role_policy_json != null ? 1 : 0

  name   = "${var.task_role_name}-policy"
  policy = var.task_role_policy_json
}

resource "aws_iam_role_policy_attachment" "task_attachment" {
  count = var.task_role_policy_json != null ? 1 : 0

  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_policy[0].arn
}
