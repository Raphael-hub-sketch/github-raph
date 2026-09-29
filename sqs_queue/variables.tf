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

variable "queue_name" {
  description = "Имя SQS очереди (для FIFO должно оканчиваться на .fifo)"
  type        = string
  default     = "notifications-queue"
}

variable "fifo_queue" {
  description = "Создавать ли FIFO очередь"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Включить content-based дедупликацию для FIFO"
  type        = bool
  default     = false
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout (секунды)"
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "Время хранения сообщений (секунды)"
  type        = number
  default     = 345600  # 4 дня
}

variable "max_message_size" {
  description = "Максимальный размер сообщения (байты)"
  type        = number
  default     = 262144  # 256 KB
}

variable "receive_wait_time_seconds" {
  description = "Long polling wait time (0-20 секунд)"
  type        = number
  default     = 10
}

variable "delay_seconds" {
  description = "Задержка доставки сообщений (0-900 секунд)"
  type        = number
  default     = 0
}

variable "sqs_managed_sse_enabled" {
  description = "Включить SSE-SQS шифрование"
  type        = bool
  default     = true
}

variable "create_dlq" {
  description = "Создавать ли Dead Letter Queue"
  type        = bool
  default     = true
}

variable "max_receive_count" {
  description = "Максимум получений до перемещения в DLQ"
  type        = number
  default     = 5
}