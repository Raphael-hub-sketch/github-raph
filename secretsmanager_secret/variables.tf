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

variable "secret_name" {
  description = "Имя секрета (допустимы: /_+=.@-, без пробелов)"
  type        = string
  default     = "database/credentials"
}

variable "secret_description" {
  description = "Описание секрета"
  type        = string
  default     = "Database credentials managed by Terraform"
}

variable "recovery_window_in_days" {
  description = "Окно восстановления после удаления (0 = force delete, 7-30 = дней)"
  type        = number
  default     = 30

  validation {
    condition     = var.recovery_window_in_days == 0 || (var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30)
    error_message = "Допустимые значения: 0 (force delete) или 7-30 дней."
  }
}

variable "kms_key_id" {
  description = "ARN или alias KMS-ключа (null = использовать aws/secretsmanager)"
  type        = string
  default     = null
}

variable "create_secret_version" {
  description = "Создавать ли значение секрета (aws_secretsmanager_secret_version)"
  type        = bool
  default     = true
}

variable "secret_username" {
  description = "Имя пользователя для секрета"
  type        = string
  default     = "dbadmin"
}

variable "secret_host" {
  description = "Хост базы данных"
  type        = string
  default     = "database.example.com"
}

variable "secret_port" {
  description = "Порт базы данных"
  type        = string
  default     = "5432"
}

variable "secret_dbname" {
  description = "Имя базы данных"
  type        = string
  default     = "myappdb"
}

variable "create_policy" {
  description = "Создавать ли resource policy для секрета"
  type        = bool
  default     = false
}

variable "allowed_read_principals" {
  description = "AWS principals, которым разрешено чтение секрета"
  type        = list(string)
  default     = ["arn:aws:iam::123456789012:role/app-role"]
}

variable "enable_replication" {
  description = "Включить ли multi-region replication"
  type        = bool
  default     = false
}

variable "replica_regions" {
  description = "Регионы для репликации секрета"
  type        = list(string)
  default     = ["us-west-2"]
}