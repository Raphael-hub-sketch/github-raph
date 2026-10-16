output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = aws_subnet.database[*].id
}

output "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  value       = aws_subnet.private[*].cidr_block
}

output "database_subnet_cidrs" {
  description = "Database subnet CIDRs"
  value       = aws_subnet.database[*].cidr_block
}

output "public_route_table_id" {
  description = "Public route table ID"
  value       = aws_route_table.public.id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "cost_report" {
  description = "Detailed cost report (imitation)"
  value = {
    metadata           = local.cost_report_metadata
    line_items         = local.cost_line_items
    by_category        = local.cost_by_category
    by_service         = local.cost_by_service
    by_environment     = local.cost_by_environment
    monthly_total_usd  = local.cost_monthly_total
    yearly_total_usd   = local.cost_yearly_total
    monthly_forecast   = local.monthly_forecast
    yearly_projection  = local.yearly_projection
    scenarios          = local.scenario_comparison
    budget             = local.budget_thresholds
    quota_checks       = local.quota_checks
    subnet_type_details = local.subnet_type_details
  }
}

output "cost_summary" {
  description = "Cost summary"
  value = {
    monthly_usd = format("%.2f", local.cost_monthly_total)
    yearly_usd  = format("%.2f", local.cost_yearly_total)
    currency    = local.cost_currency
    breakdown   = local.cost_by_service
  }
}

output "budget_alerts" {
  description = "AWS Budgets thresholds"
  value       = local.budget_thresholds
}

output "billing_note" {
  description = "Billing note"
  value       = local.cost_report_metadata.billing_note
}