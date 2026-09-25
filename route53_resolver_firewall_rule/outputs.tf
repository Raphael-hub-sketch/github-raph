output "firewall_rule_id" {
  description = "ID созданного firewall rule"
  value       = aws_route53_resolver_firewall_rule.block.id
}

output "firewall_rule_name" {
  description = "Имя firewall rule"
  value       = aws_route53_resolver_firewall_rule.block.name
}

output "firewall_rule_action" {
  description = "Действие firewall rule"
  value       = aws_route53_resolver_firewall_rule.block.action
}

output "firewall_rule_priority" {
  description = "Приоритет firewall rule"
  value       = aws_route53_resolver_firewall_rule.block.priority
}

output "allow_rule_id" {
  description = "ID ALLOW-правила (если создано)"
  value       = var.create_allow_rule ? aws_route53_resolver_firewall_rule.allow[0].id : null
}

output "alert_rule_id" {
  description = "ID ALERT-правила (если создано)"
  value       = var.create_alert_rule ? aws_route53_resolver_firewall_rule.alert[0].id : null
}

output "domain_list_id" {
  description = "ID списка заблокированных доменов"
  value       = aws_route53_resolver_firewall_domain_list.blocked.id
}

output "domain_list_arn" {
  description = "ARN списка заблокированных доменов"
  value       = aws_route53_resolver_firewall_domain_list.blocked.arn
}

output "rule_group_id" {
  description = "ID группы правил DNS Firewall"
  value       = aws_route53_resolver_firewall_rule_group.main.id
}

output "rule_group_arn" {
  description = "ARN группы правил DNS Firewall"
  value       = aws_route53_resolver_firewall_rule_group.main.arn
}

output "rule_group_association_id" {
  description = "ID ассоциации группы правил с VPC"
  value       = var.create_vpc ? aws_route53_resolver_firewall_rule_group_association.main[0].id : null
}

output "vpc_id" {
  description = "ID созданного VPC"
  value       = var.create_vpc ? aws_vpc.main[0].id : null
}

# ---------------------------------------------------------------------
# ИМИТАЦИЯ ЗАТРАТ: выходные данные для FinOps
# ---------------------------------------------------------------------
output "cost_report" {
  description = "Детализированный отчёт по предполагаемым затратам (имитация)"
  value = {
    metadata          = local.cost_report_metadata
    line_items        = local.cost_line_items
    by_category       = local.cost_by_category
    by_service        = local.cost_by_service
    by_environment    = local.cost_by_environment
    monthly_total_usd = local.cost_monthly_total
    yearly_total_usd  = local.cost_yearly_total
    monthly_forecast  = local.monthly_forecast
    yearly_projection = local.yearly_projection
    scenarios         = local.scenario_comparison
    budget            = local.budget_thresholds
    quota_checks      = local.quota_checks
    rule_action_details = local.rule_action_details
    managed_domain_lists = local.managed_domain_lists
  }
}

output "cost_summary" {
  description = "Краткая сводка затрат"
  value = {
    monthly_usd = format("%.2f", local.cost_monthly_total)
    yearly_usd  = format("%.2f", local.cost_yearly_total)
    currency    = local.cost_currency
    breakdown   = local.cost_by_service
  }
}

output "budget_alerts" {
  description = "Пороги для AWS Budgets"
  value       = local.budget_thresholds
}

output "billing_note" {
  description = "Важное примечание о биллинге Route53 Resolver DNS Firewall"
  value       = local.cost_report_metadata.billing_note
}