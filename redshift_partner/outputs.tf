output "cluster_id" {
  description = "Redshift cluster ID"
  value       = aws_redshift_cluster.main.id
}

output "cluster_identifier" {
  description = "Redshift cluster identifier"
  value       = aws_redshift_cluster.main.cluster_identifier
}

output "cluster_endpoint" {
  description = "Redshift cluster endpoint"
  value       = aws_redshift_cluster.main.endpoint
}

output "partner_id" {
  description = "Redshift partner integration ID"
  value       = aws_redshift_partner.main.id
}

output "partner_status" {
  description = "Partner integration status"
  value       = aws_redshift_partner.main.status
}

output "partner_status_message" {
  description = "Partner integration status message"
  value       = aws_redshift_partner.main.status_message
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
    partner_details     = local.partner_integration_details
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