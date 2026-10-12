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

variable "vpc_cidr" {
  description = "CIDR блок для VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR блоки для публичных подсетей"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR блоки для приватных подсетей"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "create_public_route_table" {
  description = "Создавать ли публичную route table"
  type        = bool
  default     = true
}

variable "create_private_route_table" {
  description = "Создавать ли приватную route table"
  type        = bool
  default     = true
}

variable "create_nat_gateway" {
  description = "Создавать ли NAT Gateway (влияет на затраты)"
  type        = bool
  default     = true
}

variable "create_vpc_endpoints" {
  description = "Создавать ли VPC Endpoints (влияет на затраты)"
  type        = bool
  default     = false
}

variable "monthly_data_processed_gb" {
  description = "Оценка объёма данных через NAT Gateway (GB/мес)"
  type        = number
  default     = 100
}

variable "enable_transit_gateway" {
  description = "Использовать ли Transit Gateway (влияет на затраты)"
  type        = bool
  default     = false
}

variable "transit_gateway_attachments" {
  description = "Количество VPC attachments к Transit Gateway"
  type        = number
  default     = 1
}