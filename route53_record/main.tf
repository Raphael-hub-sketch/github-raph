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

# Создание зоны хостинга 
resource "aws_route53_zone" "main" {
  name = var.zone_name
}

# Создание DNS-записей с использованием for_each
# Поддерживаются различные типы записей: A, CNAME, MX, TXT, NS и другие 
resource "aws_route53_record" "this" {
  for_each = var.records

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = lookup(each.value, "ttl", 300)
  records = lookup(each.value, "records", [])
  
  # Поддержка alias-записей для AWS-сервисов 
  dynamic "alias" {
    for_each = lookup(each.value, "alias", null) != null ? [each.value.alias] : []
    content {
      name                = alias.value.name
      zone_id             = alias.value.zone_id
      evaluate_target_health = lookup(alias.value, "evaluate_target_health", false)
    }
  }

  # Поддержка weighted-записей 
  dynamic "weighted_routing_policy" {
    for_each = lookup(each.value, "weighted_routing_policy", null) != null ? [each.value.weighted_routing_policy] : []
    content {
      weight = weighted_routing_policy.value.weight
    }
  }

  # Для записей с несколькими значениями используем set_identifier 
  set_identifier = lookup(each.value, "set_identifier", null)
}

# ==============================================
# ИМИТАЦИЯ ЗАТРАТ (интегрирована в main.tf)
# ==============================================

locals {
  # Параметры для расчета затрат
  estimated_dns_queries_per_month = var.estimated_dns_queries_per_month
  record_count = length(var.records)
  
  # Стоимость компонентов (в долларах США) на основе типовых тарифов Route53
  # Зона хостинга: $0.50 в месяц 
  hosted_zone_cost = 0.50
  
  # DNS-запросы: $0.40 за 1 млн стандартных запросов 
  # $0.60 за 1 млн запросов на основе задержки 
  # $0.70 за 1 млн Geo DNS запросов 
  standard_query_cost = 0.40
  latency_query_cost  = 0.60
  geo_query_cost      = 0.70
  
  # Расчет затрат (используем стандартные запросы как базовые)
  query_cost = (local.estimated_dns_queries_per_month / 1000000) * local.standard_query_cost
  
  # Базовая стоимость: зона хостинга + запросы
  base_monthly_cost = local.hosted_zone_cost + local.query_cost
  
  # Детализация затрат для вывода
  cost_breakdown = {
    "Количество DNS-записей" = local.record_count
    "Зона хостинга (Hosted Zone)" = format("$%.2f", local.hosted_zone_cost)
    "DNS-запросы (${local.estimated_dns_queries_per_month} запросов)" = format("$%.2f", local.query_cost)
    "---------------------------------" = "------"
    "ИТОГО в месяц" = format("$%.2f", local.base_monthly_cost)
  }
}