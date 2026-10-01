# variables.tf
# Входные переменные для конфигурации Default Security Group

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
  default     = "default-sg-demo"
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
  description = "List of ingress rules for the default security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = optional(list(string))
    self        = optional(bool)
    description = optional(string)
  }))
  default = [
    {
      from_port = 0
      to_port   = 0
      protocol  = "-1"
      self      = true
    }
  ]
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ EGRESS ПРАВИЛ
# ============================================================

variable "egress_rules" {
  description = "List of egress rules for the default security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = optional(list(string))
    self        = optional(bool)
    description = optional(string)
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ УПРАВЛЕНИЯ ПРАВИЛАМИ
# ============================================================

variable "manage_ingress_rules" {
  description = "Whether to manage ingress rules (if false, existing rules are preserved)"
  type        = bool
  default     = true
}

variable "manage_egress_rules" {
  description = "Whether to manage egress rules (if false, existing rules are preserved)"
  type        = bool
  default     = true
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ ИМИТАЦИИ ЗАТРАТ
# ============================================================

variable "monthly_data_processed_gb" {
  description = "Assumed volume of data processed through the security group in GB"
  type        = number
  default     = 1000
}

variable "monthly_rule_evaluations" {
  description = "Assumed number of rule evaluations per month"
  type        = number
  default     = 50000000
}