output "cluster_id" {
  value = aws_redshift_cluster.this.id
}

output "cluster_arn" {
  value = aws_redshift_cluster.this.arn
}

output "cluster_identifier" {
  value = aws_redshift_cluster.this.cluster_identifier
}

output "cluster_endpoint" {
  value = aws_redshift_cluster.this.endpoint
}

output "cluster_port" {
  value = aws_redshift_cluster.this.port
}

output "cluster_node_type" {
  value = aws_redshift_cluster.this.node_type
}

output "cluster_number_of_nodes" {
  value = aws_redshift_cluster.this.number_of_nodes
}

output "cost_estimation" {
  value = {
    compute = {
      description = "Compute (${local.effective_node_count} × ${var.node_type})"
      cost        = "$${local.compute_monthly_cost}"
    }
    managed_storage = {
      description = "RA3 managed storage (${var.managed_storage_gb} GB)"
      cost        = "$${local.managed_storage_cost}"
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