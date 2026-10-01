# variables.tf
# Входные переменные для конфигурации NAT Gateway

# ============================================================
# ОСНОВНЫЕ ПЕРЕМЕННЫЕ
# ============================================================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment (dev, staging, production)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "nat-gateway-demo"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ NAT GATEWAY
# ============================================================

variable "nat_gateway_count" {
  description = "Number of NAT Gateways to create (1 for cost saving, 2+ for HA)"
  type        = number
  default     = 1

  validation {
    condition     = var.nat_gateway_count >= 1 && var.nat_gateway_count <= 3
    error_message = "NAT Gateway count must be between 1 and 3."
  }
}

variable "connectivity_type" {
  description = "Connectivity type for NAT Gateway (public or private)"
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private"], var.connectivity_type)
    error_message = "Connectivity type must be public or private."
  }
}

variable "nat_gateway_name" {
  description = "Name tag for the NAT Gateway(s)"
  type        = string
  default     = null
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ SUBNETS
# ============================================================

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 2
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 2
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ ИМИТАЦИИ ЗАТРАТ
# ============================================================

variable "monthly_data_processed_gb" {
  description = "Assumed volume of data processed through NAT Gateway in GB per month"
  type        = number
  default     = 1000
}

variable "monthly_hours" {
  description = "Number of hours in a month for cost calculation"
  type        = number
  default     = 730
}

variable "include_public_ipv4_cost" {
  description = "Whether to include public IPv4 address cost ($0.005/hour)"
  type        = bool
  default     = true
}