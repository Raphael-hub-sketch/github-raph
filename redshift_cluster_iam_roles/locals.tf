locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }

  redshift_hourly_per_node = 0.25
  redshift_monthly_cluster = var.redshift_node_count * local.redshift_hourly_per_node * var.monthly_hours

  iam_roles_resource_cost = 0.00

  spectrum_cost_per_tb = 5.00
  spectrum_monthly_cost = var.spectrum_scanned_tb * local.spectrum_cost_per_tb

  total_monthly_cost = local.redshift_monthly_cluster + local.iam_roles_resource_cost + local.spectrum_monthly_cost

  cost_breakdown = {
    redshift_cluster = {
      description = "Redshift cluster (${var.redshift_node_count} × ${var.redshift_node_type})"
      unit_price  = "$0.25/node/hour"
      monthly     = local.redshift_monthly_cluster
    }
    iam_roles = {
      description = "aws_redshift_cluster_iam_roles"
      unit_price  = "$0.00 (free)"
      monthly     = local.iam_roles_resource_cost
    }
    spectrum = {
      description = "Redshift Spectrum scans (${var.spectrum_scanned_tb} TB)"
      unit_price  = "$5/TB"
      monthly     = local.spectrum_monthly_cost
    }
  }

  finops_recommendations = [
    "1. aws_redshift_cluster_iam_roles сам по себе бесплатен.",
    "2. Затраты возникают от compute кластера (node-hour) и Spectrum ($5/TB scanned).",
    "3. Максимум 10 IAM roles можно привязать к кластеру одновременно.",
    "4. Не управляйте default_iam_role_arn одновременно через этот ресурс и через aws_redshift_cluster — будет конфликт.",
    "5. Используйте отдельные роли для S3, Spectrum и COPY/UNLOAD с минимальными привилегиями.",
    "6. Spectrum сканирует только необходимые колонки в Parquet/ORC — это снижает стоимость."
  ]
}