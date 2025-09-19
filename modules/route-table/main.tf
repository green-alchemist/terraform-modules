resource "aws_route_table" "route_table" {
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
  for_each       = var.subnet_ids
  subnet_id      = each.value.id
  route_table_id = aws_route_table.route_table.id
}

