# variables.tf
# Входные переменные для конфигурации Internet Gateway

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
  default     = "igw-demo"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ INTERNET GATEWAY
# ============================================================

variable "igw_name" {
  description = "Name tag for the Internet Gateway"
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

  validation {
    condition     = var.public_subnet_count >= 1 && var.public_subnet_count <= 3
    error_message = "Public subnet count must be between 1 and 3."
  }
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 2

  validation {
    condition     = var.private_subnet_count >= 1 && var.private_subnet_count <= 3
    error_message = "Private subnet count must be between 1 and 3."
  }
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ ИМИТАЦИИ ЗАТРАТ
# ============================================================

variable "monthly_egress_gb" {
  description = "Assumed volume of data egressed to internet in GB per month"
  type        = number
  default     = 1000
}

variable "monthly_ingress_gb" {
  description = "Assumed volume of data ingress from internet in GB per month"
  type        = number
  default     = 500
}

variable "include_free_tier" {
  description = "Whether to include AWS Free Tier (100 GB free egress)"
  type        = bool
  default     = true
}