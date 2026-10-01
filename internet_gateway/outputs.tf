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
# ИНФОРМАЦИЯ О INTERNET GATEWAY
# ============================================================

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "internet_gateway_arn" {
  description = "The ARN of the Internet Gateway"
  value       = aws_internet_gateway.this.arn
}

output "internet_gateway_owner_id" {
  description = "The ID of the AWS account that owns the Internet Gateway"
  value       = aws_internet_gateway.this.owner_id
}

output "internet_gateway_tags" {
  description = "Tags of the Internet Gateway"
  value       = aws_internet_gateway.this.tags
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
  description = "Estimated monthly costs for the Internet Gateway"
  value = {
    base_resource_cost = {
      description = "aws_internet_gateway base resource"
      cost        = "$0.00"
    }
    egress = {
      description = "Data Egress to Internet (${var.monthly_egress_gb} GB, ${local.free_tier_gb} GB free)"
      cost        = "$${local.monthly_egress_cost}"
    }
    ingress = {
      description = "Data Ingress from Internet (${var.monthly_ingress_gb} GB)"
      cost        = "$${local.monthly_ingress_cost}"
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