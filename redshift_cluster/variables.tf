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
  default     = "redshift-cluster-demo"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_identifier" {
  description = "Redshift cluster identifier (lowercase)"
  type        = string
  default     = null
}

variable "node_type" {
  description = "Redshift node type"
  type        = string
  default     = "dc2.large"
}

variable "cluster_type" {
  description = "Cluster type: single-node or multi-node"
  type        = string
  default     = "multi-node"
}

variable "number_of_nodes" {
  description = "Number of nodes (ignored for single-node)"
  type        = number
  default     = 2
}

variable "database_name" {
  description = "Redshift database name"
  type        = string
  default     = "demodb"
}

variable "master_username" {
  description = "Redshift master username"
  type        = string
  default     = "adminuser"
  sensitive   = true
}

variable "master_password" {
  description = "Redshift master password"
  type        = string
  default     = "DemoPass123!"
  sensitive   = true
}

variable "manage_master_password" {
  description = "Use Secrets Manager for admin credentials"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Whether cluster is publicly accessible"
  type        = bool
  default     = false
}

variable "automated_snapshot_retention_period" {
  description = "Automated snapshot retention in days"
  type        = number
  default     = 7
}

variable "allow_version_upgrade" {
  description = "Allow major version upgrades"
  type        = bool
  default     = true
}

variable "monthly_hours" {
  description = "Hours per month"
  type        = number
  default     = 730
}

variable "spectrum_scanned_tb" {
  description = "Assumed Spectrum data scanned in TB"
  type        = number
  default     = 0
}

variable "managed_storage_gb" {
  description = "Assumed managed storage for RA3 nodes in GB"
  type        = number
  default     = 0
}