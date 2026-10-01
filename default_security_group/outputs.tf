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

output "vpc_default_security_group_id" {
  description = "The ID of the default security group"
  value       = aws_vpc.this.default_security_group_id
}

# ============================================================
# ИНФОРМАЦИЯ О DEFAULT SECURITY GROUP
# ============================================================

output "default_security_group_id" {
  description = "The ID of the managed default security group"
  value       = aws_default_security_group.this.id
}

output "default_security_group_arn" {
  description = "The ARN of the default security group"
  value       = aws_default_security_group.this.arn
}

output "default_security_group_name" {
  description = "The name of the default security group"
  value       = aws_default_security_group.this.name
}

output "default_security_group_vpc_id" {
  description = "The VPC ID of the default security group"
  value       = aws_default_security_group.this.vpc_id
}

output "default_security_group_tags" {
  description = "Tags of the default security group"
  value       = aws_default_security_group.this.tags
}

# ============================================================
# ИНФОРМАЦИЯ О ПРАВИЛАХ
# ============================================================

output "ingress_rules_managed" {
  description = "Whether ingress rules are managed"
  value       = var.manage_ingress_rules
}

output "egress_rules_managed" {
  description = "Whether egress rules are managed"
  value       = var.manage_egress_rules
}

output "ingress_rules" {
  description = "Ingress rules of the default security group"
  value       = aws_default_security_group.this.ingress
}

output "egress_rules" {
  description = "Egress rules of the default security group"
  value       = aws_default_security_group.this.egress
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
  description = "Estimated monthly costs for the default security group"
  value = {
    base_resource_cost = {
      description = "aws_default_security_group base resource"
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