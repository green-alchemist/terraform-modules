resource "aws_route_table" "public" {
  count  = var.create_public_route_table ? 1 : 0
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.internet_gateway_id
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

resource "aws_route_table" "private" {
  count  = var.create_private_route_table ? 1 : 0
  vpc_id = var.vpc_id

  # No route to 0.0.0.0/0, making it private.
  # Routes for endpoints will be added by the endpoint resources themselves.

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-rt"
  })
}

resource "aws_route_table_association" "public" {
  for_each       = var.public_subnets_map
  route_table_id = aws_route_table.public[0].id
  subnet_id      = each.value.id
}

resource "aws_route_table_association" "private" {
  for_each       = var.private_subnets_map
  route_table_id = aws_route_table.private[0].id
  subnet_id      = each.value.id
}