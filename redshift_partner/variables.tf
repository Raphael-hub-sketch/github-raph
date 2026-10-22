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

variable "partner_account_id" {
  description = "AWS account ID that owns the cluster (partner integration)"
  type        = string
  default     = "123456789012"
}

variable "partner_name" {
  description = "Name of the partner authorized to send data"
  type        = string
  default     = "example-partner"
}

variable "partner_database_name" {
  description = "Database name that receives data from the partner"
  type        = string
  default     = "analytics"
}

variable "storage_gb" {
  description = "Estimated Redshift Managed Storage (GB)"
  type        = number
  default     = 500
}

variable "spectrum_data_scanned_tb" {
  description = "Estimated Spectrum data scanned per month (TB)"
  type        = number
  default     = 1
}