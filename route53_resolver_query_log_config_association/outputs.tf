output "query_log_config_association_id" {
  description = "ID ассоциации query log config с VPC"
  value       = var.create_vpc ? aws_route53_resolver_query_log_config_association.main[0].id : null
}

output "query_log_config_id" {
  description = "ID конфигурации логирования DNS-запросов"
  value       = aws_route53_resolver_query_log_config.main.id
}

output "query_log_config_arn" {
  description = "ARN конфигурации логирования DNS-запросов"
  value       = aws_route53_resolver_query_log_config.main.arn
}

output "vpc_id" {
  description = "ID ассоциированного VPC"
  value       = var.create_vpc ? aws_vpc.main[0].id : null
}

output "cloudwatch_log_group_name" {
  description = "Имя CloudWatch Log Group (если используется)"
  value       = var.log_destination_type == "cloudwatch" ? aws_cloudwatch_log_group.query_logs[0].name : null
}

output "s3_bucket_name" {
  description = "Имя S3 Bucket (если используется)"
  value       = var.log_destination_type == "s3" ? aws_s3_bucket.query_logs[0].bucket : null
}

# ---------------------------------------------------------------------
# ИМИТАЦИЯ ЗАТРАТ: выходные данные для FinOps
# ---------------------------------------------------------------------
output "cost_report" {
  description = "Детализированный отчёт по предполагаемым затратам (имитация)"
  value = {
    metadata            = local.cost_report_metadata
    line_items          = local.cost_line_items
    by_category         = local.cost_by_category
    by_service          = local.cost_by_service
    by_environment      = local.cost_by_environment
    monthly_total_usd   = local.cost_monthly_total
    yearly_total_usd    = local.cost_yearly_total
    monthly_forecast    = local.monthly_forecast
    yearly_projection   = local.yearly_projection
    scenarios           = local.scenario_comparison
    budget              = local.budget_thresholds
    quota_checks        = local.quota_checks
    destination_details = local.destination_details
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
  description = "Важное примечание о биллинге Route53 Resolver Query Logging"
  value       = local.cost_report_metadata.billing_note
}