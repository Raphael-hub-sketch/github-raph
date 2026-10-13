output "health_check_id" {
  description = "ID созданного health check"
  value       = aws_route53_health_check.main.id
}

output "health_check_arn" {
  description = "ARN созданного health check"
  value       = aws_route53_health_check.main.arn
}

output "health_check_fqdn" {
  description = "FQDN проверяемого endpoint"
  value       = aws_route53_health_check.main.fqdn
}

output "health_check_type" {
  description = "Тип health check"
  value       = aws_route53_health_check.main.type
}

output "cloudwatch_alarm_id" {
  description = "ID CloudWatch Alarm (если создан)"
  value       = var.create_cloudwatch_alarm ? aws_cloudwatch_metric_alarm.health_check[0].id : null
}

# ---------------------------------------------------------------------
# ИМИТАЦИЯ ЗАТРАТ: выходные данные для FinOps
# ---------------------------------------------------------------------
output "cost_report" {
  description = "Детализированный отчёт по предполагаемым затратам (имитация)"
  value = {
    metadata                = local.cost_report_metadata
    line_items              = local.cost_line_items
    by_category             = local.cost_by_category
    by_service              = local.cost_by_service
    by_environment          = local.cost_by_environment
    monthly_total_usd       = local.cost_monthly_total
    yearly_total_usd        = local.cost_yearly_total
    monthly_forecast        = local.monthly_forecast
    yearly_projection       = local.yearly_projection
    scenarios               = local.scenario_comparison
    budget                  = local.budget_thresholds
    quota_checks            = local.quota_checks
    health_check_type_details = local.health_check_type_details
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
  description = "Важное примечание о биллинге Route53 Health Checks"
  value       = local.cost_report_metadata.billing_note
}