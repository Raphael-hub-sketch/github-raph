# variables.tf
# Входные переменные для конфигурации Default Network ACL

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
  default     = "default-nacl-demo"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ INGRESS ПРАВИЛ
# ============================================================

variable "ingress_rules" {
  description = "List of ingress rules for the default network ACL"
  type = list(object({
    rule_no    = number
    action     = string
    protocol   = string
    cidr_block = string
    from_port  = number
    to_port    = number
  }))
  default = [
    {
      rule_no    = 100
      action     = "allow"
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
      from_port  = 0
      to_port    = 0
    }
  ]
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ EGRESS ПРАВИЛ
# ============================================================

variable "egress_rules" {
  description = "List of egress rules for the default network ACL"
  type = list(object({
    rule_no    = number
    action     = string
    protocol   = string
    cidr_block = string
    from_port  = number
    to_port    = number
  }))
  default = [
    {
      rule_no    = 100
      action     = "allow"
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
      from_port  = 0
      to_port    = 0
    }
  ]
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ УПРАВЛЕНИЯ SUBNETS
# ============================================================

variable "manage_subnet_associations" {
  description = "Whether to manage subnet associations"
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "List of subnet IDs to associate with the default network ACL"
  type        = list(string)
  default     = []
}

variable "ignore_subnet_changes" {
  description = "Whether to ignore changes to subnet_ids (recommended)"
  type        = bool
  default     = true
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ ИМИТАЦИИ ЗАТРАТ
# ============================================================

variable "monthly_data_processed_gb" {
  description = "Assumed volume of data processed through the ACL in GB"
  type        = number
  default     = 1000
}

variable "monthly_rule_evaluations" {
  description = "Assumed number of rule evaluations per month"
  type        = number
  default     = 10000000
}