terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Настройка провайдера AWS (владелец зоны)
provider "aws" {
  region = var.aws_region
}

# Создание приватной зоны хостинга
resource "aws_route53_zone" "private" {
  name = var.zone_name
  vpc {
    vpc_id = var.owner_vpc_id
  }
}

# Авторизация ассоциации VPC из другого аккаунта
# Используем for_each для создания нескольких авторизаций
resource "aws_route53_vpc_association_authorization" "this" {
  for_each = var.vpc_associations

  zone_id = aws_route53_zone.private.zone_id
  vpc_id  = each.value.vpc_id
  vpc_region = lookup(each.value, "vpc_region", var.aws_region)
}

# (Опционально) Ассоциация VPC после авторизации
# Обычно выполняется в аккаунте-владельце VPC с отдельным провайдером
# resource "aws_route53_zone_association" "cross_account" {
#   provider = aws.vpc_owner
#   for_each = var.vpc_associations
#   
#   zone_id = aws_route53_zone.private.zone_id
#   vpc_id  = each.value.vpc_id
# }

# ==============================================
# ИМИТАЦИЯ ЗАТРАТ (интегрирована в main.tf)
# ==============================================

locals {
  # Параметры для расчета затрат
  estimated_dns_queries_per_month = var.estimated_dns_queries_per_month
  association_count = length(var.vpc_associations)
  
  # Стоимость компонентов (в долларах США) на основе типовых тарифов Route53
  # Приватные зоны: $0.50 за зону в месяц
  hosted_zone_cost = 0.50
  
  # DNS-запросы: $0.40 за 1 млн стандартных запросов [citation:7]
  standard_query_cost = 0.40
  
  # Авторизация ассоциации VPC не влечет дополнительных прямых затрат,
  # однако ассоциация зоны с VPC может влиять на стоимость запросов
  
  # Расчет затрат
  query_cost = (local.estimated_dns_queries_per_month / 1000000) * local.standard_query_cost
  
  # Базовая стоимость: зона хостинга + запросы
  base_monthly_cost = local.hosted_zone_cost + local.query_cost
  
  # Детализация затрат для вывода
  cost_breakdown = {
    "Количество авторизаций VPC" = local.association_count
    "Приватная зона (Hosted Zone)" = format("$%.2f", local.hosted_zone_cost)
    "DNS-запросы (${local.estimated_dns_queries_per_month} запросов)" = format("$%.2f", local.query_cost)
    "---------------------------------" = "------"
    "ИТОГО в месяц" = format("$%.2f", local.base_monthly_cost)
  }
}