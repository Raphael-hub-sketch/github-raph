output "sqs_queue_id" {
  description = "ID созданной SQS очереди"
  value       = aws_sqs_queue.main.id
}

output "sqs_queue_arn" {
  description = "ARN созданной SQS очереди"
  value       = aws_sqs_queue.main.arn
}

output "sqs_queue_url" {
  description = "URL созданной SQS очереди"
  value       = aws_sqs_queue.main.url
}

output "sqs_queue_name" {
  description = "Имя SQS очереди"
  value       = aws_sqs_queue.main.name
}

output "dlq_arn" {
  description = "ARN Dead Letter Queue (если создана)"
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].arn : null
}

output "dlq_url" {
  description = "URL Dead Letter Queue (если создана)"
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].url : null
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
    queue_type_details = local.queue_type_details
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
  description = "Важное примечание о биллинге SQS"
  value       = local.cost_report_metadata.billing_note
}