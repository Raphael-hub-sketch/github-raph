# variables.tf
# Входные переменные для конфигурации Network ACL

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
  default     = "nacl-demo"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ NETWORK ACL
# ============================================================

variable "nacl_name" {
  description = "Name tag for the Network ACL"
  type        = string
  default     = null
}

variable "ingress_rules" {
  description = "List of ingress rules for the Network ACL"
  type = list(object({
    rule_no    = number
    action     = string
    protocol   = string
    cidr_block = optional(string)
    ipv6_cidr_block = optional(string)
    from_port  = number
    to_port    = number
    icmp_type  = optional(number)
    icmp_code  = optional(number)
  }))
  default = [
    {
      rule_no    = 100
      action     = "allow"
      protocol   = "tcp"
      cidr_block = "0.0.0.0/0"
      from_port  = 80
      to_port    = 80
    },
    {
      rule_no    = 110
      action     = "allow"
      protocol   = "tcp"
      cidr_block = "0.0.0.0/0"
      from_port  = 443
      to_port    = 443
    },
    {
      rule_no    = 120
      action     = "allow"
      protocol   = "tcp"
      cidr_block = "10.0.0.0/16"
      from_port  = 22
      to_port    = 22
    },
    {
      rule_no    = 130
      action     = "allow"
      protocol   = "tcp"
      cidr_block = "10.0.0.0/16"
      from_port  = 1024
      to_port    = 65535
    }
  ]
}

variable "egress_rules" {
  description = "List of egress rules for the Network ACL"
  type = list(object({
    rule_no    = number
    action     = string
    protocol   = string
    cidr_block = optional(string)
    ipv6_cidr_block = optional(string)
    from_port  = number
    to_port    = number
    icmp_type  = optional(number)
    icmp_code  = optional(number)
  }))
  default = [
    {
      rule_no    = 100
      action     = "allow"
      protocol   = "tcp"
      cidr_block = "0.0.0.0/0"
      from_port  = 80
      to_port    = 80
    },
    {
      rule_no    = 110
      action     = "allow"
      protocol   = "tcp"
      cidr_block = "0.0.0.0/0"
      from_port  = 443
      to_port    = 443
    },
    {
      rule_no    = 120
      action     = "allow"
      protocol   = "tcp"
      cidr_block = "10.0.0.0/16"
      from_port  = 1024
      to_port    = 65535
    }
  ]
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ SUBNETS
# ============================================================

variable "public_subnet_count" {
  description = "Number of public subnets to create and associate with NACL"
  type        = number
  default     = 2
}

variable "private_subnet_count" {
  description = "Number of private subnets to create and associate with NACL"
  type        = number
  default     = 2
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ ИМИТАЦИИ ЗАТРАТ
# ============================================================

variable "monthly_data_processed_gb" {
  description = "Assumed volume of data processed through NACL (for indirect cost estimation)"
  type        = number
  default     = 1000
}

variable "cross_az_data_gb" {
  description = "Assumed volume of cross-AZ data transfer in GB"
  type        = number
  default     = 100
}

variable "include_nat_cost" {
  description = "Whether to include NAT Gateway cost in simulation (NACL itself is free)"
  type        = bool
  default     = false
}