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

variable "create_topic" {
  description = "Создавать SNS Topic"
  type        = bool
  default     = true
}

variable "existing_topic_arn" {
  description = "ARN существующего SNS Topic"
  type        = string
  default     = ""
}

variable "subscriptions" {
  description = "Список подписок"
  type = list(object({
    protocol              = string
    endpoint              = string
    raw_message_delivery  = optional(bool, false)
    filter_policy         = optional(string, null)
    filter_policy_scope   = optional(string, "MessageAttributes")
    redrive_policy        = optional(string, null)
    subscription_role_arn = optional(string, null)
    delivery_policy       = optional(string, null)
    replay_policy         = optional(string, null)
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