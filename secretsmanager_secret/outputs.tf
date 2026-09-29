output "secret_id" {
  description = "ID созданного секрета"
  value       = aws_secretsmanager_secret.main.id
}

output "secret_arn" {
  description = "ARN созданного секрета"
  value       = aws_secretsmanager_secret.main.arn
}

output "secret_name" {
  description = "Имя секрета"
  value       = aws_secretsmanager_secret.main.name
}

output "secret_version_id" {
  description = "ID версии секрета (если создана)"
  value       = var.create_secret_version ? aws_secretsmanager_secret_version.main[0].version_id : null
}

output "secret_policy_id" {
  description = "ID политики секрета (если создана)"
  value       = var.create_policy ? aws_secretsmanager_secret_policy.main[0].id : null
}

# ---------------------------------------------------------------------
# ИМИТАЦИЯ ЗАТРАТ: выходные данные для FinOps
# ---------------------------------------------------------------------
output "cost_report" {
  description = "Детализированный отчёт по предполагаемым затратам (имитация)"
  value = {
    metadata                  = local.cost_report_metadata
    line_items                = local.cost_line_items
    by_category               = local.cost_by_category
    by_service                = local.cost_by_service
    by_environment            = local.cost_by_environment
    monthly_total_usd         = local.cost_monthly_total
    yearly_total_usd          = local.cost_yearly_total
    monthly_forecast          = local.monthly_forecast
    yearly_projection         = local.yearly_projection
    scenarios                 = local.scenario_comparison
    budget                    = local.budget_thresholds
    quota_checks              = local.quota_checks
    parameter_store_comparison = local.parameter_store_comparison
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
  description = "Важное примечание о биллинге Secrets Manager"
  value       = local.cost_report_metadata.billing_note
}