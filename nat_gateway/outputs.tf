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
# ИНФОРМАЦИЯ О NAT GATEWAY
# ============================================================

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "List of public IPs of the NAT Gateways"
  value       = aws_nat_gateway.this[*].public_ip
}

output "nat_gateway_network_interface_ids" {
  description = "List of network interface IDs of the NAT Gateways"
  value       = aws_nat_gateway.this[*].network_interface_id
}

output "nat_gateway_association_ids" {
  description = "List of association IDs of the NAT Gateways"
  value       = aws_nat_gateway.this[*].association_id
}

output "nat_gateway_count" {
  description = "Number of NAT Gateways created"
  value       = var.nat_gateway_count
}

output "connectivity_type" {
  description = "Connectivity type of NAT Gateways"
  value       = var.connectivity_type
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
  description = "Estimated monthly costs for the NAT Gateway(s)"
  value = {
    hourly_charge = {
      description = "NAT Gateway Hourly (${var.nat_gateway_count} × ${var.monthly_hours}h)"
      cost        = "$${local.monthly_hourly_cost}"
    }
    data_processing = {
      description = "Data Processing (${var.monthly_data_processed_gb} GB)"
      cost        = "$${local.monthly_data_cost}"
    }
    public_ipv4 = {
      description = "Public IPv4 Addresses (${var.nat_gateway_count} addresses)"
      cost        = "$${local.monthly_ipv4_cost}"
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

output "cost_scenarios" {
  description = "Cost comparison scenarios (single vs multi-AZ)"
  value       = local.cost_scenarios
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