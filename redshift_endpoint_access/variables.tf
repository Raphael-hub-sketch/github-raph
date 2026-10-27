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
  default     = "redshift-endpoint-access-demo"
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

variable "endpoint_name" {
  description = "Redshift-managed VPC endpoint name"
  type        = string
  default     = "demo-endpoint"
}

variable "resource_owner" {
  description = "AWS account ID of the cluster owner (if cross-account)"
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "Security group IDs for the endpoint"
  type        = list(string)
  default     = []
}

variable "monthly_hours" {
  description = "Hours per month"
  type        = number
  default     = 730
}

variable "monthly_data_processed_gb" {
  description = "Assumed data processed through endpoint in GB"
  type        = number
  default     = 0
}