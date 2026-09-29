output "sns_topic_arn" {
  description = "ARN SNS Topic (созданного или существующего)"
  value       = local.topic_arn
}

output "sns_topic_name" {
  description = "Имя SNS Topic"
  value       = var.create_topic ? aws_sns_topic.main[0].name : null
}

output "subscription_ids" {
  description = "ID всех созданных подписок"
  value       = aws_sns_topic_subscription.main[*].id
}

output "subscription_arns" {
  description = "ARN всех созданных подписок"
  value       = aws_sns_topic_subscription.main[*].arn
}

output "subscription_endpoints" {
  description = "Endpoints всех подписок"
  value       = aws_sns_topic_subscription.main[*].endpoint
}

output "subscription_protocols" {
  description = "Протоколы всех подписок"
  value       = aws_sns_topic_subscription.main[*].protocol
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
    subscriber_type_details = local.subscriber_type_details
    subscriptions_by_protocol = local.subscription_counts
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