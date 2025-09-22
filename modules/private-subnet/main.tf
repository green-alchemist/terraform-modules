resource "aws_subnet" "private_subnet" {
  for_each          = var.private_subnets
  vpc_id            = var.vpc_id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(var.tags, {
    Name = "private-subnet-${each.key}"
  })
}