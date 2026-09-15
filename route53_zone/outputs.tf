output "zone_id" {
  description = "ID созданной hosted zone"
  value       = aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "NS-серверы для делегирования домена"
  value       = aws_route53_zone.main.name_servers
}

output "zone_arn" {
  description = "ARN hosted zone"
  value       = aws_route53_zone.main.arn
}

output "query_log_group_name" {
  description = "Имя CloudWatch Log Group для DNS-логов"
  value       = var.create_query_log ? aws_cloudwatch_log_group.dns_query_log[0].name : null
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