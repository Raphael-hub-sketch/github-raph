output "profile_id" {
  description = "ID созданного Route53 Profile"
  value       = aws_route53profiles_profile.main.id
}

output "profile_arn" {
  description = "ARN созданного Route53 Profile"
  value       = aws_route53profiles_profile.main.arn
}

output "resource_association_id" {
  description = "ID ассоциации ресурса с профилем"
  value       = aws_route53profiles_resource_association.main.id
}

output "resource_association_status" {
  description = "Статус ассоциации"
  value       = aws_route53profiles_resource_association.main.status
}

output "vpc_id" {
  description = "ID созданного VPC"
  value       = var.create_vpc ? aws_vpc.main[0].id : null
}

output "profile_vpc_association_id" {
  description = "ID ассоциации профиля с VPC"
  value       = var.create_vpc && var.associate_profile_with_vpc ? aws_route53profiles_association.main[0].id : null
}

# ---------------------------------------------------------------------
# ИМИТАЦИЯ ЗАТРАТ: выходные данные для FinOps
# ---------------------------------------------------------------------
output "cost_report" {
  description = "Детализированный отчёт по предполагаемым затратам (имитация)"
  value = {
    metadata              = local.cost_report_metadata
    line_items            = local.cost_line_items
    by_category           = local.cost_by_category
    by_service            = local.cost_by_service
    by_environment        = local.cost_by_environment
    monthly_total_usd     = local.cost_monthly_total
    yearly_total_usd      = local.cost_yearly_total
    monthly_forecast      = local.monthly_forecast
    yearly_projection     = local.yearly_projection
    scenarios             = local.scenario_comparison
    budget                = local.budget_thresholds
    resource_type_details = local.resource_type_details
    quota_checks          = local.quota_checks
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
  description = "Важное примечание о биллинге Route53 Profiles"
  value       = local.cost_report_metadata.billing_note
}