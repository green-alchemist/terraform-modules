resource "aws_route_table" "route_table" {
  count  = var.route_table_should_be_created ? 1 : 0
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.internet_gateway_id
  }

  tags = {
    Name = var.route_table_name
  }
}

resource "aws_route_table_association" "route_table_association" {
  for_each       = toset(var.subnet_ids)
  subnet_id      = each.value
  route_table_id = aws_route_table.route_table.id
}

