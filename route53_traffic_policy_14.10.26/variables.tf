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

variable "policy_name" {
  description = "Имя traffic policy"
  type        = string
  default     = "failover-policy"
}

variable "policy_comment" {
  description = "Комментарий к traffic policy"
  type        = string
  default     = "Active-passive failover policy managed by Terraform"
}

variable "record_type" {
  description = "Тип DNS-записи (A, AAAA, CNAME)"
  type        = string
  default     = "A"
}

variable "primary_endpoint_value" {
  description = "Значение primary endpoint"
  type        = string
  default     = "primary.example.com"
}

variable "secondary_endpoint_value" {
  description = "Значение secondary endpoint"
  type        = string
  default     = "secondary.example.com"
}

variable "create_instance" {
  description = "Создавать ли traffic policy instance (запись)"
  type        = bool
  default     = false
}

variable "hosted_zone_id" {
  description = "ID hosted zone для traffic policy instance"
  type        = string
  default     = ""
}

variable "instance_name" {
  description = "Доменное имя для traffic policy instance"
  type        = string
  default     = "app.example.com"
}

variable "instance_ttl" {
  description = "TTL для traffic policy instance"
  type        = number
  default     = 300
}