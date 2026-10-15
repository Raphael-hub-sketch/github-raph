output "s3_bucket_id" {
  description = "ID созданного S3 бакета"
  value       = aws_s3_bucket.main.id
}

output "s3_bucket_arn" {
  description = "ARN созданного S3 бакета"
  value       = aws_s3_bucket.main.arn
}

output "s3_bucket_name" {
  description = "Имя созданного S3 бакета"
  value       = aws_s3_bucket.main.bucket
}

output "s3_bucket_domain_name" {
  description = "Доменное имя S3 бакета"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "versioning_status" {
  description = "Статус versioning"
  value       = var.enable_versioning ? aws_s3_bucket_versioning.main[0].versioning_configuration[0].status : "Disabled"
}

output "encryption_algorithm" {
  description = "Алгоритм шифрования"
  value       = var.enable_encryption ? aws_s3_bucket_server_side_encryption_configuration.main[0].rule[0].apply_server_side_encryption_by_default[0].sse_algorithm : "None"
}

# ---------------------------------------------------------------------
# ИМИТАЦИЯ ЗАТРАТ: выходные данные для FinOps
# ---------------------------------------------------------------------
output "cost_report" {
  description = "Детализированный отчёт по предполагаемым затратам (имитация)"
  value = {
    metadata             = local.cost_report_metadata
    line_items           = local.cost_line_items
    by_category          = local.cost_by_category
    by_service           = local.cost_by_service
    by_environment       = local.cost_by_environment
    monthly_total_usd    = local.cost_monthly_total
    yearly_total_usd     = local.cost_yearly_total
    monthly_forecast     = local.monthly_forecast
    yearly_projection    = local.yearly_projection
    scenarios            = local.scenario_comparison
    budget               = local.budget_thresholds
    quota_checks         = local.quota_checks
    storage_class_details = local.storage_class_details
    volume_by_class      = local.volume_by_class
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
  description = "Важное примечание о биллинге S3"
  value       = local.cost_report_metadata.billing_note
}