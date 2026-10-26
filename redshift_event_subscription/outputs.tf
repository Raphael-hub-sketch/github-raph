output "redshift_cluster_id" {
  value = aws_redshift_cluster.this.id
}

output "redshift_cluster_arn" {
  value = aws_redshift_cluster.this.arn
}

output "event_subscription_id" {
  value = aws_redshift_event_subscription.this.id
}

output "event_subscription_arn" {
  value = aws_redshift_event_subscription.this.arn
}

output "sns_topic_arn" {
  value = aws_sns_topic.redshift_events.arn
}

output "cost_estimation" {
  value = {
    redshift_cluster = {
      description = "Cluster compute (${var.redshift_node_count} × ${var.redshift_node_type})"
      cost        = "$${local.redshift_monthly_cluster}"
    }
    event_subscription = {
      description = "aws_redshift_event_subscription"
      cost        = "$0.00 (free)"
    }
    sns_notifications = {
      description = "SNS notifications (${var.monthly_sns_notifications} messages)"
      cost        = "$${local.sns_monthly_cost}"
    }
    subscription_total = {
      description = "Total event-subscription-related cost (excl. cluster)"
      cost        = "$${local.subscription_monthly_cost}"
    }
  }
}

output "cost_breakdown_table" {
  value = local.cost_breakdown
}

output "finops_recommendations" {
  value = local.finops_recommendations
}