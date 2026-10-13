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

variable "collection_name" {
  description = "Уникальное имя CIDR-коллекции"
  type        = string
  default     = "ip-routing-collection"
}

variable "location_name" {
  description = "Имя CIDR-локации (максимум 16 символов)"
  type        = string
  default     = "office-moscow"

  validation {
    condition     = length(var.location_name) <= 16
    error_message = "Имя локации не должно превышать 16 символов."
  }
}

variable "cidr_blocks" {
  description = "Список CIDR-блоков для локации (IPv4 /0-/24, IPv6 /0-/48)"
  type        = list(string)
  default     = ["203.0.113.0/24", "198.51.100.0/24"]
}

variable "create_collection" {
  description = "Создавать ли CIDR-коллекцию или использовать существующую"
  type        = bool
  default     = true
}

variable "existing_collection_id" {
  description = "ID существующей коллекции (если create_collection = false)"
  type        = string
  default     = ""
}