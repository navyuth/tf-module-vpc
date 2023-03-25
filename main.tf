resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags       = merge(
    var.tags,
    { Name = "${var.env}-vpc" }
  )
}

# Public subnets
resource "aws_subnet" "public_subnets" {
  vpc_id = aws_vpc.main.id

  for_each = var.public_subnets
  cidr_block = each.value["cidr_block"]
  availability_zone = each.value["availability_zone"]
  tags = merge(
    var.tags,
    { Name = "${var.env}-${each.value["name"]}" }
  )
}

# Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  # only 1 igw in public
  tags = merge(
    var.tags,
    { Name = "${var.env}-igw" }
  )
}

# Public route-table
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  for_each = var.public_subnets
  tags = merge(
    var.tags,
    { Name = "${var.env}-${each.value["name"]}" }
  )
}

# Route table association {Hard part in terraform referring data}
resource "aws_route_table_association" "public-association" {
  for_each = var.public_subnets
  subnet_id = lookup(lookup(aws_subnet.public_subnets, each.value["name"], null), "id", null)
  #subnet_id      = aws_subnet.public_subnets[each.value["name"]].id
  route_table_id = aws_route_table.public-route-table[each.value["name"]].id
}

# Private Subnets
resource "aws_subnet" "private_subnets" {
  vpc_id = aws_vpc.main.id


  for_each = var.private_subnets
  cidr_block = each.value["cidr_block"]
  availability_zone = each.value["availability_zone"]
  tags = merge(
    var.tags,
    { Name = "${var.env}-${each.value["name"]}" }
  )
}

# Private route table
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.main.id

  for_each = var.private_subnets
  tags = merge(
    var.tags,
    { Name = "${var.env}-${each.value["name"]}" }
  )
}

# Route table association {Hard part in terraform referring data}
resource "aws_route_table_association" "private-association" {
  for_each = var.private_subnets
  subnet_id = lookup(lookup(aws_subnet.private_subnets, each.value["name"], null), "id", null)
  #subnet_id      = aws_subnet.public_subnets[each.value["name"]].id
  route_table_id = aws_route_table.private-route-table[each.value["name"]].id
}

