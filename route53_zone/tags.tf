locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
      Component   = "dns"
      Service     = "route53"
    },
    {
      # Имитация расширенного набора тегов для FinOps
      BillingCode        = "DNS-${upper(var.environment)}-001"
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
    }
  )
}