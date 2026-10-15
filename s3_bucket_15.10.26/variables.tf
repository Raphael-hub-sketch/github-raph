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

variable "bucket_prefix" {
  description = "Префикс имени бакета (случайный суффикс добавится автоматически)"
  type        = string
  default     = "app-assets"
}

variable "force_destroy" {
  description = "Удалять все объекты при уничтожении бакета"
  type        = bool
  default     = false
}

variable "enable_versioning" {
  description = "Включить версионирование объектов"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Включить server-side шифрование (SSE-S3)"
  type        = bool
  default     = true
}

variable "block_public_access" {
  description = "Блокировать публичный доступ"
  type        = bool
  default     = true
}

variable "enable_lifecycle" {
  description = "Создавать ли lifecycle rules"
  type        = bool
  default     = true
}

variable "lifecycle_ia_days" {
  description = "Дней до перехода в STANDARD_IA"
  type        = number
  default     = 30
}

variable "lifecycle_glacier_days" {
  description = "Дней до перехода в GLACIER_IR"
  type        = number
  default     = 90
}

variable "lifecycle_deep_archive_days" {
  description = "Дней до перехода в DEEP_ARCHIVE"
  type        = number
  default     = 180
}

variable "lifecycle_expiration_days" {
  description = "Дней до удаления объектов (0 = не удалять)"
  type        = number
  default     = 365
}