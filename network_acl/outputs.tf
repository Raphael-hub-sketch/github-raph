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

# ============================================================
# ИНФОРМАЦИЯ О NETWORK ACL
# ============================================================

output "network_acl_id" {
  description = "The ID of the Network ACL"
  value       = aws_network_acl.this.id
}

output "network_acl_arn" {
  description = "The ARN of the Network ACL"
  value       = aws_network_acl.this.arn
}

output "network_acl_owner_id" {
  description = "The ID of the AWS account that owns the Network ACL"
  value       = aws_network_acl.this.owner_id
}

output "network_acl_tags" {
  description = "Tags of the Network ACL"
  value       = aws_network_acl.this.tags
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

output "associated_subnet_ids" {
  description = "List of subnets associated with the NACL"
  value       = aws_network_acl.this.subnet_ids
}

# ============================================================
# ИМИТАЦИЯ ВЫВОДА ЗАТРАТ (Cost Estimation Output)
# ============================================================

output "cost_estimation" {
  description = "Estimated monthly costs for the Network ACL (indirect only)"
  value = {
    base_resource_cost = {
      description = "aws_network_acl base resource"
      cost        = "$0.00 (NACL is free)"
    }
    nacl_processing = {
      description = "NACL Traffic Processing (${var.monthly_data_processed_gb} GB)"
      cost        = "$0.00 (NACL is free)"
    }
    cross_az = {
      description = "Cross-AZ Data Transfer (${var.cross_az_data_gb} GB)"
      cost        = "$${local.cross_az_cost}"
    }
    nat_gateway = {
      description = "NAT Gateway (optional, ${var.monthly_data_processed_gb} GB)"
      cost        = "$${local.nat_total_cost}"
    }
    total = {
      description = "Estimated Monthly Indirect Total"
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