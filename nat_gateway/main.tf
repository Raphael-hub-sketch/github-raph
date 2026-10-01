# main.tf
# Основные ресурсы: VPC, NAT Gateway и связанные компоненты

# ============================================================
# RANDOM ID FOR RESOURCE NAMING
# ============================================================

resource "random_id" "suffix" {
  byte_length = 4
}

# ============================================================
# VPC
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
  # VPC is free.
  # ============================================================
}

# ============================================================
# INTERNET GATEWAY
# ============================================================
# Интернет-шлюз требуется для публичного NAT Gateway.
# Internet Gateway бесплатен.
# ============================================================

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })

  # ============================================================
  # COST IMPACT: Internet Gateway
  # ============================================================
  # Internet Gateway is free [citation:9].
  # Data transfer out to internet costs $0.09/GB.
  # ============================================================
}

# ============================================================
# PUBLIC SUBNETS
# ============================================================
# Публичные подсети для размещения NAT Gateway.
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
  # Subnets are free.
  # Public IPs (if assigned) cost $0.005/hour.
  # ============================================================
}

# ============================================================
# PRIVATE SUBNETS
# ============================================================
# Приватные подсети, которые будут использовать NAT Gateway
# для доступа в интернет.
# ============================================================

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
# ELASTIC IP FOR NAT GATEWAY
# ============================================================
# Elastic IP требуется для публичного NAT Gateway.
# Public IPv4 стоит $0.005/час.
# ============================================================

resource "aws_eip" "nat" {
  count = var.connectivity_type == "public" ? var.nat_gateway_count : 0

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
  })

  # ============================================================
  # COST IMPACT: Elastic IP
  # ============================================================
  # Public IPv4 addresses cost $0.005/hour.
  # For 1 EIP: ~$3.65/month.
  # ============================================================

  depends_on = [aws_internet_gateway.this]
}

# ============================================================
# MAIN RESOURCE: NAT GATEWAY
# ============================================================
# Ресурс aws_nat_gateway является основным.
# Стоимость: $0.045/час + $0.045/GB [citation:3][citation:9].
# Почасовая плата взимается даже при нулевом трафике [citation:13].
# ============================================================

resource "aws_nat_gateway" "this" {
  count = var.nat_gateway_count

  # Для публичного NAT требуется allocation_id
  allocation_id = var.connectivity_type == "public" ? aws_eip.nat[count.index].id : null

  # Подсеть для размещения NAT Gateway
  subnet_id = aws_subnet.public[count.index].id

  # Тип подключения: public или private
  connectivity_type = var.connectivity_type

  tags = merge(local.common_tags, {
    Name = "${local.nat_gateway_name}-${count.index + 1}"
  })

  # Явная зависимость от Internet Gateway для правильного порядка
  depends_on = [aws_internet_gateway.this]

  # ============================================================
  # ИМИТАЦИЯ ЗАТРАТ ДЛЯ aws_nat_gateway
  # ============================================================
  # Hourly Charge (${var.nat_gateway_count} × ${var.monthly_hours}h): ~$${local.monthly_hourly_cost}
  # Data Processing (${var.monthly_data_processed_gb} GB): ~$${local.monthly_data_cost}
  # Public IPv4 (${var.nat_gateway_count} addresses): ~$${local.monthly_ipv4_cost}
  # ---------------------------------
  # Estimated Monthly Total: ~$${local.estimated_monthly_cost}
  # ============================================================
}

# ============================================================
# ROUTE TABLE FOR PUBLIC SUBNETS
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
}

resource "aws_route_table_association" "public" {
  count = var.public_subnet_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ============================================================
# ROUTE TABLE FOR PRIVATE SUBNETS
# ============================================================
# Маршрут через NAT Gateway для доступа в интернет.
# ============================================================

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[0].id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-rt"
  })

  # ============================================================
  # COST IMPACT: Route through NAT
  # ============================================================
  # All traffic from private subnets to internet goes through NAT.
  # Each GB processed costs $0.045 [citation:3][citation:9].
  # ============================================================
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