output "domain_name" {
  description = "Имя зарегистрированного домена"
  value       = aws_route53domains_registered_domain.main.domain_name
}

output "domain_status" {
  description = "Статус домена"
  value       = aws_route53domains_registered_domain.main.status
}

output "auto_renew_enabled" {
  description = "Включено ли автоматическое продление"
  value       = aws_route53domains_registered_domain.main.auto_renew
}

output "transfer_lock_enabled" {
  description = "Включена ли блокировка трансфера"
  value       = aws_route53domains_registered_domain.main.transfer_lock
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

output "domain_pricing_reference" {
  description = "Справочник цен по TLD"
  value       = local.domain_pricing
}