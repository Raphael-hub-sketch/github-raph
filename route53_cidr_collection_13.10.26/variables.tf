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

variable "locations" {
  description = "Список CIDR-локаций для создания"
  type = list(object({
    name        = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      name        = "office-moscow"
      cidr_blocks = ["203.0.113.0/24", "198.51.100.0/24"]
    },
    {
      name        = "office-spb"
      cidr_blocks = ["192.0.2.0/24"]
    },
    {
      name        = "vpn-users"
      cidr_blocks = ["10.100.0.0/24", "10.100.1.0/24"]
    }
  ]
}