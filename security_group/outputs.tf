output "app_sg_id" {
  description = "ID Application Security Group"
  value       = aws_security_group.app.id
}

output "app_sg_arn" {
  description = "ARN Application Security Group"
  value       = aws_security_group.app.arn
}

output "alb_sg_id" {
  description = "ID ALB Security Group"
  value       = var.create_alb_sg ? aws_security_group.alb[0].id : null
}

output "db_sg_id" {
  description = "ID Database Security Group"
  value       = var.create_db_sg ? aws_security_group.db[0].id : null
}

output "vpc_id" {
  description = "ID созданного VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "ID публичных подсетей"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "ID приватных подсетей"
  value       = aws_subnet.private[*].id
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
    sg_type_details   = local.sg_type_details
    best_practices    = local.best_practices
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
  description = "Важное примечание о биллинге Security Groups"
  value       = local.cost_report_metadata.billing_note
}