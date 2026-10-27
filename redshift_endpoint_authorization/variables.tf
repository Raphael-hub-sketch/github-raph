variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "redshift-endpoint-auth-demo"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "redshift_node_type" {
  description = "Redshift node type"
  type        = string
  default     = "dc2.large"
}

variable "redshift_node_count" {
  description = "Number of Redshift nodes"
  type        = number
  default     = 2
}

variable "redshift_database_name" {
  description = "Redshift database name"
  type        = string
  default     = "demodb"
}

variable "redshift_master_username" {
  description = "Redshift master username"
  type        = string
  default     = "adminuser"
  sensitive   = true
}

variable "redshift_master_password" {
  description = "Redshift master password"
  type        = string
  default     = "DemoPass123!"
  sensitive   = true
}

variable "grantee_account_id" {
  description = "AWS account ID to grant endpoint access to"
  type        = string
  default     = "123456789012"
}

variable "vpc_ids" {
  description = "List of VPC IDs to grant access to (empty for all VPCs)"
  type        = list(string)
  default     = []
}

variable "force_delete" {
  description = "Force delete endpoint authorization and associated endpoints"
  type        = bool
  default     = false
}

variable "monthly_hours" {
  description = "Hours per month"
  type        = number
  default     = 730
}

variable "monthly_spectrum_scanned_gb" {
  description = "Assumed Spectrum data scanned in GB per month"
  type        = number
  default     = 0
}