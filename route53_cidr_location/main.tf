terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Рекомендуемая версия провайдера
    }
  }
}

# Настройка провайдера AWS (замените регион на свой)
provider "aws" {
  region = var.aws_region
}

# Создание коллекции CIDR для Route53
resource "aws_route53_cidr_collection" "main" {
  name = var.collection_name
}

# Создание локаций и добавление CIDR-блоков
resource "aws_route53_cidr_location" "locations" {
  # Используем for_each для создания нескольких локаций из карты переменных 
  for_each = var.locations

  cidr_collection_id = aws_route53_cidr_collection.main.id
  name               = each.key
  cidr_blocks        = each.value
}