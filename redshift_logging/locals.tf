locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }

  # Redshift cluster cost (dc2.large ~$0.25/hour) [citation:12]
  redshift_hourly_per_node = 0.25
  redshift_monthly_cluster = var.redshift_node_count * local.redshift_hourly_per_node * var.monthly_hours

  # Logging resource itself is free; cost comes from storage destination
  logging_resource_cost = 0.00

  # S3 storage for logs (~$0.023/GB) [citation:2][citation:3]
  s3_log_storage_cost_per_gb = 0.023
  s3_log_storage_cost        = var.log_destination_type == "s3" ? var.monthly_log_storage_gb * local.s3_log_storage_cost_per_gb : 0

  # CloudWatch Logs ingestion (~$0.50/GB) and storage (~$0.03/GB)
  cloudwatch_ingestion_cost = var.log_destination_type == "cloudwatch" ? var.monthly_log_storage_gb * 0.50 : 0
  cloudwatch_storage_cost   = var.log_destination_type == "cloudwatch" ? var.monthly_log_storage_gb * 0.03 : 0
  cloudwatch_total_cost     = local.cloudwatch_ingestion_cost + local.cloudwatch_storage_cost

  # Total logging-related cost (excludes cluster compute)
  logging_monthly_cost = local.logging_resource_cost + local.s3_log_storage_cost + local.cloudwatch_total_cost

  cost_breakdown = {
    redshift_cluster = {
      description = "Redshift cluster (${var.redshift_node_count} × ${var.redshift_node_type})"
      unit_price  = "$0.25/node/hour"
      monthly     = local.redshift_monthly_cluster
    }
    logging_resource = {
      description = "aws_redshift_logging resource"
      unit_price  = "$0.00 (free)"
      monthly     = local.logging_resource_cost
    }
    s3_storage = {
      description = "S3 log storage (${var.monthly_log_storage_gb} GB)"
      unit_price  = "$0.023/GB"
      monthly     = local.s3_log_storage_cost
    }
    cloudwatch_logs = {
      description = "CloudWatch Logs (${var.monthly_log_storage_gb} GB)"
      unit_price  = "$0.50/GB ingestion + $0.03/GB storage"
      monthly     = local.cloudwatch_total_cost
    }
  }

  finops_recommendations = [
    "1. aws_redshift_logging сам по себе бесплатен; затраты возникают только от S3 или CloudWatch [citation:2][citation:3].",
    "2. S3 дешевле CloudWatch для долгосрочного хранения логов ($0.023/GB vs $0.50/GB ingestion) [citation:2].",
    "3. Настройте lifecycle policy в S3 для удаления или архивации старых логов [citation:2].",
    "4. Включайте useractivitylog только при необходимости — он генерирует наибольший объём логов [citation:14].",
    "5. Для S3 требуется политика bucket с principal redshift.amazonaws.com и правами s3:GetBucketAcl, s3:PutObject [citation:2].",
    "6. Используйте CloudWatch только если нужны алерты и real-time анализ [citation:14]."
  ]
}