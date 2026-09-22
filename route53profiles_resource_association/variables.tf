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

variable "profile_name" {
  description = "Имя Route53 Profile"
  type        = string
  default     = "centralized-dns-profile"
}

variable "resource_association_name" {
  description = "Имя ассоциации ресурса с профилем"
  type        = string
  default     = "vpc-endpoint-association"
}

variable "resource_arn" {
  description = "ARN ресурса для ассоциации (hosted zone, resolver rule, DNS Firewall rule group или VPC endpoint)"
  type        = string
  default     = "arn:aws:route53:us-east-1:123456789012:hostedzone/Z123456789ABC"
}

variable "resource_properties" {
  description = "JSON-строка с дополнительными свойствами ресурса"
  type        = string
  default     = null
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

variable "associate_profile_with_vpc" {
  description = "Ассоциировать ли профиль с VPC (влияет на биллинг)"
  type        = bool
  default     = true
}