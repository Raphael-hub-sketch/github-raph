# variables.tf
# Входные переменные для конфигурации SNS Platform Application

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
  default     = "sns-push-demo"
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ SNS PLATFORM APPLICATION
# ============================================================

variable "platform_application_name" {
  description = "Friendly name for the SNS platform application"
  type        = string
  default     = null
}

variable "platform" {
  description = "Platform for push notifications (APNS, APNS_SANDBOX, GCM, ADM, BAIDU)"
  type        = string
  default     = "GCM"

  validation {
    condition = contains([
      "APNS", "APNS_SANDBOX", "GCM", "ADM", "BAIDU"
    ], var.platform)
    error_message = "Platform must be one of: APNS, APNS_SANDBOX, GCM, ADM, BAIDU."
  }
}

variable "platform_credential" {
  description = "Platform credential (API key for GCM/FCM, private key for APNS)"
  type        = string
  default     = "demo-credential-placeholder"
  sensitive   = true
}

variable "platform_principal" {
  description = "Platform principal (certificate for APNS). Required for APNS/APNS_SANDBOX only."
  type        = string
  default     = null
  sensitive   = true
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ ОБРАБОТКИ СОБЫТИЙ (Event Topics)
# ============================================================

variable "create_event_topics" {
  description = "Whether to create SNS topics for platform application events"
  type        = bool
  default     = true
}

variable "event_delivery_failure_topic_arn" {
  description = "SNS Topic ARN for delivery failures"
  type        = string
  default     = null
}

variable "event_endpoint_created_topic_arn" {
  description = "SNS Topic ARN for endpoint created events"
  type        = string
  default     = null
}

variable "event_endpoint_deleted_topic_arn" {
  description = "SNS Topic ARN for endpoint deleted events"
  type        = string
  default     = null
}

variable "event_endpoint_updated_topic_arn" {
  description = "SNS Topic ARN for endpoint updated events"
  type        = string
  default     = null
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ FEEDBACK РОЛЕЙ
# ============================================================

variable "create_feedback_roles" {
  description = "Whether to create IAM roles for success/failure feedback"
  type        = bool
  default     = true
}

variable "failure_feedback_role_arn" {
  description = "IAM Role ARN for failure feedback"
  type        = string
  default     = null
}

variable "success_feedback_role_arn" {
  description = "IAM Role ARN for success feedback"
  type        = string
  default     = null
}

variable "success_feedback_sample_rate" {
  description = "Percentage of success to sample (0-100)"
  type        = number
  default     = 100

  validation {
    condition     = var.success_feedback_sample_rate >= 0 && var.success_feedback_sample_rate <= 100
    error_message = "Sample rate must be between 0 and 100."
  }
}

# ============================================================
# ПЕРЕМЕННЫЕ ДЛЯ ИМИТАЦИИ ЗАТРАТ
# ============================================================

variable "monthly_push_notifications" {
  description = "Assumed number of monthly push notifications for cost estimation"
  type        = number
  default     = 1000000
}

variable "monthly_api_requests" {
  description = "Assumed number of monthly API requests for cost estimation"
  type        = number
  default     = 500000
}

variable "monthly_endpoint_operations" {
  description = "Assumed number of monthly endpoint operations (create/delete/update)"
  type        = number
  default     = 10000
}