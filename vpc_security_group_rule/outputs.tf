output "ingress_rule_ids" {
  description = "Ingress rule IDs"
  value       = aws_security_group_rule.ingress[*].id
}

output "egress_rule_ids" {
  description = "Egress rule IDs"
  value       = aws_security_group_rule.egress[*].id
}

output "ingress_rules_count" {
  description = "Number of ingress rules"
  value       = length(aws_security_group_rule.ingress)
}

output "egress_rules_count" {
  description = "Number of egress rules"
  value       = length(aws_security_group_rule.egress)
}

output "security_group_id" {
  description = "Security group ID"
  value       = var.security_group_id
}

output "cost_report" {
  description = "Detailed cost report (imitation)"
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
    rule_type_details = local.rule_type_details
    protocol_details  = local.protocol_details
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