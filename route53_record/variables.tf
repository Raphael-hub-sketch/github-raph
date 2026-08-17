variable "aws_region" {
  description = "Регион AWS для развертывания"
  type        = string
  default     = "us-east-1"
}

variable "zone_name" {
  description = "Имя зоны хостинга Route53"
  type        = string
  default     = "example.com"
}

variable "records" {
  description = "Список DNS-записей для создания"
  type = map(object({
    name    = string
    type    = string
    ttl     = optional(number)
    records = optional(list(string))
    alias = optional(object({
      name    = string
      zone_id = string
      evaluate_target_health = optional(bool)
    }))
    weighted_routing_policy = optional(object({
      weight = number
    }))
    set_identifier = optional(string)
  }))
  default = {}
}

variable "estimated_dns_queries_per_month" {
  description = "Ориентировочное количество DNS-запросов в месяц для расчета затрат"
  type        = number
  default     = 1000000
}