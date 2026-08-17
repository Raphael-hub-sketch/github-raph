variable "aws_region" {
  description = "Регион AWS для развертывания"
  type        = string
  default     = "us-east-1"
}

variable "zone_name" {
  description = "Имя приватной зоны хостинга"
  type        = string
  default     = "internal.example.com"
}

variable "owner_vpc_id" {
  description = "VPC владельца зоны (из того же аккаунта)"
  type        = string
}

variable "vpc_associations" {
  description = "Карта VPC для авторизации ассоциации"
  type = map(object({
    vpc_id     = string
    vpc_region = optional(string)
  }))
  default = {}
}

variable "estimated_dns_queries_per_month" {
  description = "Ориентировочное количество DNS-запросов в месяц для расчета затрат"
  type        = number
  default     = 1000000
}