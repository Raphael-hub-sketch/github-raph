output "cidr_location_id" {
  description = "ID созданной CIDR-локации (deprecated)"
  value       = aws_route53_cidr_location.main.id
}

output "cidr_location_name" {
  description = "Имя CIDR-локации"
  value       = aws_route53_cidr_location.main.name
}

output "cidr_location_blocks" {
  description = "CIDR-блоки локации"
  value       = aws_route53_cidr_location.main.cidr_blocks
}

output "cidr_collection_id" {
  description = "ID CIDR-коллекции"
  value       = local.collection_id
}

output "cidr_collection_name" {
  description = "Имя CIDR-коллекции"
  value       = var.create_collection ? aws_route53_cidr_collection.main[0].name : null
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
    cidr_details        = local.cidr_details
    ip_based_routing_info = local.ip_based_routing_info
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
  description = "Важное примечание о биллинге Route53 CIDR Locations"
  value       = local.cost_report_metadata.billing_note
}