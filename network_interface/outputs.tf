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
# ИНФОРМАЦИЯ О NETWORK INTERFACE
# ============================================================

output "network_interface_ids" {
  description = "List of Network Interface IDs"
  value       = aws_network_interface.this[*].id
}

output "network_interface_arns" {
  description = "List of Network Interface ARNs"
  value       = aws_network_interface.this[*].arn
}

output "network_interface_private_ips" {
  description = "List of private IPs of the Network Interfaces"
  value       = aws_network_interface.this[*].private_ips
}

output "network_interface_mac_addresses" {
  description = "List of MAC addresses of the Network Interfaces"
  value       = aws_network_interface.this[*].mac_address
}

output "network_interface_subnet_ids" {
  description = "List of subnet IDs where Network Interfaces are created"
  value       = aws_network_interface.this[*].subnet_id
}

output "network_interface_count" {
  description = "Number of Network Interfaces created"
  value       = var.eni_count
}

# ============================================================
# ИНФОРМАЦИЯ О SUBNETS
# ============================================================

output "subnet_ids" {
  description = "List of subnet IDs"
  value       = aws_subnet.this[*].id
}

# ============================================================
# ИМИТАЦИЯ ВЫВОДА ЗАТРАТ (Cost Estimation Output)
# ============================================================

output "cost_estimation" {
  description = "Estimated monthly costs for the Network Interfaces (indirect only)"
  value = {
    base_resource_cost = {
      description = "aws_network_interface base resource"
      cost        = "$0.00 (ENI is free)"
    }
    public_ipv4 = {
      description = "Public IPv4 Addresses (${var.eni_count} ENIs)"
      cost        = "$${local.monthly_public_ipv4_cost}"
    }
    traffic_mirroring = {
      description = "Traffic Mirroring (${var.traffic_mirroring_sessions} sessions)"
      cost        = "$${local.monthly_traffic_mirroring_cost}"
    }
    network_access_analyzer = {
      description = "Network Access Analyzer (${var.network_access_analyzer_evaluations} evaluations)"
      cost        = "$${local.monthly_network_access_analyzer_cost}"
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