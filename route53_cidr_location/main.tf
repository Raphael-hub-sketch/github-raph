terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Настройка провайдера AWS
provider "aws" {
  region = var.aws_region
}

# Создание коллекции CIDR для Route53 [citation:2]
resource "aws_route53_cidr_collection" "main" {
  name = var.collection_name
}

# Генерация локаций с помощью for_each [citation:1][citation:7]
resource "aws_route53_cidr_location" "locations" {
  for_each = var.locations

  cidr_collection_id = aws_route53_cidr_collection.main.id
  name               = each.key
  cidr_blocks        = each.value
}

# ==============================================
# ИМИТАЦИЯ ЗАТРАТ (интегрирована в main.tf)
# ==============================================

locals {
  # Параметры для расчета затрат (можно переопределить через переменные)
  estimated_dns_queries_per_month = 1000000  # Количество DNS-запросов в месяц
  location_count                  = length(var.locations)
  
  # Стоимость компонентов (в долларах США) на основе типовых тарифов Route53
  hosted_zone_cost   = 0.50      # $0.50 за зону хостинга в месяц
  standard_query_cost = 0.40     # $0.40 за 1 млн стандартных запросов
  
  # Расчет затрат
  query_cost = (local.estimated_dns_queries_per_month / 1000000) * local.standard_query_cost
  
  # Базовая стоимость: зона хостинга + запросы
  base_monthly_cost = local.hosted_zone_cost + local.query_cost
  
  # Детализация затрат для вывода
  cost_breakdown = {
    "Количество локаций"                     = local.location_count
    "Зона хостинга (Hosted Zone)"           = format("$%.2f", local.hosted_zone_cost)
    "DNS-запросы (${local.estimated_dns_queries_per_month} запросов)" = format("$%.2f", local.query_cost)
    "---------------------------------"     = "------"
    "ИТОГО в месяц"                         = format("$%.2f", local.base_monthly_cost)
  }
}