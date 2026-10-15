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

variable "platform_app_name" {
  description = "Имя SNS Platform Application"
  type        = string
  default     = "mobile-push-app"
}

variable "platform" {
  description = "Платформа push-сервиса"
  type        = string
  default     = "GCM"
}

variable "platform_credential" {
  description = "Credential для платформы"
  type        = string
  default     = "AIzaSyDemo-ReplaceWithRealKey"
  sensitive   = true
}

variable "platform_principal" {
  description = "Principal для платформы"
  type        = string
  default     = null
  sensitive   = true
}

variable "create_event_topics" {
  description = "Создавать ли SNS Topics для event-триггеров"
  type        = bool
  default     = true
}

variable "success_feedback_sample_rate" {
  description = "Процент успешных доставок для логирования"
  type        = number
  default     = 100
}