# variables.tf
variable "aws_region" {
  description = "AWS регион"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Окружение"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Имя проекта"
  type        = string
  default     = "infra-core"
}

variable "owner" {
  description = "Ответственный"
  type        = string
  default     = "devops-team"
}

variable "cost_center" {
  description = "Cost center"
  type        = string
  default     = "CC-1042"
}

variable "topic_name" {
  description = "Имя SNS Topic"
  type        = string
  default     = "notifications-topic"
}

variable "display_name" {
  description = "Отображаемое имя"
  type        = string
  default     = "Notifications Topic"
}

variable "fifo_topic" {
  description = "FIFO топик"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Content-based дедупликация"
  type        = bool
  default     = false
}

variable "kms_master_key_id" {
  description = "KMS key для шифрования"
  type        = string
  default     = null
}

variable "create_topic_policy" {
  description = "Создавать политику топика"
  type        = bool
  default     = true
}

variable "allowed_publish_principals" {
  description = "AWS principals для публикации"
  type        = list(string)
  default     = ["arn:aws:iam::123456789012:root"]
}