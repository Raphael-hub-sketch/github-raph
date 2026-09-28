# variables.tf
# Входные переменные для конфигурации S3 bucket

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
  default     = "s3-cost-demo"
}

variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique). If null, auto-generated."
  type        = string
  default     = null
}

# ============================================================
# ФУНКЦИОНАЛЬНЫЕ ПЕРЕМЕННЫЕ
# ============================================================

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "enable_lifecycle" {
  description = "Enable S3 bucket lifecycle configuration"
  type        = bool
  default     = true
}

variable "lifecycle_glacier_days" {
  description = "Days after which objects transition to Glacier"
  type        = number
  default     = 90
}

variable "lifecycle_expiration_days" {
  description = "Days after which objects expire"
  type        = number
  default     = 365
}

variable "enable_encryption" {
  description = "Enable server-side encryption"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable S3 access logging"
  type        = bool
  default     = false
}

variable "enable_public_access_block" {
  description = "Block all public access to the bucket"
  type        = bool
  default     = true
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ ИМИТАЦИИ ЗАТРАТ
# ============================================================

variable "storage_gb" {
  description = "Assumed storage volume in GB for cost estimation"
  type        = number
  default     = 100
}

variable "monthly_requests" {
  description = "Assumed number of monthly requests for cost estimation"
  type        = number
  default     = 1000000
}

variable "versioning_overhead_gb" {
  description = "Assumed overhead from non-current versions in GB"
  type        = number
  default     = 20
}

variable "logging_gb" {
  description = "Assumed volume of access logs in GB"
  type        = number
  default     = 5
}

variable "transition_objects" {
  description = "Assumed number of objects transitioned to Glacier"
  type        = number
  default     = 10000
}