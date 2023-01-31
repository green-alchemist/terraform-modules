locals {
  defaults = {
    scan_on_push = true
    # The tag mutability setting for the repository. Must be one of: MUTABLE or IMMUTABLE. Defaults to MUTABLE.
    image_tag_mutability = "MUTABLE"
    lifecycle_policy = {
      rules = [{
        rulePriority = 10
        description  = "keep last 20 images"
        action = {
          type = "expire"
        }
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 20
        }
        },
        {
          rulePriority = 1
          description  = "Expire untagged images older than 14 days"
          action = {
            type = "expire"
          }
          selection = {
            tagStatus   = "untagged"
            countType   = "sinceImagePushed"
            countUnit   = "days"
            countNumber = 14
          }
      }]
    }
  }
}

resource "aws_ecr_repository" "this" {
  for_each = { for k, v in var.ecrs : k => v }

  name                 = each.key
  image_tag_mutability = try(each.value.image_tag_mutability, local.defaults.image_tag_mutability)

  image_scanning_configuration {
    scan_on_push = try(each.value.scan_on_push, local.defaults.scan_on_push)
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, try(each.value.tags, null))
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = { for k, v in var.ecrs : k => v if lookup(v, "lifecycle_policy", null) != null
  && try(length(v.lifecycle_policy) > 0, false) }

  repository = aws_ecr_repository.this[each.key].id
  policy     = try(jsonencode(each.value.lifecycle_policy), jsonencode(local.defaults.lifecycle_policy))

  depends_on = [aws_ecr_repository.this]
}