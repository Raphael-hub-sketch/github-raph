variable "aws_region" {
  description = "AWS регион для развёртывания"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Имя домена для hosted zone"
  type        = string
  default     = "example.com"
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

variable "enable_dnssec" {
  description = "Включить DNSSEC для зоны"
  type        = bool
  default     = false
}

variable "create_query_log" {
  description = "Создавать ли CloudWatch log group для query logging"
  type        = bool
  default     = true
}

variable "query_log_retention_days" {
  description = "Срок хранения логов DNS-запросов"
  type        = number
  default     = 30
}