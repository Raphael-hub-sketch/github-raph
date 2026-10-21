output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "VPC ARN"
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "vpc_instance_tenancy" {
  description = "VPC instance tenancy"
  value       = aws_vpc.main.instance_tenancy
}

output "vpc_enable_dns_support" {
  description = "VPC DNS support enabled"
  value       = aws_vpc.main.enable_dns_support
}

output "vpc_enable_dns_hostnames" {
  description = "VPC DNS hostnames enabled"
  value       = aws_vpc.main.enable_dns_hostnames
}

output "vpc_default_security_group_id" {
  description = "Default security group ID"
  value       = aws_vpc.main.default_security_group_id
}

output "vpc_default_route_table_id" {
  description = "Default route table ID"
  value       = aws_vpc.main.default_route_table_id
}

output "vpc_main_route_table_id" {
  description = "Main route table ID"
  value       = aws_vpc.main.main_route_table_id
}

output "cost_report" {
  description = "Detailed cost report (imitation)"
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
    vpc_feature_details = local.vpc_feature_details
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