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
  default     = "redshift-iam-roles-demo"
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

variable "iam_role_arns" {
  description = "List of IAM Role ARNs to associate with the cluster (max 10)"
  type        = list(string)
  default     = []
}

variable "default_iam_role_arn" {
  description = "ARN of the default IAM role for the cluster"
  type        = string
  default     = null
}

variable "monthly_hours" {
  description = "Hours per month"
  type        = number
  default     = 730
}

variable "spectrum_scanned_tb" {
  description = "Assumed Redshift Spectrum data scanned in TB per month"
  type        = number
  default     = 0
}