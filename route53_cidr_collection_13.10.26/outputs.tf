output "cidr_collection_id" {
  description = "ID созданной CIDR-коллекции"
  value       = aws_route53_cidr_collection.main.id
}

output "cidr_collection_arn" {
  description = "ARN созданной CIDR-коллекции"
  value       = aws_route53_cidr_collection.main.arn
}

output "cidr_collection_name" {
  description = "Имя CIDR-коллекции"
  value       = aws_route53_cidr_collection.main.name
}

output "cidr_collection_version" {
  description = "Версия CIDR-коллекции"
  value       = aws_route53_cidr_collection.main.version
}

output "cidr_location_ids" {
  description = "ID всех созданных CIDR-локаций"
  value       = aws_route53_cidr_location.main[*].id
}

output "cidr_location_names" {
  description = "Имена всех CIDR-локаций"
  value       = aws_route53_cidr_location.main[*].name
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
    location_details  = local.location_details
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
  description = "Важное примечание о биллинге Route53 CIDR Collections"
  value       = local.cost_report_metadata.billing_note
}