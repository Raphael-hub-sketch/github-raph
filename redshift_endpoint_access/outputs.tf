output "redshift_cluster_id" {
  value = aws_redshift_cluster.this.id
}

output "redshift_cluster_arn" {
  value = aws_redshift_cluster.this.arn
}

output "endpoint_access_id" {
  value = aws_redshift_endpoint_access.this.id
}

output "endpoint_access_address" {
  value = aws_redshift_endpoint_access.this.address
}

output "endpoint_access_port" {
  value = aws_redshift_endpoint_access.this.port
}

output "endpoint_access_vpc_endpoint" {
  value = aws_redshift_endpoint_access.this.vpc_endpoint
}

output "cost_estimation" {
  value = {
    redshift_cluster = {
      description = "Cluster compute"
      cost        = "$${local.redshift_monthly_cluster}"
    }
    endpoint_access = {
      description = "aws_redshift_endpoint_access"
      cost        = "$0.00 (free)"
    }
    cross_az_transfer = {
      description = "Cross-AZ data transfer (${var.monthly_data_processed_gb} GB)"
      cost        = "$${local.cross_az_monthly_cost}"
    }
    total = {
      description = "Estimated Monthly Total"
      cost        = "$${local.total_monthly_cost}"
    }
  }
}

output "cost_breakdown_table" {
  value = local.cost_breakdown
}

output "finops_recommendations" {
  value = local.finops_recommendations
}