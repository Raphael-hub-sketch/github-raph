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

variable "health_check_name" {
  description = "Имя health check"
  type        = string
  default     = "api-health-check"
}

variable "fqdn" {
  description = "Fully qualified domain name для проверки"
  type        = string
  default     = "api.example.com"
}

variable "health_check_type" {
  description = "Тип health check (HTTP, HTTPS, TCP, HTTP_STR_MATCH, HTTPS_STR_MATCH, CALCULATED)"
  type        = string
  default     = "HTTPS"

  validation {
    condition     = contains(["HTTP", "HTTPS", "TCP", "HTTP_STR_MATCH", "HTTPS_STR_MATCH", "CALCULATED"], var.health_check_type)
    error_message = "Допустимые значения: HTTP, HTTPS, TCP, HTTP_STR_MATCH, HTTPS_STR_MATCH, CALCULATED."
  }
}

variable "resource_path" {
  description = "Путь для проверки"
  type        = string
  default     = "/health"
}

variable "port" {
  description = "Порт для проверки"
  type        = number
  default     = 443
}

variable "request_interval" {
  description = "Интервал проверки (10 или 30 секунд)"
  type        = number
  default     = 30

  validation {
    condition     = contains([10, 30], var.request_interval)
    error_message = "Допустимые значения: 10 или 30."
  }
}

variable "failure_threshold" {
  description = "Количество неудачных проверок до unhealthy"
  type        = number
  default     = 3

  validation {
    condition     = var.failure_threshold >= 1 && var.failure_threshold <= 10
    error_message = "Значение должно быть от 1 до 10."
  }
}

variable "search_string" {
  description = "Строка для поиска в ответе (для STR_MATCH)"
  type        = string
  default     = null
}

variable "measure_latency" {
  description = "Измерять ли latency"
  type        = bool
  default     = false
}

variable "invert_healthcheck" {
  description = "Инвертировать статус проверки"
  type        = bool
  default     = false
}

variable "disabled" {
  description = "Отключить health check (продолжает тарифицироваться)"
  type        = bool
  default     = false
}

variable "is_aws_endpoint" {
  description = "Является ли endpoint AWS-ресурсом (влияет на тарификацию и free tier)"
  type        = bool
  default     = true
}

variable "create_cloudwatch_alarm" {
  description = "Создавать ли CloudWatch Alarm на основе health check"
  type        = bool
  default     = true
}

variable "sns_topic_arn" {
  description = "ARN SNS топика для алертов"
  type        = string
  default     = "arn:aws:sns:us-east-1:123456789012:alerts-topic"
}