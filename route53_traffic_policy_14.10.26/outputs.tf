output "traffic_policy_id" {
  description = "ID созданной traffic policy"
  value       = aws_route53_traffic_policy.main.id
}

output "traffic_policy_arn" {
  description = "ARN созданной traffic policy"
  value       = aws_route53_traffic_policy.main.arn
}

output "traffic_policy_version" {
  description = "Версия traffic policy (автоматически инкрементируется AWS)"
  value       = aws_route53_traffic_policy.main.version
}

output "traffic_policy_type" {
  description = "DNS-тип ресурсных записей"
  value       = aws_route53_traffic_policy.main.type
}

output "traffic_policy_instance_id" {
  description = "ID traffic policy instance (если создан)"
  value       = var.create_instance ? aws_route53_traffic_policy_instance.main[0].id : null
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
    rule_type_details = local.rule_type_details
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
  description = "Важное примечание о биллинге Traffic Flow"
  value       = local.cost_report_metadata.billing_note
}