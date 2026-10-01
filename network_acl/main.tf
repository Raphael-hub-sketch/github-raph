# main.tf
# Основные ресурсы: VPC, Network ACL и связанные компоненты

# ============================================================
# RANDOM ID FOR RESOURCE NAMING
# ============================================================

resource "random_id" "suffix" {
  byte_length = 4
}

# ============================================================
# VPC
# ============================================================
# VPC, для которой будет создана Network ACL.
# VPC сам по себе бесплатен [citation:15].
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
  # VPC is free [citation:15].
  # ============================================================
}

# ============================================================
# MAIN RESOURCE: NETWORK ACL
# ============================================================
# Ресурс aws_network_acl является основным.
#
# ВАЖНО: В Terraform есть два подхода:
#   1. Inline-правила в aws_network_acl (используется здесь)
#   2. Отдельные aws_network_acl_rule ресурсы
#
# НЕЛЬЗЯ смешивать оба подхода — это вызовет конфликт [citation:2][citation:3].
#
# Стоимость этого ресурса: $0.00 (сам ресурс бесплатен).
# AWS не взимает плату за использование network ACLs [citation:5].
# ============================================================

resource "aws_network_acl" "this" {
  vpc_id = aws_vpc.this.id

  # ============================================================
  # INGRESS RULES
  # ============================================================
  # Правила входящего трафика.
  # Оцениваются по номеру от меньшего к большему [citation:1].
  # ============================================================

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      rule_no    = ingress.value.rule_no
      action     = ingress.value.action
      protocol   = ingress.value.protocol
      cidr_block = ingress.value.cidr_block
      ipv6_cidr_block = ingress.value.ipv6_cidr_block
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
      icmp_type  = ingress.value.icmp_type
      icmp_code  = ingress.value.icmp_code
    }
  }

  # ============================================================
  # EGRESS RULES
  # ============================================================
  # Правила исходящего трафика.
  # NACL stateless — ответы требуют отдельного правила [citation:1][citation:8].
  # ============================================================

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      rule_no    = egress.value.rule_no
      action     = egress.value.action
      protocol   = egress.value.protocol
      cidr_block = egress.value.cidr_block
      ipv6_cidr_block = egress.value.ipv6_cidr_block
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
      icmp_type  = egress.value.icmp_type
      icmp_code  = egress.value.icmp_code
    }
  }

  # ============================================================
  # SUBNET ASSOCIATIONS
  # ============================================================
  # Ассоциации с подсетями.
  # Каждая подсеть может быть связана только с одной NACL [citation:1].
  # ============================================================

  subnet_ids = concat(
    aws_subnet.public[*].id,
    aws_subnet.private[*].id
  )

  tags = merge(local.common_tags, {
    Name = local.nacl_name
  })

  # ============================================================
  # ИМИТАЦИЯ ЗАТРАТ ДЛЯ aws_network_acl
  # ============================================================
  # Base Resource Cost: $0.00 (сам ресурс бесплатен) [citation:5]
  # NACL Processing (${var.monthly_data_processed_gb} GB): ~$${local.nacl_processing_cost}
  # Cross-AZ Transfer (${var.cross_az_data_gb} GB): ~$${local.cross_az_cost}
  # NAT Gateway (optional): ~$${local.nat_total_cost}
  # ---------------------------------
  # Estimated Monthly Total: ~$${local.estimated_monthly_cost}
  # ============================================================
}

# ============================================================
# SUBNETS
# ============================================================
# Создаём подсети для ассоциации с NACL.
# Подсети бесплатны [citation:15].
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
  # Subnets are free [citation:15].
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
# INTERNET GATEWAY (для контекста)
# ============================================================
# Интернет-шлюз для публичных подсетей.
# Internet Gateway бесплатен [citation:14].
# ============================================================

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })

  # ============================================================
  # COST IMPACT: Internet Gateway
  # ============================================================
  # Internet Gateway is free [citation:14].
  # Data transfer out to internet costs $0.09/GB.
  # ============================================================
}

# ============================================================
# ROUTE TABLES (для полноты картины)
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