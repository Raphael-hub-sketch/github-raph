# main.tf
# Основные ресурсы: VPC и Default Security Group

# ============================================================
# RANDOM ID FOR RESOURCE NAMING
# ============================================================

resource "random_id" "suffix" {
  byte_length = 4
}

# ============================================================
# VPC
# ============================================================
# VPC, для которой будет управляться default security group.
# VPC сам по себе бесплатен [citation:11].
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
  # VPC is free [citation:11].
  # Costs arise from components like NAT Gateway, Public IPv4 [citation:15].
  # ============================================================
}

# ============================================================
# SUBNETS (для демонстрации)
# ============================================================
# Создаём подсети для полноты картины.
# ============================================================

resource "aws_subnet" "public" {
  count = 2

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
  # Subnets are free [citation:11].
  # Public IPs (if assigned) cost $0.005/hour [citation:15].
  # ============================================================
}

resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-${count.index + 1}"
    Tier = "private"
  })
}

# ============================================================
# INTERNET GATEWAY
# ============================================================
# Интернет-шлюз для публичных подсетей.
# ============================================================

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })

  # ============================================================
  # COST IMPACT: Internet Gateway
  # ============================================================
  # Internet Gateway is free [citation:11].
  # Data transfer out to internet costs $0.09/GB [citation:15].
  # ============================================================
}

# ============================================================
# MAIN RESOURCE: DEFAULT SECURITY GROUP
# ============================================================
# Ресурс aws_default_security_group является основным.
#
# ВАЖНО: Terraform не создаёт этот ресурс, а "принимает" его
# под управление. При первом принятии все существующие правила
# удаляются, затем создаются указанные в конфигурации [citation:2].
#
# Ресурс не может быть удалён — default security group существует
# в каждом VPC и не может быть удалён [citation:8][citation:9].
#
# Стоимость этого ресурса: $0.00 (сам ресурс бесплатен).
# AWS не взимает плату за использование security groups [citation:6][citation:10][citation:19].
# ============================================================

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  # ============================================================
  # INGRESS RULES
  # ============================================================
  # Правила входящего трафика.
  # Только правила, определённые здесь, будут созданы.
  # Любые изменения вне Terraform вызовут drift [citation:2].
  # ============================================================

  dynamic "ingress" {
    for_each = var.manage_ingress_rules ? var.ingress_rules : []
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      self        = ingress.value.self
      description = ingress.value.description
    }
  }

  # ============================================================
  # EGRESS RULES
  # ============================================================
  # Правила исходящего трафика.
  # ============================================================

  dynamic "egress" {
    for_each = var.manage_egress_rules ? var.egress_rules : []
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      self        = egress.value.self
      description = egress.value.description
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-default-sg"
  })

  # ============================================================
  # ИМИТАЦИЯ ЗАТРАТ ДЛЯ aws_default_security_group
  # ============================================================
  # Base Resource Cost: $0.00 (сам ресурс бесплатен)
  # Monthly Data Processing (${var.monthly_data_processed_gb} GB): ~$${local.data_processing_cost}
  # Monthly Rule Evaluations: ~$${local.rule_evaluation_cost}
  # ---------------------------------
  # Estimated Monthly Total: ~$${local.estimated_monthly_cost}
  # ============================================================
}

# ============================================================
# DATA SOURCES
# ============================================================

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}