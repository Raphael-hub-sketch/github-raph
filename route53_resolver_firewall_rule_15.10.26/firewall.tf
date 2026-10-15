# =====================================================================
# DNS Firewall Domain List: заблокированные домены
# =====================================================================
resource "aws_route53_resolver_firewall_domain_list" "blocked" {
  name    = "${var.project_name}-${var.environment}-blocked-domains"
  domains = var.blocked_domains

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-blocked-domains"
  })
}

# =====================================================================
# DNS Firewall Domain List: разрешённые домены
# =====================================================================
resource "aws_route53_resolver_firewall_domain_list" "allowed" {
  count = var.create_allow_rule ? 1 : 0

  name    = "${var.project_name}-${var.environment}-allowed-domains"
  domains = var.allowed_domains

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-allowed-domains"
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
# DNS Firewall Rule Group Association (привязка к VPC)
# =====================================================================
resource "aws_route53_resolver_firewall_rule_group_association" "main" {
  count = var.create_vpc ? 1 : 0

  name                   = var.firewall_rule_group_association_name
  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.main.id
  vpc_id                 = aws_vpc.main[0].id
  priority               = 100

  mutation_protection = var.environment == "prod" ? "ENABLED" : "DISABLED"

  tags = merge(local.common_tags, {
    Name = var.firewall_rule_group_association_name
  })
}