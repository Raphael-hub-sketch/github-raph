output "redshift_cluster_id" {
  value = aws_redshift_cluster.this.id
}

output "redshift_cluster_arn" {
  value = aws_redshift_cluster.this.arn
}

output "endpoint_authorization_id" {
  value = aws_redshift_endpoint_authorization.this.id
}

output "endpoint_authorization_grantee" {
  value = aws_redshift_endpoint_authorization.this.grantee
}

output "endpoint_authorization_grantor" {
  value = aws_redshift_endpoint_authorization.this.grantor
}

output "endpoint_authorization_allowed_all_vpcs" {
  value = aws_redshift_endpoint_authorization.this.allowed_all_vpcs
}

output "endpoint_authorization_endpoint_count" {
  value = aws_redshift_endpoint_authorization.this.endpoint_count
}

output "cost_estimation" {
  value = {
    redshift_cluster = {
      description = "Cluster compute"
      cost        = "$${local.redshift_monthly_cluster}"
    }
    endpoint_authorization = {
      description = "aws_redshift_endpoint_authorization"
      cost        = "$0.00 (free)"
    }
    spectrum_scans = {
      description = "Spectrum scans (${var.monthly_spectrum_scanned_gb} GB)"
      cost        = "$${local.spectrum_monthly_cost}"
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