# ==============================================================================
# variables.tf
# Входные переменные для конфигурации
# ==============================================================================

variable "aws_region" {
  description = "Регион AWS для развертывания ресурсов"
  type        = string
  default     = "us-east-1"
}

variable "hosted_zone_name" {
  description = "Имя частной зоны Route 53"
  type        = string
  default     = "internal.example.com"
}

variable "primary_vpc_cidr" {
  description = "CIDR-блок для основного VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "alternate_vpc_cidr" {
  description = "CIDR-блок для альтернативного VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "environment" {
  description = "Название окружения (для тегов)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Название проекта (для тегов)"
  type        = string
  default     = "route53-demo"
}