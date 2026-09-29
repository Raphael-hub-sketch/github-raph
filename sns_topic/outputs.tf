output "sns_topic_id" {
  description = "ID созданного SNS Topic"
  value       = aws_sns_topic.main.id
}

output "sns_topic_arn" {
  description = "ARN созданного SNS Topic"
  value       = aws_sns_topic.main.arn
}

output "sns_topic_name" {
  description = "Имя SNS Topic"
  value       = aws_sns_topic.main.name
}

output "sns_topic_owner" {
  description = "AWS Account ID владельца топика"
  value       = aws_sns_topic.main.owner
}

output "sns_topic_policy_id" {
  description = "ID политики топика (если создана)"
  value       = var.create_topic_policy ? aws_sns_topic_policy.main[0].id : null
}

# ---------------------------------------------------------------------
# ИМИТАЦИЯ ЗАТРАТ: выходные данные для FinOps
# ---------------------------------------------------------------------
output "cost_report" {
  description = "Детализированный отчёт по предполагаемым затратам (имитация)"
  value = {
    metadata               = local.cost_report_metadata
    line_items             = local.cost_line_items
    by_category            = local.cost_by_category
    by_service             = local.cost_by_service
    by_environment         = local.cost_by_environment
    monthly_total_usd      = local.cost_monthly_total
    yearly_total_usd       = local.cost_yearly_total
    monthly_forecast       = local.monthly_forecast
    yearly_projection      = local.yearly_projection
    scenarios              = local.scenario_comparison
    budget                 = local.budget_thresholds
    quota_checks           = local.quota_checks
    subscriber_type_details = local.subscriber_type_details
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
  description = "Важное примечание о биллинге SNS"
  value       = local.cost_report_metadata.billing_note
}