terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

data "aws_availability_zones" "selected" {
  state = "available"

  filter {
    name   = "zone-name"
    values = var.availability_zones
  }
}

data "aws_region" "current" {}

locals {
  azs         = var.availability_zones
  az_count    = length(var.availability_zones)
  nat_count   = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : local.az_count) : 0
  public_cidr = [for index in range(local.az_count) : cidrsubnet(var.cidr_block, 4, index)]
  app_cidr    = [for index in range(local.az_count) : cidrsubnet(var.cidr_block, 4, index + 4)]
  db_cidr     = [for index in range(local.az_count) : cidrsubnet(var.cidr_block, 4, index + 8)]
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = var.name }

  lifecycle {
    precondition {
      condition     = length(data.aws_availability_zones.selected.names) == length(var.availability_zones)
      error_message = "One or more availability_zones are not available in this region."
    }
  }
}

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.name}-default-deny" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = var.name }
}

resource "aws_subnet" "public" {
  count = local.az_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.public_cidr[count.index]
  availability_zone = local.azs[count.index]

  tags = { Name = "${var.name}-public-${local.azs[count.index]}", Tier = "public" }
}

resource "aws_subnet" "app" {
  count = local.az_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.app_cidr[count.index]
  availability_zone = local.azs[count.index]

  tags = { Name = "${var.name}-app-${local.azs[count.index]}", Tier = "app" }
}

resource "aws_subnet" "db" {
  count = local.az_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.db_cidr[count.index]
  availability_zone = local.azs[count.index]

  tags = { Name = "${var.name}-db-${local.azs[count.index]}", Tier = "db" }
}

resource "aws_eip" "nat" {
  count  = local.nat_count
  domain = "vpc"

  tags = { Name = "${var.name}-nat-${count.index}" }
}

resource "aws_nat_gateway" "this" {
  count = local.nat_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = { Name = "${var.name}-${local.azs[count.index]}" }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "${var.name}-public" }
}

resource "aws_route_table_association" "public" {
  count = local.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "app" {
  count = local.az_count

  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = local.nat_count > 0 ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[min(count.index, local.nat_count - 1)].id
    }
  }

  tags = { Name = "${var.name}-app-${local.azs[count.index]}" }
}

resource "aws_route_table_association" "app" {
  count = local.az_count

  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app[count.index].id
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.name}-db" }
}

resource "aws_route_table_association" "db" {
  count = local.az_count

  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db.id
}

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.app[*].id

  tags = { Name = "${var.name}-s3" }
}
