# outputs.tf
output "platform_application_arn" {
  description = "ARN SNS Platform Application"
  value       = aws_sns_platform_application.main.arn
}

output "platform_application_id" {
  description = "ID SNS Platform Application"
  value       = aws_sns_platform_application.main.id
}

output "platform_application_name" {
  description = "Имя SNS Platform Application"
  value       = aws_sns_platform_application.main.name
}

output "event_endpoint_created_topic_arn" {
  description = "ARN топика endpoint created"
  value       = var.create_event_topics ? aws_sns_topic.event_endpoint_created[0].arn : null
}

output "event_endpoint_updated_topic_arn" {
  description = "ARN топика endpoint updated"
  value       = var.create_event_topics ? aws_sns_topic.event_endpoint_updated[0].arn : null
}

output "event_endpoint_deleted_topic_arn" {
  description = "ARN топика endpoint deleted"
  value       = var.create_event_topics ? aws_sns_topic.event_endpoint_deleted[0].arn : null
}

output "event_delivery_failure_topic_arn" {
  description = "ARN топика delivery failure"
  value       = var.create_event_topics ? aws_sns_topic.event_delivery_failure[0].arn : null
}

output "cost_report" {
  description = "Отчёт по затратам (имитация)"
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
    platform_details  = local.platform_details
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
  description = "Примечание о биллинге"
  value       = local.cost_report_metadata.billing_note
}