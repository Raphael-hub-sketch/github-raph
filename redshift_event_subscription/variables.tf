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
  default     = "redshift-event-sub-demo"
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

variable "subscription_name" {
  description = "Name of the Redshift event subscription"
  type        = string
  default     = "redshift-event-sub"
}

variable "severity" {
  description = "Event severity (INFO or ERROR)"
  type        = string
  default     = "INFO"
}

variable "event_categories" {
  description = "List of event categories"
  type        = list(string)
  default     = ["configuration", "management", "monitoring", "security"]
}

variable "enabled" {
  description = "Whether the subscription is enabled"
  type        = bool
  default     = true
}

variable "monthly_hours" {
  description = "Hours per month"
  type        = number
  default     = 730
}

variable "monthly_sns_notifications" {
  description = "Assumed number of SNS notifications per month"
  type        = number
  default     = 1000
}