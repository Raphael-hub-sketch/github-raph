# main.tf
# Основные ресурсы: VPC, Internet Gateway и связанные компоненты

# ============================================================
# RANDOM ID FOR RESOURCE NAMING
# ============================================================

resource "random_id" "suffix" {
  byte_length = 4
}

# ============================================================
# VPC
# ============================================================
# VPC, для которой будет создан Internet Gateway.
# VPC сам по себе бесплатен [citation:16].
# ============================================================

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })

  # ============================================================
  # COST IMPACT: VPC
  # ============================================================
  # VPC is free [citation:16].
  # Costs arise from components like NAT Gateway, Public IPv4.
  # ============================================================
}

# ============================================================
# MAIN RESOURCE: INTERNET GATEWAY
# ============================================================
# Ресурс aws_internet_gateway является основным.
# Это горизонтально масштабируемый, избыточный и
# высокодоступный компонент VPC [citation:14].
#
# Стоимость этого ресурса: $0.00 (сам ресурс бесплатен).
# AWS явно указывает: "There is no charge for an internet gateway"
# [citation:6][citation:14].
# ============================================================

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = local.igw_name
  })

  # ============================================================
  # ИМИТАЦИЯ ЗАТРАТ ДЛЯ aws_internet_gateway
  # ============================================================
  # Base Resource Cost: $0.00 (сам ресурс бесплатен) [citation:6]
  # Monthly Egress (${var.monthly_egress_gb} GB): ~$${local.monthly_egress_cost}
  # Monthly Ingress (${var.monthly_ingress_gb} GB): ~$${local.monthly_ingress_cost}
  # ---------------------------------
  # Estimated Monthly Total: ~$${local.estimated_monthly_cost}
  # ============================================================
}

# ============================================================
# SUBNETS
# ============================================================
# Создаём публичные и приватные подсети для полноты картины.
# ============================================================

resource "aws_subnet" "public" {
  count = var.public_subnet_count

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-${count.index + 1}"
    Tier = "public"
  })

  # ============================================================
  # COST IMPACT: Subnet
  # ============================================================
  # Subnets are free [citation:16].
  # Public IPs (if assigned) cost $0.005/hour.
  # ============================================================
}

resource "aws_subnet" "private" {
  count = var.private_subnet_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-${count.index + 1}"
    Tier = "private"
  })
}

# ============================================================
# ROUTE TABLE FOR PUBLIC SUBNETS
# ============================================================
# Публичная таблица маршрутизации с маршрутом через Internet Gateway.
# ============================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
  })

  # ============================================================
  # COST IMPACT: Route Table
  # ============================================================
  # Route Tables are free.
  # Routes through IGW incur no per-GB processing charge [citation:13].
  # ============================================================
}

resource "aws_route_table_association" "public" {
  count = var.public_subnet_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ============================================================
# ROUTE TABLE FOR PRIVATE SUBNETS
# ============================================================
# Приватная таблица маршрутизации (без выхода в интернет).
# ============================================================

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  count = var.private_subnet_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ============================================================
# DATA SOURCES
# ============================================================

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}