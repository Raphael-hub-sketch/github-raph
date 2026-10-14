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

variable "endpoint_name" {
  description = "Имя Route53 Resolver Endpoint"
  type        = string
  default     = "resolver-endpoint"
}

variable "endpoint_direction" {
  description = "Направление DNS-запросов (INBOUND или OUTBOUND)"
  type        = string
  default     = "INBOUND"

  validation {
    condition     = contains(["INBOUND", "OUTBOUND"], var.endpoint_direction)
    error_message = "Допустимые значения: INBOUND, OUTBOUND."
  }
}

variable "resolver_endpoint_type" {
  description = "Тип endpoint (IPV4, IPV6 или DUALSTACK)"
  type        = string
  default     = "IPV4"
}

variable "protocols" {
  description = "Протоколы для endpoint (Do53, DoH, DoH-FIPS)"
  type        = list(string)
  default     = ["Do53"]
}

variable "vpc_cidr" {
  description = "CIDR блок для VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  description = "CIDR блоки для подсетей (минимум две в разных AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "allowed_cidr_blocks" {
  description = "CIDR блоки, которым разрешён DNS-трафик к endpoint"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "create_vpc" {
  description = "Создавать ли VPC и подсети для демонстрации"
  type        = bool
  default     = true
}