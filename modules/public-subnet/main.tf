resource "aws_subnet" "public_subnet" {
  # count                   = var.subnet_should_be_created ? 1 : 0
  for_each                = var.public_subnets
  vpc_id                  = var.vpc_id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "public-subnet-${each.key}"
  })
}
