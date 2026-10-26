output "redshift_cluster_id" {
  value = aws_redshift_cluster.this.id
}

output "redshift_cluster_arn" {
  value = aws_redshift_cluster.this.arn
}

output "redshift_logging_id" {
  value = aws_redshift_logging.this.id
}

output "log_destination_type" {
  value = var.log_destination_type
}

output "s3_bucket_name" {
  value = var.log_destination_type == "s3" ? aws_s3_bucket.logs[0].id : null
}

output "cost_estimation" {
  value = {
    redshift_cluster = {
      description = "Cluster compute (${var.redshift_node_count} × ${var.redshift_node_type})"
      cost        = "$${local.redshift_monthly_cluster}"
    }
    logging_resource = {
      description = "aws_redshift_logging"
      cost        = "$0.00 (free)"
    }
    s3_storage = {
      description = "S3 log storage (${var.monthly_log_storage_gb} GB)"
      cost        = "$${local.s3_log_storage_cost}"
    }
    cloudwatch_logs = {
      description = "CloudWatch Logs (${var.monthly_log_storage_gb} GB)"
      cost        = "$${local.cloudwatch_total_cost}"
    }
    logging_total = {
      description = "Total logging-related cost (excl. cluster)"
      cost        = "$${local.logging_monthly_cost}"
    }
  }
}

output "cost_breakdown_table" {
  value = local.cost_breakdown
}

output "finops_recommendations" {
  value = local.finops_recommendations
}