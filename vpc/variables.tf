variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Allowed values: dev, stage, prod."
  }
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "infra-core"
}

variable "owner" {
  description = "Resource owner"
  type        = string
  default     = "devops-team"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "CC-1042"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_tenancy" {
  description = "Instance tenancy (default or dedicated). Dedicated has $2/hour fee"
  type        = string
  default     = "default"

  validation {
    condition     = contains(["default", "dedicated"], var.instance_tenancy)
    error_message = "Allowed values: default, dedicated."
  }
}

variable "enable_dns_support" {
  description = "Enable DNS support in VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true
}

variable "assign_generated_ipv6_cidr_block" {
  description = "Request AWS-provided IPv6 CIDR block"
  type        = bool
  default     = false
}

variable "create_nat_gateway" {
  description = "Simulate NAT Gateway presence in cost calculation"
  type        = bool
  default     = true
}

variable "nat_gateways_count" {
  description = "Number of NAT Gateways"
  type        = number
  default     = 3
}

variable "nat_data_gb_per_month" {
  description = "Estimated NAT Gateway data processing volume in GB per month"
  type        = number
  default     = 100
}

variable "public_ipv4_addresses_count" {
  description = "Number of public IPv4 addresses associated with the VPC"
  type        = number
  default     = 3
}