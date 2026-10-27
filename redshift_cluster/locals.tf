locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }

  identifier = var.cluster_identifier != null ? var.cluster_identifier : "${var.project_name}-${var.environment}-${random_id.suffix.hex}"

  # dc2.large ~$0.25/hour; ra3.xlplus ~$1.086/hour [citation:6][citation:10]
  node_hourly_rates = {
    "dc2.large"    = 0.25
    "dc2.8xlarge"  = 4.80
    "ra3.xlplus"   = 1.086
    "ra3.4xlarge"  = 3.26
  }

  effective_node_hourly = lookup(local.node_hourly_rates, var.node_type, 0.25)

  effective_node_count = var.cluster_type == "single-node" ? 1 : var.number_of_nodes

  compute_monthly_cost = local.effective_node_count * local.effective_node_hourly * var.monthly_hours

  # RA3 managed storage ~$0.024/GB-month [citation:6][citation:7]
  managed_storage_cost = var.node_type == "ra3.xlplus" || var.node_type == "ra3.4xlarge" ? var.managed_storage_gb * 0.024 : 0

  # Spectrum $5/TB scanned (provisioned clusters) [citation:3][citation:15]
  spectrum_monthly_cost = var.spectrum_scanned_tb * 5.00

  total_monthly_cost = local.compute_monthly_cost + local.managed_storage_cost + local.spectrum_monthly_cost

  cost_breakdown = {
    compute = {
      description = "Cluster compute (${local.effective_node_count} × ${var.node_type})"
      unit_price  = "$${local.effective_node_hourly}/node/hour"
      monthly     = local.compute_monthly_cost
    }
    managed_storage = {
      description = "RA3 managed storage (${var.managed_storage_gb} GB)"
      unit_price  = "$0.024/GB-month"
      monthly     = local.managed_storage_cost
    }
    spectrum = {
      description = "Spectrum scans (${var.spectrum_scanned_tb} TB)"
      unit_price  = "$5/TB"
      monthly     = local.spectrum_monthly_cost
    }
  }

  finops_recommendations = [
    "1. aws_redshift_cluster оплачивается по node-hour; dc2.large ~$0.25/hour, ra3.xlplus ~$1.086/hour.",
    "2. DC2 включает локальный SSD (160 GB для dc2.large), RA3 billed отдельно за managed storage ~$0.024/GB-month.",
    "3. Spectrum на provisioned кластерах: $5/TB scanned; Parquet + column pruning снижает scans в разы.",
    "4. Reserved Nodes дают скидку до ~42% (1 год) и ~76% (3 года) от on-demand.",
    "5. automated_snapshot_retention_period увеличивает backup storage; 7 дней достаточно для большинства сценариев.",
    "6. Для прерывистых нагрузок сравните с Redshift Serverless (RPU-hour) вместо always-on cluster."
  ]
}