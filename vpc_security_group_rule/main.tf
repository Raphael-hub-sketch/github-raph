resource "aws_security_group_rule" "ingress" {
  count = length(var.ingress_rules)

  type              = "ingress"
  security_group_id = var.security_group_id
  from_port         = var.ingress_rules[count.index].from_port
  to_port           = var.ingress_rules[count.index].to_port
  protocol          = var.ingress_rules[count.index].protocol
  cidr_blocks       = var.ingress_rules[count.index].cidr_blocks
  description       = var.ingress_rules[count.index].description
}

resource "aws_security_group_rule" "egress" {
  count = length(var.egress_rules)

  type              = "egress"
  security_group_id = var.security_group_id
  from_port         = var.egress_rules[count.index].from_port
  to_port           = var.egress_rules[count.index].to_port
  protocol          = var.egress_rules[count.index].protocol
  cidr_blocks       = var.egress_rules[count.index].cidr_blocks
  description       = var.egress_rules[count.index].description
}

locals {
  sgr_pricing = {
    rule_hourly_usd              = 0.00
    flow_logs_per_gb_usd         = 0.50
    flow_logs_storage_per_gb_usd = 0.03
    hours_per_month              = 730
    hours_per_year               = 8760
  }

  sgr_usage = {
    ingress_rules_count          = length(var.ingress_rules)
    egress_rules_count           = length(var.egress_rules)
    total_rules_count            = length(var.ingress_rules) + length(var.egress_rules)
    flow_logs_enabled            = var.enable_flow_logs_simulation
    flow_logs_data_gb_per_month  = var.enable_flow_logs_simulation ? var.flow_logs_data_gb_per_month : 0
  }

  cost_breakdown = {
    rules = {
      description = "Security Group Rules (${local.sgr_usage.total_rules_count} шт.)"
      quantity    = local.sgr_usage.total_rules_count
      unit_price  = local.sgr_pricing.rule_hourly_usd
      monthly_usd = local.sgr_usage.total_rules_count * local.sgr_pricing.rule_hourly_usd * local.sgr_pricing.hours_per_month
      yearly_usd  = local.sgr_usage.total_rules_count * local.sgr_pricing.rule_hourly_usd * local.sgr_pricing.hours_per_year
    }

    flow_logs_ingestion = {
      description = "VPC Flow Logs ingestion (${local.sgr_usage.flow_logs_data_gb_per_month} GB/мес)"
      quantity    = local.sgr_usage.flow_logs_data_gb_per_month
      unit_price  = local.sgr_pricing.flow_logs_per_gb_usd
      monthly_usd = local.sgr_usage.flow_logs_data_gb_per_month * local.sgr_pricing.flow_logs_per_gb_usd
      yearly_usd  = local.sgr_usage.flow_logs_data_gb_per_month * local.sgr_pricing.flow_logs_per_gb_usd * 12
    }

    flow_logs_storage = {
      description = "VPC Flow Logs storage"
      quantity    = local.sgr_usage.flow_logs_data_gb_per_month
      unit_price  = local.sgr_pricing.flow_logs_storage_per_gb_usd
      monthly_usd = local.sgr_usage.flow_logs_data_gb_per_month * local.sgr_pricing.flow_logs_storage_per_gb_usd
      yearly_usd  = local.sgr_usage.flow_logs_data_gb_per_month * local.sgr_pricing.flow_logs_storage_per_gb_usd * 12
    }
  }

  cost_monthly_total = sum([for k, v in local.cost_breakdown : v.monthly_usd])
  cost_yearly_total  = sum([for k, v in local.cost_breakdown : v.yearly_usd])
  cost_currency      = "USD"

  cost_line_items = [
    {
      line_no     = 1
      service     = "VPC"
      component   = "SecurityGroupRule"
      description = "Security Group Rules (${local.sgr_usage.total_rules_count} шт.)"
      unit        = "rule"
      quantity    = local.sgr_usage.total_rules_count
      unit_price  = local.sgr_pricing.rule_hourly_usd
      monthly_usd = local.cost_breakdown.rules.monthly_usd
      yearly_usd  = local.cost_breakdown.rules.yearly_usd
      notes       = "Security group rules are free of charge [citation:2][citation:12]"
    },
    {
      line_no     = 2
      service     = "CloudWatch"
      component   = "FlowLogs.Ingestion"
      description = "VPC Flow Logs ingestion"
      unit        = "per GB"
      quantity    = local.sgr_usage.flow_logs_data_gb_per_month
      unit_price  = local.sgr_pricing.flow_logs_per_gb_usd
      monthly_usd = local.cost_breakdown.flow_logs_ingestion.monthly_usd
      yearly_usd  = local.cost_breakdown.flow_logs_ingestion.yearly_usd
      notes       = "Vended Logs pricing applies [citation:3][citation:13]"
    },
    {
      line_no     = 3
      service     = "CloudWatch"
      component   = "FlowLogs.Storage"
      description = "VPC Flow Logs storage"
      unit        = "per GB/month"
      quantity    = local.sgr_usage.flow_logs_data_gb_per_month
      unit_price  = local.sgr_pricing.flow_logs_storage_per_gb_usd
      monthly_usd = local.cost_breakdown.flow_logs_storage.monthly_usd
      yearly_usd  = local.cost_breakdown.flow_logs_storage.yearly_usd
      notes       = "Storage cost for log retention"
    }
  ]

  cost_by_category = {
    "VPC.SecurityGroupRule" = local.cost_breakdown.rules.monthly_usd
    "CloudWatch.FlowLogs"   = local.cost_breakdown.flow_logs_ingestion.monthly_usd + local.cost_breakdown.flow_logs_storage.monthly_usd
  }

  cost_by_service = {
    "VPC"        = local.cost_breakdown.rules.monthly_usd
    "CloudWatch" = local.cost_breakdown.flow_logs_ingestion.monthly_usd + local.cost_breakdown.flow_logs_storage.monthly_usd
  }

  cost_by_environment = {
    "${var.environment}" = local.cost_monthly_total
  }

  monthly_forecast = [
    for m in range(1, 13) : {
      month         = m
      month_name    = element([
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
      ], m - 1)
      base_usd      = local.cost_monthly_total
      growth_rate   = 0.02
      projected_usd = local.cost_monthly_total * pow(1.02, m - 1)
    }
  ]

  yearly_projection = {
    total_usd       = sum([for m in local.monthly_forecast : m.projected_usd])
    average_monthly = sum([for m in local.monthly_forecast : m.projected_usd]) / 12
    peak_month      = max([for m in local.monthly_forecast : m.projected_usd]...)
    lowest_month    = min([for m in local.monthly_forecast : m.projected_usd]...)
  }

  scenario_comparison = {
    "current" = {
      description   = "Current configuration (${local.sgr_usage.total_rules_count} rules, Flow Logs on)"
      rules_count   = local.sgr_usage.total_rules_count
      flow_logs     = local.sgr_usage.flow_logs_enabled
      monthly_usd   = local.cost_monthly_total
    }
    "no_flow_logs" = {
      description   = "Security Group Rules without Flow Logs"
      rules_count   = local.sgr_usage.total_rules_count
      flow_logs     = false
      monthly_usd   = local.cost_monthly_total - local.cost_breakdown.flow_logs_ingestion.monthly_usd - local.cost_breakdown.flow_logs_storage.monthly_usd
    }
    "high_traffic" = {
      description   = "High traffic (500 GB Flow Logs)"
      rules_count   = local.sgr_usage.total_rules_count
      flow_logs     = true
      monthly_usd   = local.cost_monthly_total + (500 - local.sgr_usage.flow_logs_data_gb_per_month) * local.sgr_pricing.flow_logs_per_gb_usd
    }
    "minimal_rules" = {
      description   = "Minimal rules (2 rules, no Flow Logs)"
      rules_count   = 2
      flow_logs     = false
      monthly_usd   = 0.00
    }
    "max_rules" = {
      description   = "Max rules (60 ingress + 60 egress, no Flow Logs)"
      rules_count   = 120
      flow_logs     = false
      monthly_usd   = 0.00
    }
  }

  budget_thresholds = {
    monthly_warning  = 50.00
    monthly_critical = 100.00
    yearly_max       = 1000.00
    notify_emails    = ["finops@example.com", "devops@example.com"]
    alert_on_breach  = true
  }

  cost_report_metadata = {
    generated_by   = "terraform"
    project        = var.project_name
    environment    = var.environment
    aws_region     = var.aws_region
    vpc_id         = var.vpc_id
    security_group_id = var.security_group_id
    currency       = local.cost_currency
    pricing_source = "https://aws.amazon.com/vpc/pricing/"
    pricing_date   = "2025-01-01"
    report_version = "1.0.0"
    disclaimer     = "Imitation only. Use Infracost / AWS Cost Explorer for accuracy."
    billing_note   = "Security group rules are free; costs come from VPC Flow Logs [citation:2][citation:12]"
  }

  quota_checks = {
    max_ingress_rules_per_sg = 60
    max_egress_rules_per_sg  = 60
    max_rules_per_eni        = 1000
    current_ingress          = local.sgr_usage.ingress_rules_count
    current_egress           = local.sgr_usage.egress_rules_count
    ingress_ok               = local.sgr_usage.ingress_rules_count <= 60
    egress_ok                = local.sgr_usage.egress_rules_count <= 60
  }

  rule_type_details = {
    "ingress" = {
      description = "Inbound traffic to resources"
      direction   = "inbound"
      default_limit = 60
      use_cases   = "Web access, SSH, DB access"
    }
    "egress" = {
      description = "Outbound traffic from resources"
      direction   = "outbound"
      default_limit = 60
      use_cases   = "Internet access, API calls, package downloads"
    }
  }

  protocol_details = {
    "tcp" = {
      description = "Transmission Control Protocol"
      common_ports = "22 (SSH), 80 (HTTP), 443 (HTTPS), 3306 (MySQL), 5432 (PostgreSQL)"
    }
    "udp" = {
      description = "User Datagram Protocol"
      common_ports = "53 (DNS), 123 (NTP), 161 (SNMP)"
    }
    "-1" = {
      description = "All protocols"
      common_ports = "All ports (from_port=0, to_port=0)"
    }
    "icmp" = {
      description = "Internet Control Message Protocol"
      common_ports = "Type 8 (Echo Request), Type 0 (Echo Reply)"
    }
  }
}