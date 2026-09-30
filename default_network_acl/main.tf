# main.tf
# Основные ресурсы: VPC и Default Network ACL

# ============================================================
# RANDOM ID FOR RESOURCE NAMING
# ============================================================

resource "random_id" "suffix" {
  byte_length = 4
}

# ============================================================
# VPC
# ============================================================
# VPC, для которой будет управляться default network ACL.
# VPC сам по себе бесплатен [citation:5].
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
  # VPC is free [citation:5].
  # Costs arise from components like NAT Gateway, Public IPv4 [citation:5].
  # ============================================================
}

# ============================================================
# SUBNETS (для демонстрации ассоциаций)
# ============================================================
# Создаём подсети, чтобы показать, как управлять ассоциациями
# с default network ACL.
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
  # Subnets are free.
  # Public IPs (if assigned) cost $0.005/hour [citation:4].
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
  # Internet Gateway is free.
  # Data transfer out to internet costs $0.09/GB [citation:4].
  # ============================================================
}

# ============================================================
# MAIN RESOURCE: DEFAULT NETWORK ACL
# ============================================================
# Ресурс aws_default_network_acl является основным.
# ВАЖНО: Terraform не создаёт этот ресурс, а "принимает" его
# под управление. При первом принятии все существующие правила
# удаляются, затем создаются указанные в конфигурации [citation:1].
#
# Стоимость этого ресурса: $0.00 (сам ресурс бесплатен).
# AWS не взимает плату за использование network ACLs [citation:3][citation:6].
# ============================================================

resource "aws_default_network_acl" "this" {
  default_network_acl_id = aws_vpc.this.default_network_acl_id

  # ============================================================
  # INGRESS RULES
  # ============================================================
  # Правила входящего трафика.
  # Только правила, определённые здесь, будут созданы.
  # Любые изменения вне Terraform вызовут drift [citation:1].
  # ============================================================

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      rule_no    = ingress.value.rule_no
      action     = ingress.value.action
      protocol   = ingress.value.protocol
      cidr_block = ingress.value.cidr_block
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
    }
  }

  # ============================================================
  # EGRESS RULES
  # ============================================================
  # Правила исходящего трафика.
  # ============================================================

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      rule_no    = egress.value.rule_no
      action     = egress.value.action
      protocol   = egress.value.protocol
      cidr_block = egress.value.cidr_block
      from_port  = egress.value.from_port
      to_port    = egress.value.to_port
    }
  }

  # ============================================================
  # SUBNET ASSOCIATIONS
  # ============================================================
  # Ассоциации с подсетями.
  # Управление ассоциациями может быть сложным, поэтому
  # используем опциональный подход [citation:1].
  # ============================================================

  subnet_ids = var.manage_subnet_associations ? var.subnet_ids : null

  # ============================================================
  # LIFECYCLE
  # ============================================================
  # Игнорирование изменений subnet_ids рекомендуется, чтобы
  # избежать повторяющихся планов [citation:1][citation:2].
  # ============================================================

  lifecycle {
    ignore_changes = var.ignore_subnet_changes ? [subnet_ids] : []
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-default-nacl"
  })

  # ============================================================
  # ИМИТАЦИЯ ЗАТРАТ ДЛЯ aws_default_network_acl
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