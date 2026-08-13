# variables.tf
variable "region" {
  description = "AWS регион, в котором будет создан ресурс"
  type        = string
  default     = "us-east-1"
}

variable "cidr_collection_name" {
  description = "Название CIDR коллекции Route53"
  type        = string
  default     = "my-cidr-collection"
}

variable "location_name" {
  description = "Название географического местоположения для CIDR блоков"
  type        = string
  default     = "office-main"
}

variable "cidr_blocks" {
  description = "Список CIDR блоков, связанных с данным местоположением"
  type        = list(string)
  default = [
    "10.0.0.0/24",
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
    "10.0.4.0/24",
    "10.0.5.0/24",
    "10.0.6.0/24",
    "10.0.7.0/24",
    "10.0.8.0/24",
    "10.0.9.0/24",
    "10.0.10.0/24",
    "10.0.11.0/24",
    "10.0.12.0/24",
    "10.0.13.0/24",
    "10.0.14.0/24",
    "10.0.15.0/24",
    "10.0.16.0/24",
    "10.0.17.0/24",
    "10.0.18.0/24",
    "10.0.19.0/24",
    "10.0.20.0/24",
    "10.0.21.0/24",
    "10.0.22.0/24"
  ]
}