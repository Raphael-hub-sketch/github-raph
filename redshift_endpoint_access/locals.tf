locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }

  redshift_hourly_per_node = 0.25
  redshift_monthly_cluster = var.redshift_node_count * local.redshift_hourly_per_node * var.monthly_hours

  endpoint_access_resource_cost = 0.00

  cross_az_data_cost_per_gb = 0.01
  cross_az_monthly_cost = var.monthly_data_processed_gb * local.cross_az_data_cost_per_gb

  total_monthly_cost = local.redshift_monthly_cluster + local.endpoint_access_resource_cost + local.cross_az_monthly_cost

  cost_breakdown = {
    redshift_cluster = {
      description = "Redshift cluster (${var.redshift_node_count} × ${var.redshift_node_type})"
      unit_price  = "$0.25/node/hour"
      monthly     = local.redshift_monthly_cluster
    }
    endpoint_access = {
      description = "aws_redshift_endpoint_access"
      unit_price  = "$0.00 (free)"
      monthly     = local.endpoint_access_resource_cost
    }
    cross_az_transfer = {
      description = "Cross-AZ data transfer (${var.monthly_data_processed_gb} GB)"
      unit_price  = "$0.01/GB"
      monthly     = local.cross_az_monthly_cost
    }
  }

  finops_recommendations = [
    "1. aws_redshift_endpoint_access сам по себе бесплатен.",
    "2. Redshift-managed VPC endpoint не имеет почасовой платы и платы за обработку.",
    "3. Затраты могут возникать от cross-AZ data transfer ($0.01/GB) при обращении к endpoint из другой AZ.",
    "4. Размещайте клиентов в той же AZ, что и endpoint, чтобы избежать cross-AZ charges.",
    "5. Ограничьте vpc_security_group_ids минимально необходимыми правилами.",
    "6. Используйте resource_owner только при cross-account доступе."
  ]
}