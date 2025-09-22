resource "aws_subnet" "this" {
  for_each                = var.subnets
  vpc_id                  = var.vpc_id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = var.assign_public_ip_on_launch

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${each.key}"
  })
}