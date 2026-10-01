# variables.tf
# Входные переменные для конфигурации Network Interface

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
  default     = "eni-demo"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ NETWORK INTERFACE
# ============================================================

variable "eni_count" {
  description = "Number of ENIs to create"
  type        = number
  default     = 2

  validation {
    condition     = var.eni_count >= 1 && var.eni_count <= 5
    error_message = "ENI count must be between 1 and 5."
  }
}

variable "eni_description" {
  description = "Description for the network interface"
  type        = string
  default     = "Demo network interface managed by Terraform"
}

variable "private_ips" {
  description = "List of private IPs to assign to the ENI (null for auto-assignment)"
  type        = list(string)
  default     = null
}

variable "private_ips_count" {
  description = "Number of private IPs to assign (used if private_ips is null)"
  type        = number
  default     = 1
}

variable "enable_source_dest_check" {
  description = "Whether to enable source/destination checking"
  type        = bool
  default     = true
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ SUBNETS
# ============================================================

variable "subnet_count" {
  description = "Number of subnets to create"
  type        = number
  default     = 2
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ ИМИТАЦИИ ЗАТРАТ
# ============================================================

variable "enable_public_ip" {
  description = "Whether to associate public IP addresses with ENIs (for cost estimation)"
  type        = bool
  default     = false
}

variable "enable_traffic_mirroring" {
  description = "Whether to simulate Traffic Mirroring cost"
  type        = bool
  default     = false
}

variable "traffic_mirroring_sessions" {
  description = "Number of Traffic Mirroring sessions for cost estimation"
  type        = number
  default     = 1
}

variable "enable_network_access_analyzer" {
  description = "Whether to simulate Network Access Analyzer cost"
  type        = bool
  default     = false
}

variable "network_access_analyzer_evaluations" {
  description = "Number of Network Access Analyzer evaluations"
  type        = number
  default     = 5
}

variable "monthly_hours" {
  description = "Number of hours in a month for cost calculation"
  type        = number
  default     = 730
}