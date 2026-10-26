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
  default     = "redshift-logging-demo"
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

variable "log_destination_type" {
  description = "Log destination type: s3 or cloudwatch"
  type        = string
  default     = "s3"

  validation {
    condition     = contains(["s3", "cloudwatch"], var.log_destination_type)
    error_message = "Must be s3 or cloudwatch."
  }
}

variable "log_exports" {
  description = "Log types to export (for cloudwatch)"
  type        = list(string)
  default     = ["connectionlog", "userlog"]
}

variable "s3_key_prefix" {
  description = "S3 key prefix for logs"
  type        = string
  default     = "redshift-logs/"
}

variable "monthly_log_storage_gb" {
  description = "Assumed monthly log storage in GB"
  type        = number
  default     = 10
}

variable "monthly_hours" {
  description = "Hours per month"
  type        = number
  default     = 730
}