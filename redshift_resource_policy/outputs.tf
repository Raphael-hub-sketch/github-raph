output "cluster_id" {
  description = "Redshift cluster ID"
  value       = aws_redshift_cluster.main.id
}

output "cluster_identifier" {
  description = "Redshift cluster identifier"
  value       = aws_redshift_cluster.main.cluster_identifier
}

output "cluster_namespace_arn" {
  description = "Redshift cluster namespace ARN"
  value       = aws_redshift_cluster.main.cluster_namespace_arn
}

output "cluster_endpoint" {
  description = "Redshift cluster endpoint"
  value       = aws_redshift_cluster.main.endpoint
}

output "resource_policy_id" {
  description = "Resource policy ID"
  value       = aws_redshift_resource_policy.main.id
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
    component_details   = local.redshift_component_details
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