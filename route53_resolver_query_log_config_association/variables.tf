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

variable "vpc_cidr" {
  description = "CIDR блок для VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "create_vpc" {
  description = "Создавать ли VPC для демонстрации"
  type        = bool
  default     = true
}

variable "query_log_config_name" {
  description = "Имя конфигурации логирования DNS-запросов"
  type        = string
  default     = "dns-query-log-config"
}

variable "log_destination_type" {
  description = "Тип целевого сервиса для логов (cloudwatch, s3, firehose)"
  type        = string
  default     = "cloudwatch"

  validation {
    condition     = contains(["cloudwatch", "s3", "firehose"], var.log_destination_type)
    error_message = "Допустимые значения: cloudwatch, s3, firehose."
  }
}

variable "cloudwatch_log_retention_days" {
  description = "Срок хранения логов в CloudWatch (дни)"
  type        = number
  default     = 30
}

variable "s3_log_retention_days" {
  description = "Срок хранения логов в S3 (дни)"
  type        = number
  default     = 90
}

variable "estimated_log_volume_gb" {
  description = "Оценка объёма логов в месяц (GB)"
  type        = number
  default     = 50
}