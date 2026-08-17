variable "aws_region" {
  description = "Регион AWS для развертывания"
  type        = string
  default     = "us-east-1"
}

variable "collection_name" {
  description = "Уникальное имя для коллекции CIDR"
  type        = string
  default     = "my-cidr-collection"
}

variable "locations" {
  description = "Карта локаций и их CIDR-блоков"
  type = map(list(string))
  default = {}
}

variable "estimated_dns_queries_per_month" {
  description = "Ориентировочное количество DNS-запросов в месяц для расчета затрат"
  type        = number
  default     = 1000000
}