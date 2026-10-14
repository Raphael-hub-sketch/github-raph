# =====================================================================
# Traffic Policy Document (генерируется через data source)
# =====================================================================
data "aws_route53_traffic_policy_document" "main" {
  record_type = var.record_type
  start_rule  = "failover_rule"

  # Primary endpoint
  endpoint {
    id    = "primary_endpoint"
    type  = "value"
    value = var.primary_endpoint_value
  }

  # Secondary endpoint
  endpoint {
    id    = "secondary_endpoint"
    type  = "value"
    value = var.secondary_endpoint_value
  }

  # Failover rule
  rule {
    id   = "failover_rule"
    type = "failover"

    primary {
      endpoint_reference   = "primary_endpoint"
      evaluate_target_health = true
    }

    secondary {
      endpoint_reference   = "secondary_endpoint"
      evaluate_target_health = true
    }
  }
}