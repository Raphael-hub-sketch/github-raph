# =====================================================================
# VPC
# =====================================================================
resource "aws_vpc" "main" {
  count = var.create_vpc ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

# =====================================================================
# DNS Firewall Domain List (пользовательский список доменов)
# =====================================================================
resource "aws_route53_resolver_firewall_domain_list" "blocked" {
  name    = "${var.project_name}-${var.environment}-blocked-domains"
  domains = var.blocked_domains

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-blocked-domains"
  })
}

# =====================================================================
# DNS Firewall Rule Group
# =====================================================================
resource "aws_route53_resolver_firewall_rule_group" "main" {
  name = var.firewall_rule_group_name

  tags = merge(local.common_tags, {
    Name = var.firewall_rule_group_name
  })
}

# =====================================================================
# DNS Firewall Rule: BLOCK для заблокированных доменов
# =====================================================================
resource "aws_route53_resolver_firewall_rule" "block" {
  name                    = "${var.project_name}-${var.environment}-block-rule"
  action                  = "BLOCK"
  block_response          = "NXDOMAIN"
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.blocked.id
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.main.id
  priority                = 100
}

# =====================================================================
# DNS Firewall Rule Group Association (привязка к VPC)
# =====================================================================
resource "aws_route53_resolver_firewall_rule_group_association" "main" {
  count = var.create_vpc ? 1 : 0

  name                   = var.firewall_rule_group_association_name
  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.main.id
  vpc_id                 = aws_vpc.main[0].id
  priority               = 100

  # Mutation protection предотвращает случайное удаление защиты
  mutation_protection = var.environment == "prod" ? "ENABLED" : "DISABLED"

  tags = merge(local.common_tags, {
    Name = var.firewall_rule_group_association_name
  })
}