locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }

  # Redshift cluster compute (dc2.large ~$0.25/hour) 
  redshift_hourly_per_node = 0.25
  redshift_monthly_cluster = var.redshift_node_count * local.redshift_hourly_per_node * var.monthly_hours

  # Event subscription resource itself is free [citation:11]
  subscription_resource_cost = 0.00

  # Billing is through SNS [citation:2][citation:10]
  # SNS email/HTTP notifications: first 1,000 free, then $0.50 per 1M (approx)
  sns_free_tier = 1000
  sns_billable = max(0, var.monthly_sns_notifications - local.sns_free_tier)
  sns_cost_per_million = 0.50
  sns_monthly_cost = (local.sns_billable / 1000000) * local.sns_cost_per_million

  # Total event-subscription-related cost (excl. cluster)
  subscription_monthly_cost = local.subscription_resource_cost + local.sns_monthly_cost

  cost_breakdown = {
    redshift_cluster = {
      description = "Redshift cluster (${var.redshift_node_count} × ${var.redshift_node_type})"
      unit_price  = "$0.25/node/hour"
      monthly     = local.redshift_monthly_cluster
    }
    event_subscription = {
      description = "aws_redshift_event_subscription"
      unit_price  = "$0.00 (free)"
      monthly     = local.subscription_resource_cost
    }
    sns_notifications = {
      description = "SNS notifications (${var.monthly_sns_notifications} messages)"
      unit_price  = "First 1,000 free, then $0.50/1M"
      monthly     = local.sns_monthly_cost
    }
  }

  finops_recommendations = [
    "1. aws_redshift_event_subscription сам по себе бесплатен; оплата идёт через SNS [citation:2][citation:10].",
    "2. SNS email/HTTP уведомления: первые 1,000 бесплатно, далее ~$0.50 за 1M сообщений.",
    "3. Ограничьте event_categories только необходимыми (например, monitoring, security) для снижения объёма уведомлений.",
    "4. severity = ERROR сокращает количество уведомлений по сравнению с INFO.",
    "5. Не включайте subscription для всех sources, если нужен мониторинг только конкретного кластера.",
    "6. SNS SMS дороже email/HTTP — используйте email или HTTP endpoint для алертов."
  ]
}