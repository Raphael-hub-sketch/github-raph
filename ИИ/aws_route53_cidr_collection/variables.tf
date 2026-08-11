# variables.tf

# ============================================
# ОСНОВНЫЕ ПЕРЕМЕННЫЕ
# ============================================

variable "aws_region" {
  description = "Primary AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "backup_region" {
  description = "Backup AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment (dev, staging, production)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production"
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "cidr-routing"
}

# ============================================
# ПЕРЕМЕННЫЕ ДЛЯ CIDR COLLECTION
# ============================================

variable "cidr_collection_name" {
  description = "Name of the Route53 CIDR collection"
  type        = string
  default     = null

  # Если не указано, генерируется из project_name и environment
}

variable "cidr_collection_tags" {
  description = "Additional tags for CIDR collection"
  type        = map(string)
  default     = {}
}

# ============================================
# ПЕРЕМЕННЫЕ ДЛЯ CIDR LOCATIONS
# ============================================

variable "locations" {
  description = "Map of CIDR locations with CIDR blocks"
  type = map(object({
    cidr_blocks = list(string)
    description = optional(string, "")
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.locations : length(v.cidr_blocks) > 0
    ])
    error_message = "Each location must have at least one CIDR block."
  }
}

variable "enable_locations" {
  description = "Whether to create CIDR locations"
  type        = bool
  default     = true
}

# ============================================
# ПЕРЕМЕННЫЕ ДЛЯ ВЗАИМОДЕЙСТВИЯ С ДРУГИМИ МОДУЛЯМИ
# ============================================

variable "create_route53_records" {
  description = "Whether to create Route53 records using the CIDR collection"
  type        = bool
  default     = false
}

variable "hosted_zone_id" {
  description = "Hosted zone ID for creating records (if create_route53_records is true)"
  type        = string
  default     = null
}

variable "record_name" {
  description = "Record name for CIDR routing"
  type        = string
  default     = "example.com"
}

variable "record_ttl" {
  description = "TTL for CIDR routing records"
  type        = number
  default     = 300
}