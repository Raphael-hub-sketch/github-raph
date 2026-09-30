# outputs.tf
# Выходные значения, включая имитацию отчёта о затратах

# ============================================================
# ИНФОРМАЦИЯ О VPC
# ============================================================

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "vpc_default_network_acl_id" {
  description = "The ID of the default network ACL"
  value       = aws_vpc.this.default_network_acl_id
}

# ============================================================
# ИНФОРМАЦИЯ О DEFAULT NETWORK ACL
# ============================================================

output "default_network_acl_id" {
  description = "The ID of the managed default network ACL"
  value       = aws_default_network_acl.this.id
}

output "default_network_acl_arn" {
  description = "The ARN of the default network ACL"
  value       = aws_default_network_acl.this.arn
}

output "default_network_acl_tags" {
  description = "Tags of the default network ACL"
  value       = aws_default_network_acl.this.tags
}

# ============================================================
# ИНФОРМАЦИЯ О SUBNETS
# ============================================================

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "all_subnet_ids" {
  description = "List of all subnet IDs"
  value       = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
}

# ============================================================
# ИМИТАЦИЯ ВЫВОДА ЗАТРАТ (Cost Estimation Output)
# ============================================================

output "cost_estimation" {
  description = "Estimated monthly costs for the default network ACL"
  value = {
    base_resource_cost = {
      description = "aws_default_network_acl base resource"
      cost        = "$0.00"
    }
    data_processing = {
      description = "Data Processing (${var.monthly_data_processed_gb} GB)"
      cost        = "$${local.data_processing_cost}"
    }
    rule_evaluation = {
      description = "Rule Evaluations (${var.monthly_rule_evaluations} evaluations)"
      cost        = "$${local.rule_evaluation_cost}"
    }
    total = {
      description = "Estimated Monthly Total"
      cost        = "$${local.estimated_monthly_cost}"
    }
  }
}

output "cost_breakdown_table" {
  description = "Detailed cost breakdown table"
  value       = local.cost_breakdown
}

# ============================================================
# РЕКОМЕНДАЦИИ ПО ОПТИМИЗАЦИИ (FinOps Recommendations)
# ============================================================

output "finops_recommendations" {
  description = "Cost optimization recommendations"
  value       = local.finops_recommendations
}

# ============================================================
# ИНФОРМАЦИЯ ОБ АККАУНТЕ
# ============================================================

output "account_info" {
  description = "AWS account information"
  value = {
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
    user_arn   = data.aws_caller_identity.current.arn
  }
}