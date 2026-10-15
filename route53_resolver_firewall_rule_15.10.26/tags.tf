locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
      Component   = "dns-firewall-rule"
      Service     = "route53-resolver"
    },
    {
      # Имитация расширенного набора тегов для FinOps
      BillingCode        = "FW-RULE-${upper(var.environment)}-001"
      DataClassification = "internal"
      ComplianceScope    = "none"
      BackupPolicy       = "none"
      PatchGroup         = "n/a"
      MaintenanceWindow  = "sun:03:00-sun:04:00"
      Lifecycle          = "persistent"
      Criticality        = var.environment == "prod" ? "high" : "medium"
      SLA                = var.environment == "prod" ? "99.99" : "99.9"
      AutoShutdown       = "false"
      ReviewDate         = "2025-12-31"
      RuleAction         = var.rule_action
      RulePriority       = tostring(var.rule_priority)
    }
  )
}