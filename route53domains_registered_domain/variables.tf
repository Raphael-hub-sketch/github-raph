variable "aws_region" {
  description = "AWS регион (Route53 Domains — глобальный сервис, но требуется)"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Имя домена, зарегистрированного в Route 53"
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

variable "auto_renew" {
  description = "Включить автоматическое продление домена"
  type        = bool
  default     = true
}

variable "transfer_lock" {
  description = "Заблокировать трансфер домена"
  type        = bool
  default     = true
}

variable "privacy_protection" {
  description = "Включить защиту приватности WHOIS"
  type        = bool
  default     = true
}

variable "registrant_contact" {
  description = "Контакт регистранта"
  type = object({
    first_name  = string
    last_name   = string
    email       = string
    phone       = string
    address     = string
    city        = string
    state       = string
    zip_code    = string
    country     = string
  })
  default = {
    first_name = "John"
    last_name  = "Doe"
    email      = "admin@example.com"
    phone      = "+1.5555555555"
    address    = "123 Main St"
    city       = "New York"
    state      = "NY"
    zip_code   = "10001"
    country    = "US"
  }
}