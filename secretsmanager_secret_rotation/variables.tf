# variables.tf
# Входные переменные для конфигурации Secrets Manager Rotation

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
  default     = "secrets-rotation-demo"
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ SECRET
# ============================================================

variable "secret_name" {
  description = "Name of the Secrets Manager secret"
  type        = string
  default     = null
}

variable "secret_description" {
  description = "Description of the secret"
  type        = string
  default     = "Demo secret with automatic rotation"
}

variable "secret_recovery_window_in_days" {
  description = "Recovery window for the secret (0-30 days)"
  type        = number
  default     = 7

  validation {
    condition     = var.secret_recovery_window_in_days >= 0 && var.secret_recovery_window_in_days <= 30
    error_message = "Recovery window must be between 0 and 30 days."
  }
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ ROTATION
# ============================================================

variable "enable_rotation" {
  description = "Whether to enable automatic rotation"
  type        = bool
  default     = true
}

variable "rotation_automatically_after_days" {
  description = "Number of days between automatic rotations"
  type        = number
  default     = 30

  validation {
    condition     = var.rotation_automatically_after_days >= 1
    error_message = "Rotation interval must be at least 1 day."
  }
}

variable "rotation_duration" {
  description = "Rotation window duration (e.g., 3h)"
  type        = string
  default     = "3h"
}

variable "rotation_schedule_expression" {
  description = "Cron or rate expression for rotation schedule (alternative to automatically_after_days)"
  type        = string
  default     = null
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ ЛЯМБДА-ФУНКЦИИ РОТАЦИИ
# ============================================================

variable "lambda_runtime" {
  description = "Runtime for the rotation Lambda function"
  type        = string
  default     = "python3.12"
}

variable "lambda_timeout" {
  description = "Timeout for the rotation Lambda function in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Memory size for the rotation Lambda function in MB"
  type        = number
  default     = 128
}

variable "create_rotation_lambda" {
  description = "Whether to create a new rotation Lambda function"
  type        = bool
  default     = true
}

variable "existing_rotation_lambda_arn" {
  description = "ARN of existing rotation Lambda function (if create_rotation_lambda is false)"
  type        = string
  default     = null
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ ИМИТАЦИИ ЗАТРАТ
# ============================================================

variable "monthly_secret_count" {
  description = "Assumed number of secrets for cost estimation"
  type        = number
  default     = 10
}

variable "monthly_api_calls" {
  description = "Assumed number of monthly API calls for cost estimation"
  type        = number
  default     = 50000
}

variable "monthly_rotation_invocations" {
  description = "Assumed number of monthly rotation Lambda invocations"
  type        = number
  default     = 30
}

variable "lambda_execution_duration_ms" {
  description = "Average Lambda execution duration in milliseconds"
  type        = number
  default     = 500
}