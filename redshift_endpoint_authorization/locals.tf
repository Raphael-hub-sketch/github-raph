locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }

  redshift_hourly_per_node = 0.25
  redshift_monthly_cluster = var.redshift_node_count * local.redshift_hourly_per_node * var.monthly_hours

  endpoint_auth_resource_cost = 0.00

  spectrum_cost_per_tb = 5.00
  spectrum_monthly_cost = (var.monthly_spectrum_scanned_gb / 1024) * local.spectrum_cost_per_tb

  total_monthly_cost = local.redshift_monthly_cluster + local.endpoint_auth_resource_cost + local.spectrum_monthly_cost

  cost_breakdown = {
    redshift_cluster = {
      description = "Redshift cluster (${var.redshift_node_count} × ${var.redshift_node_type})"
      unit_price  = "$0.25/node/hour"
      monthly     = local.redshift_monthly_cluster
    }
    endpoint_authorization = {
      description = "aws_redshift_endpoint_authorization"
      unit_price  = "$0.00 (free)"
      monthly     = local.endpoint_auth_resource_cost
    }
    spectrum_scans = {
      description = "Redshift Spectrum scans (${var.monthly_spectrum_scanned_gb} GB)"
      unit_price  = "$5/TB"
      monthly     = local.spectrum_monthly_cost
    }
  }

  finops_recommendations = [
    "1. aws_redshift_endpoint_authorization сам по себе бесплатен.",
    "2. Затраты возникают от Redshift Spectrum ($5/TB scanned) при использовании provisioned cluster.",
    "3. Ограничьте vpc_ids конкретными VPC вместо разрешения всех VPC в grantee account.",
    "4. Используйте columnar formats (Parquet/ORC) и partition pruning для снижения Spectrum scans.",
    "5. RG instances и Serverless устраняют отдельную оплату Spectrum scans.",
    "6. Мониторите endpoint_count для контроля созданных Redshift-managed VPC endpoints."
  ]
}