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

variable "create_topic" {
  description = "Создавать ли SNS Topic или использовать существующий"
  type        = bool
  default     = true
}

variable "existing_topic_arn" {
  description = "ARN существующего SNS Topic (если create_topic = false)"
  type        = string
  default     = ""
}

variable "subscriptions" {
  description = "Список подписок (protocol + endpoint + опции)"
  type = list(object({
    protocol                = string
    endpoint                = string
    raw_message_delivery    = optional(bool, false)
    filter_policy           = optional(string, null)
    filter_policy_scope     = optional(string, "MessageAttributes")
    redrive_policy          = optional(string, null)
    subscription_role_arn   = optional(string, null)
    delivery_policy         = optional(string, null)
    replay_policy           = optional(string, null)
  }))
  default = [
    {
      protocol             = "sqs"
      endpoint             = "arn:aws:sqs:us-east-1:123456789012:my-queue"
      raw_message_delivery = true
    },
    {
      protocol = "lambda"
      endpoint = "arn:aws:lambda:us-east-1:123456789012:function:my-function"
    }
  ]
}