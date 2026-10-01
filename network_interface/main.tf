# main.tf
# Основные ресурсы: VPC, Network Interfaces и связанные компоненты

# ============================================================
# RANDOM ID FOR RESOURCE NAMING
# ============================================================

resource "random_id" "suffix" {
  byte_length = 4
}

# ============================================================
# VPC
# ============================================================
# VPC, в которой будут созданы Network Interfaces.
# VPC сам по себе бесплатен.
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
# SUBNETS
# ============================================================
# Создаём подсети для размещения ENI.
# Подсети бесплатны.
# ============================================================

resource "aws_subnet" "this" {
  count = var.subnet_count

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = var.enable_public_ip

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-subnet-${count.index + 1}"
  })

  # ============================================================
  # COST IMPACT: Subnet
  # ============================================================
  # Subnets are free.
  # Public IPs (if assigned) cost $0.005/hour [citation:10].
  # ============================================================
}

# ============================================================
# INTERNET GATEWAY (для публичных подсетей)
# ============================================================

resource "aws_internet_gateway" "this" {
  count = var.enable_public_ip ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })

  # ============================================================
  # COST IMPACT: Internet Gateway
  # ============================================================
  # Internet Gateway is free.
  # ============================================================
}

# ============================================================
# SECURITY GROUP
# ============================================================
# Security Group для ENI.
# Security Group бесплатен.
# ============================================================

resource "aws_security_group" "this" {
  name        = "${var.project_name}-${var.environment}-sg-${random_id.suffix.hex}"
  description = "Security group for demo ENIs"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow all traffic from self"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-sg"
  })

  # ============================================================
  # COST IMPACT: Security Group
  # ============================================================
  # Security Groups are free.
  # ============================================================
}

# ============================================================
# MAIN RESOURCE: NETWORK INTERFACE
# ============================================================
# Ресурс aws_network_interface является основным.
#
# Стоимость этого ресурса: $0.00 (сам ресурс бесплатен).
# AWS не взимает плату за создание или использование ENI.
#
# Косвенные затраты могут возникать от:
#   - Public IPv4: $0.005/hour [citation:10]
#   - Traffic Mirroring: $0.015/hour [citation:1]
# ============================================================

resource "aws_network_interface" "this" {
  count = var.eni_count

  subnet_id = aws_subnet.this[count.index % var.subnet_count].id

  # Описание ENI
  description = "${var.eni_description} - ${count.index + 1}"

  # Приватные IP-адреса (если указаны, иначе AWS назначит автоматически)
  private_ips = var.private_ips

  # Количество приватных IP (если private_ips не указан)
  private_ips_count = var.private_ips == null ? var.private_ips_count : null

  # Security Groups
  security_groups = [aws_security_group.this.id]

  # Проверка источника/назначения
  source_dest_check = var.enable_source_dest_check

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-eni-${count.index + 1}"
  })

  # ============================================================
  # ИМИТАЦИЯ ЗАТРАТ ДЛЯ aws_network_interface
  # ============================================================
  # Base Resource Cost: $0.00 (сам ресурс бесплатен)
  # Public IPv4: ~$${local.monthly_public_ipv4_cost} (${var.enable_public_ip ? "enabled" : "disabled"})
  # Traffic Mirroring: ~$${local.monthly_traffic_mirroring_cost} (${var.enable_traffic_mirroring ? "enabled" : "disabled"})
  # Network Access Analyzer: ~$${local.monthly_network_access_analyzer_cost} (${var.enable_network_access_analyzer ? "enabled" : "disabled"})
  # ---------------------------------
  # Estimated Monthly Total: ~$${local.estimated_monthly_cost}
  # ============================================================
}

# ============================================================
# ROUTE TABLE (для публичных подсетей)
# ============================================================

resource "aws_route_table" "public" {
  count = var.enable_public_ip ? 1 : 0

  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = var.enable_public_ip ? var.subnet_count : 0

  subnet_id      = aws_subnet.this[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# ============================================================
# DATA SOURCES
# ============================================================

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}