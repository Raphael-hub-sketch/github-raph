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

variable "cluster_identifier" {
  description = "Redshift cluster identifier"
  type        = string
  default     = "analytics-cluster"
}

variable "node_type" {
  description = "Redshift node type"
  type        = string
  default     = "ra3.xlplus"
}

variable "number_of_nodes" {
  description = "Number of compute nodes"
  type        = number
  default     = 2
}

variable "database_name" {
  description = "Redshift database name"
  type        = string
  default     = "analytics"
}

variable "master_username" {
  description = "Redshift master username"
  type        = string
  default     = "adminuser"
}

variable "master_password" {
  description = "Redshift master password"
  type        = string
  sensitive   = true
  default     = "TempPassword123!"
}

variable "allowed_aws_account_id" {
  description = "AWS account ID allowed for inbound integration"
  type        = string
  default     = "123456789012"
}

variable "enable_concurrency_scaling" {
  description = "Simulate concurrency scaling usage"
  type        = bool
  default     = false
}

variable "spectrum_data_scanned_tb" {
  description = "Estimated Spectrum data scanned per month (TB)"
  type        = number
  default     = 1
}

variable "storage_gb" {
  description = "Estimated Redshift Managed Storage (GB)"
  type        = number
  default     = 500
}