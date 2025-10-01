resource "aws_eip" "nat" {
  for_each = toset(var.public_subnet_ids)
  domain   = "vpc"
}

# Create one NAT Gateway for each Elastic IP, placing it in the corresponding public subnet.
resource "aws_nat_gateway" "this" {
  for_each      = toset(var.public_subnet_ids)
  allocation_id = aws_eip.nat[each.value].id
  subnet_id     = each.value # The key here is using the subnet ID from the for_each loop

  tags = {
    # Extract AZ from the subnet data source for a more descriptive name
    Name = "${var.name}-${data.aws_subnet.public[each.value].availability_zone}"
  }
}

# Create a unique route table for each private subnet.
resource "aws_route_table" "private" {
  for_each = var.private_subnet_ids
  vpc_id   = var.vpc_id

  tags = {
    Name = "${var.name}-private-rt-${each.key}" # e.g., strapi-nat-private-rt-us-east-1a
  }
}

# Create a route in each private route table that points to the NAT Gateway
# located in the SAME Availability Zone.
resource "aws_route" "private_nat_gateway" {
  for_each               = aws_route_table.private
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  # This is the magic: Match the private subnet's AZ with the NAT Gateway's AZ
  nat_gateway_id = aws_nat_gateway.this[data.aws_subnet.public[each.key].availability_zone].id
}

# Associate each private subnet with its corresponding new route table.
resource "aws_route_table_association" "private" {
  for_each       = var.private_subnet_ids
  subnet_id      = each.value
  route_table_id = aws_route_table.private[each.key].id
}

# --- Data Sources to look up AZ information ---
data "aws_subnet" "public" {
  for_each = toset(var.public_subnet_ids)
  id       = each.value
}