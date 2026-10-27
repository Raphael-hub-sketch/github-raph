output "redshift_cluster_id" {
  value = aws_redshift_cluster.this.id
}

output "redshift_cluster_endpoint" {
  value = aws_redshift_cluster.this.endpoint
}

output "redshift_cluster_arn" {
  value = aws_redshift_cluster.this.arn
}

output "redshift_simulated_cost_tags" {
  value = {
    CostCenter              = local.redshift_tags.CostCenter
    SimulatedMonthlyCostUSD = "2400"
    SimulatedHourlyRateUSD  = "3.33"
    NodeType                = var.node_type
    NodeCount               = var.number_of_nodes
  }
}

output "redshift_logs_bucket" {
  value = aws_s3_bucket.redshift_logs.bucket
}