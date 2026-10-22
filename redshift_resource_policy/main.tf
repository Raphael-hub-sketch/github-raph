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

resource "aws_redshift_resource_policy" "main" {
  resource_arn = aws_redshift_cluster.main.cluster_namespace_arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${var.allowed_aws_account_id}:root"
      }
      Action   = "redshift:CreateInboundIntegration"
      Resource = aws_redshift_cluster.main.cluster_namespace_arn
      Sid      = ""
    }]
  })
}

locals {
  redshift_pricing = {
    ra3_xlplus_hourly_usd        = 1.086
    spectrum_per_tb_usd          = 5.00
    rms_storage_per_gb_month_usd = 0.024
    concurrency_scaling_hourly   = 0.00
    hours_per_month              = 730
    hours_per_year               = 8760
  }

  redshift_usage = {
    cluster_nodes_count          = var.number_of_nodes
    hours_running_per_month      = local.redshift_pricing.hours_per_month
    spectrum_data_scanned_tb     = var.spectrum_data_scanned_tb
    storage_gb                   = var.storage_gb
    concurrency_scaling_enabled  = var.enable_concurrency_scaling
    concurrency_scaling_hours    = var.enable_concurrency_scaling ? 100 : 0
    resource_policy_count        = 1
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

    concurrency_scaling = {
      description = "Concurrency Scaling (${local.redshift_usage.concurrency_scaling_hours} hours)"
      quantity    = local.redshift_usage.concurrency_scaling_hours
      unit_price  = local.redshift_pricing.concurrency_scaling_hourly
      monthly_usd = local.redshift_usage.concurrency_scaling_hours * local.redshift_pricing.concurrency_scaling_hourly
      yearly_usd  = local.redshift_usage.concurrency_scaling_hours * local.redshift_pricing.concurrency_scaling_hourly * 12
    }

    resource_policy = {
      description = "Redshift Resource Policy (${local.redshift_usage.resource_policy_count} шт.)"
      quantity    = local.redshift_usage.resource_policy_count
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
      component   = "ConcurrencyScaling"
      description = "Concurrency Scaling hours"
      unit        = "per hour"
      quantity    = local.redshift_usage.concurrency_scaling_hours
      unit_price  = local.redshift_pricing.concurrency_scaling_hourly
      monthly_usd = local.cost_breakdown.concurrency_scaling.monthly_usd
      yearly_usd  = local.cost_breakdown.concurrency_scaling.yearly_usd
      notes       = "Free tier per cluster per day; additional hours billed"
    },
    {
      line_no     = 5
      service     = "Redshift"
      component   = "ResourcePolicy"
      description = "Resource Policy (${local.redshift_usage.resource_policy_count} шт.)"
      unit        = "policy"
      quantity    = local.redshift_usage.resource_policy_count
      unit_price  = 0.00
      monthly_usd = local.cost_breakdown.resource_policy.monthly_usd
      yearly_usd  = local.cost_breakdown.resource_policy.yearly_usd
      notes       = "Resource policies themselves are free"
    }
  ]

  cost_by_category = {
    "Redshift.Compute"            = local.cost_breakdown.compute_nodes.monthly_usd
    "Redshift.Spectrum"           = local.cost_breakdown.spectrum.monthly_usd
    "Redshift.Storage"            = local.cost_breakdown.storage.monthly_usd
    "Redshift.ConcurrencyScaling" = local.cost_breakdown.concurrency_scaling.monthly_usd
    "Redshift.ResourcePolicy"     = local.cost_breakdown.resource_policy.monthly_usd
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
      description       = "Current configuration (${local.redshift_usage.cluster_nodes_count} nodes, Spectrum on)"
      nodes_count       = local.redshift_usage.cluster_nodes_count
      spectrum_tb       = local.redshift_usage.spectrum_data_scanned_tb
      monthly_usd       = local.cost_monthly_total
    }
    "no_spectrum" = {
      description       = "Without Spectrum"
      nodes_count       = local.redshift_usage.cluster_nodes_count
      spectrum_tb       = 0
      monthly_usd       = local.cost_monthly_total - local.cost_breakdown.spectrum.monthly_usd
    }
    "single_node" = {
      description       = "Single node cluster"
      nodes_count       = 1
      spectrum_tb       = local.redshift_usage.spectrum_data_scanned_tb
      monthly_usd       = local.cost_monthly_total - ((local.redshift_usage.cluster_nodes_count - 1) * local.redshift_pricing.ra3_xlplus_hourly_usd * local.redshift_usage.hours_running_per_month)
    }
    "serverless" = {
      description       = "Serverless alternative (RPU-based, estimated)"
      nodes_count       = 0
      spectrum_tb       = local.redshift_usage.spectrum_data_scanned_tb
      monthly_usd       = 0.00
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
    currency       = local.cost_currency
    pricing_source = "https://aws.amazon.com/redshift/pricing/"
    pricing_date   = "2025-01-01"
    report_version = "1.0.0"
    disclaimer     = "Imitation only. Use Infracost / AWS Cost Explorer for accuracy."
    billing_note   = "Resource policies are free; costs come from compute nodes, Spectrum, storage and concurrency scaling"
  }

  quota_checks = {
    max_nodes_per_cluster     = 32
    max_spectrum_tb_per_month = 1000
    current_nodes             = local.redshift_usage.cluster_nodes_count
    current_spectrum_tb       = local.redshift_usage.spectrum_data_scanned_tb
    nodes_ok                  = local.redshift_usage.cluster_nodes_count <= 32
    spectrum_ok               = local.redshift_usage.spectrum_data_scanned_tb <= 1000
  }

  redshift_component_details = {
    "compute" = {
      description = "Provisioned compute nodes"
      billing     = "Per node-hour"
      use_cases   = "Steady workloads with predictable usage"
    }
    "spectrum" = {
      description = "Query S3 data lake without loading"
      billing     = "$5/TB scanned"
      use_cases   = "Ad-hoc analytics on external data"
    }
    "storage" = {
      description = "Redshift Managed Storage"
      billing     = "Per GB-month"
      use_cases   = "All cluster data and snapshots"
    }
    "resource_policy" = {
      description = "Cross-account access policy"
      billing     = "Free"
      use_cases   = "Data sharing and inbound integrations"
    }
  }
}