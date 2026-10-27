output "redshift_cluster_id" {
  value = aws_redshift_cluster.this.id
}

output "redshift_cluster_arn" {
  value = aws_redshift_cluster.this.arn
}

output "cluster_iam_roles_id" {
  value = aws_redshift_cluster_iam_roles.this.id
}

output "attached_iam_role_arns" {
  value = aws_redshift_cluster_iam_roles.this.iam_role_arns
}

output "default_iam_role_arn" {
  value = aws_redshift_cluster_iam_roles.this.default_iam_role_arn
}

output "s3_role_arn" {
  value = aws_iam_role.redshift_s3.arn
}

output "spectrum_role_arn" {
  value = aws_iam_role.redshift_spectrum.arn
}

output "cost_estimation" {
  value = {
    redshift_cluster = {
      description = "Cluster compute"
      cost        = "$${local.redshift_monthly_cluster}"
    }
    iam_roles = {
      description = "aws_redshift_cluster_iam_roles"
      cost        = "$0.00 (free)"
    }
    spectrum = {
      description = "Spectrum scans (${var.spectrum_scanned_tb} TB)"
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