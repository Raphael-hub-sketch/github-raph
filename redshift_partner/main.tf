resource "aws_redshift_cluster" "main" {
  cluster_identifier = var.cluster_identifier
  node_type          = var.node_type
  number_of_nodes    = var.number_of_nodes
  database_name      = var.database_name
  master_username    = var.master_username
  master_password    = var.master_password

  cluster_type = "multi-node"

  publicly_accessible = false
  skip_final_snapshot = true

  tags = merge(local.common_tags, {
    Name = var.cluster_identifier
  })
}

resource "aws_redshift_partner" "main" {
  cluster_identifier = aws_redshift_cluster.main.id
  account_id         = var.partner_account_id
  database_name      = var.partner_database_name
  partner_name       = var.partner_name
}

locals {
  redshift_pricing = {
    ra3_xlplus_hourly_usd        = 1.086
    spectrum_per_tb_usd          = 5.00
    rms_storage_per_gb_month_usd = 0.024
    hours_per_month              = 730
    hours_per_year               = 8760
  }

  redshift_usage = {
    cluster_nodes_count          = var.number_of_nodes
    hours_running_per_month      = local.redshift_pricing.hours_per_month
    spectrum_data_scanned_tb     = var.spectrum_data_scanned_tb
    storage_gb                   = var.storage_gb
    partner_integration_count    = 1
  }

  cost_breakdown = {
    compute_nodes = {
      description = "Redshift compute nodes (${local.redshift_usage.cluster_nodes_count} x ${var.node_type})"
      quantity    = local.redshift_usage.cluster_nodes_count
      unit_price  = local.redshift_pricing.ra3_xlplus_hourly_usd
      monthly_usd = local.redshift_usage.cluster_nodes_count * local.redshift_pricing.ra3_xlplus_hourly_usd * local.redshift_usage.hours_running_per_month
      yearly_usd  = local.redshift_usage.cluster_nodes_count * local.redshift_pricing.ra3_xlplus_hourly_usd * local.redshift_pricing.hours_per_year
    }

    spectrum = {
      description = "Redshift Spectrum (${local.redshift_usage.spectrum_data_scanned_tb} TB scanned)"
      quantity    = local.redshift_usage.spectrum_data_scanned_tb
      unit_price  = local.redshift_pricing.spectrum_per_tb_usd
      monthly_usd = local.redshift_usage.spectrum_data_scanned_tb * local.redshift_pricing.spectrum_per_tb_usd
      yearly_usd  = local.redshift_usage.spectrum_data_scanned_tb * local.redshift_pricing.spectrum_per_tb_usd * 12
    }

    storage = {
      description = "Redshift Managed Storage (${local.redshift_usage.storage_gb} GB)"
      quantity    = local.redshift_usage.storage_gb
      unit_price  = local.redshift_pricing.rms_storage_per_gb_month_usd
      monthly_usd = local.redshift_usage.storage_gb * local.redshift_pricing.rms_storage_per_gb_month_usd
      yearly_usd  = local.redshift_usage.storage_gb * local.redshift_pricing.rms_storage_per_gb_month_usd * 12
    }

    partner_integration = {
      description = "Redshift Partner Integration (${local.redshift_usage.partner_integration_count} шт.)"
      quantity    = local.redshift_usage.partner_integration_count
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
    }
  }

  cost_monthly_total = sum([for k, v in local.cost_breakdown : v.monthly_usd])
  cost_yearly_total  = sum([for k, v in local.cost_breakdown : v.yearly_usd])
  cost_currency      = "USD"

  cost_line_items = [
    {
      line_no     = 1
      service     = "Redshift"
      component   = "ComputeNodes"
      description = "Compute nodes (${var.node_type} x ${local.redshift_usage.cluster_nodes_count})"
      unit        = "node/hour"
      quantity    = local.redshift_usage.cluster_nodes_count
      unit_price  = local.redshift_pricing.ra3_xlplus_hourly_usd
      monthly_usd = local.cost_breakdown.compute_nodes.monthly_usd
      yearly_usd  = local.cost_breakdown.compute_nodes.yearly_usd
      notes       = "Dominant cost line for provisioned clusters"
    },
    {
      line_no     = 2
      service     = "Redshift"
      component   = "Spectrum"
      description = "Spectrum data scanned"
      unit        = "per TB"
      quantity    = local.redshift_usage.spectrum_data_scanned_tb
      unit_price  = local.redshift_pricing.spectrum_per_tb_usd
      monthly_usd = local.cost_breakdown.spectrum.monthly_usd
      yearly_usd  = local.cost_breakdown.spectrum.yearly_usd
      notes       = "Parquet/ORC partitioning reduces scan volume significantly"
    },
    {
      line_no     = 3
      service     = "Redshift"
      component   = "Storage"
      description = "Redshift Managed Storage"
      unit        = "per GB/month"
      quantity    = local.redshift_usage.storage_gb
      unit_price  = local.redshift_pricing.rms_storage_per_gb_month_usd
      monthly_usd = local.cost_breakdown.storage.monthly_usd
      yearly_usd  = local.cost_breakdown.storage.yearly_usd
      notes       = "Billed separately from compute"
    },
    {
      line_no     = 4
      service     = "Redshift"
      component   = "PartnerIntegration"
      description = "Partner Integration (${var.partner_name})"
      unit        = "integration"
      quantity    = local.redshift_usage.partner_integration_count
      unit_price  = 0.00
      monthly_usd = local.cost_breakdown.partner_integration.monthly_usd
      yearly_usd  = local.cost_breakdown.partner_integration.yearly_usd
      notes       = "Partner integrations themselves are free; compute/storage costs apply"
    }
  ]

  cost_by_category = {
    "Redshift.Compute"            = local.cost_breakdown.compute_nodes.monthly_usd
    "Redshift.Spectrum"           = local.cost_breakdown.spectrum.monthly_usd
    "Redshift.Storage"            = local.cost_breakdown.storage.monthly_usd
    "Redshift.PartnerIntegration" = local.cost_breakdown.partner_integration.monthly_usd
  }

  cost_by_service = {
    "Redshift" = local.cost_monthly_total
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
      description       = "Current configuration (${local.redshift_usage.cluster_nodes_count} nodes, partner integration on)"
      nodes_count       = local.redshift_usage.cluster_nodes_count
      partner_enabled   = true
      monthly_usd       = local.cost_monthly_total
    }
    "no_partner" = {
      description       = "Without partner integration"
      nodes_count       = local.redshift_usage.cluster_nodes_count
      partner_enabled   = false
      monthly_usd       = local.cost_monthly_total
    }
    "single_node" = {
      description       = "Single node cluster"
      nodes_count       = 1
      partner_enabled   = true
      monthly_usd       = local.cost_monthly_total - ((local.redshift_usage.cluster_nodes_count - 1) * local.redshift_pricing.ra3_xlplus_hourly_usd * local.redshift_usage.hours_running_per_month)
    }
    "no_spectrum" = {
      description       = "Without Spectrum"
      nodes_count       = local.redshift_usage.cluster_nodes_count
      partner_enabled   = true
      monthly_usd       = local.cost_monthly_total - local.cost_breakdown.spectrum.monthly_usd
    }
  }

  budget_thresholds = {
    monthly_warning  = 2000.00
    monthly_critical = 3000.00
    yearly_max       = 30000.00
    notify_emails    = ["finops@example.com", "devops@example.com"]
    alert_on_breach  = true
  }

  cost_report_metadata = {
    generated_by   = "terraform"
    project        = var.project_name
    environment    = var.environment
    aws_region     = var.aws_region
    cluster_id     = aws_redshift_cluster.main.cluster_identifier
    partner_name   = var.partner_name
    currency       = local.cost_currency
    pricing_source = "https://aws.amazon.com/redshift/pricing/"
    pricing_date   = "2025-01-01"
    report_version = "1.0.0"
    disclaimer     = "Imitation only. Use Infracost / AWS Cost Explorer for accuracy."
    billing_note   = "Partner integrations are free; costs come from compute nodes, Spectrum and storage"
  }

  quota_checks = {
    max_nodes_per_cluster     = 32
    max_spectrum_tb_per_month = 1000
    current_nodes             = local.redshift_usage.cluster_nodes_count
    current_spectrum_tb       = local.redshift_usage.spectrum_data_scanned_tb
    nodes_ok                  = local.redshift_usage.cluster_nodes_count <= 32
    spectrum_ok               = local.redshift_usage.spectrum_data_scanned_tb <= 1000
  }

  partner_integration_details = {
    "status" = {
      description = "Partner integration status"
      billing     = "Free"
      use_cases   = "Monitoring data ingestion from partner"
    }
    "account_id" = {
      description = "AWS account ID that owns the cluster"
      billing     = "n/a"
      use_cases   = "Authorization scope for partner"
    }
    "database_name" = {
      description = "Target database for partner data"
      billing     = "n/a"
      use_cases   = "Isolation of partner data"
    }
  }
}