resource "aws_ssm_parameter" "this" {
  for_each = var.parameters

  name        = each.key
  description = try(each.value.description, null)
  type        = try(each.value.type, "String")
  value       = each.value.value
  tier        = try(each.value.tier, "Standard")
  overwrite   = try(each.value.overwrite, false)

  tags = var.tags
}
