output "vpc_id" {
  description = "ID созданного VPC"
  value       = aws_vpc.main.id
}

output "public_route_table_id" {
  description = "ID публичной route table"
  value       = var.create_public_route_table ? aws_route_table.public[0].id : null
}

output "private_route_table_id" {
  description = "ID приватной route table"
  value       = var.create_private_route_table ? aws_route_table.private[0].id : null
}

output "public_subnet_ids" {
  description = "ID публичных подсетей"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "ID приватных подсетей"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_id" {
  description = "ID NAT Gateway (если создан)"
  value       = var.create_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "internet_gateway_id" {
  description = "ID Internet Gateway"
  value       = aws_internet_gateway.main.id
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
    route_type_details = local.route_type_details
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
  description = "Важное примечание о биллинге VPC"
  value       = local.cost_report_metadata.billing_note
}