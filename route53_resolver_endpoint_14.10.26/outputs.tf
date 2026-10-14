output "resolver_endpoint_id" {
  description = "ID созданного Resolver Endpoint"
  value       = aws_route53_resolver_endpoint.main.id
}

output "resolver_endpoint_arn" {
  description = "ARN созданного Resolver Endpoint"
  value       = aws_route53_resolver_endpoint.main.arn
}

output "resolver_endpoint_host_vpc_id" {
  description = "ID VPC, в котором создан endpoint"
  value       = aws_route53_resolver_endpoint.main.host_vpc_id
}

output "subnet_ids" {
  description = "ID подсетей, используемых endpoint"
  value       = var.create_vpc ? aws_subnet.resolver[*].id : []
}

output "security_group_id" {
  description = "ID Security Group для endpoint"
  value       = var.create_vpc ? aws_security_group.resolver[0].id : null
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
    protocol_details  = local.protocol_details
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
  description = "Важное примечание о биллинге Route53 Resolver"
  value       = local.cost_report_metadata.billing_note
}