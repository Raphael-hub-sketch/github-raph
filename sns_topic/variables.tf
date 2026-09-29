variable "aws_region" {
  description = "AWS регион для развёртывания"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Окружение (dev/stage/prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Допустимые значения: dev, stage, prod."
  }
}

variable "project_name" {
  description = "Имя проекта"
  type        = string
  default     = "infra-core"
}

variable "owner" {
  description = "Ответственный за ресурс"
  type        = string
  default     = "devops-team"
}

variable "cost_center" {
  description = "Cost center для биллинга"
  type        = string
  default     = "CC-1042"
}

variable "topic_name" {
  description = "Имя SNS Topic"
  type        = string
  default     = "notifications-topic"
}

variable "display_name" {
  description = "Отображаемое имя топика"
  type        = string
  default     = "Notifications Topic"
}

variable "fifo_topic" {
  description = "Создавать ли FIFO топик (имя должно оканчиваться на .fifo)"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Включить content-based дедупликацию для FIFO"
  type        = bool
  default     = false
}

variable "kms_master_key_id" {
  description = "KMS key для server-side encryption (alias/aws/sns для AWS-managed)"
  type        = string
  default     = null
}

variable "create_topic_policy" {
  description = "Создавать ли политику топика"
  type        = bool
  default     = true
}

variable "allowed_publish_principals" {
  description = "AWS principals, которым разрешена публикация в топик"
  type        = list(string)
  default     = ["arn:aws:iam::123456789012:root"]
}