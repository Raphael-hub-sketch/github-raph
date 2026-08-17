terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Получение текущего региона
data "aws_region" "current" {}

# Источник данных для генерации JSON-документа политики трафика
data "aws_route53_traffic_policy_document" "example" {
  record_type = "A"
  start_rule  = "site_switch"

  endpoint {
    id    = "my_elb"
    type  = "elastic-load-balancer"
    value = "elb-111111.${data.aws_region.current.name}.elb.amazonaws.com"
  }

  endpoint {
    id     = "site_down_banner"
    type   = "s3-website"
    region = data.aws_region.current.name
    value  = "www.example.com"
  }

  rule {
    id   = "site_switch"
    type = "failover"

    primary {
      endpoint_reference = "my_elb"
    }

    secondary {
      endpoint_reference = "site_down_banner"
    }
  }
}

# Создание зоны хостинга
resource "aws_route53_zone" "main" {
  name = var.zone_name
}

# Создание политики трафика
resource "aws_route53_traffic_policy" "example" {
  name     = var.policy_name
  comment  = var.policy_comment
  document = data.aws_route53_traffic_policy_document.example.json
}

# Создание экземпляра политики трафика
resource "aws_route53_traffic_policy_instance" "example" {
  name                   = var.record_name
  traffic_policy_id      = aws_route53_traffic_policy.example.id
  traffic_policy_version = aws_route53_traffic_policy.example.version
  hosted_zone_id         = aws_route53_zone.main.zone_id
  ttl                    = var.ttl
}

# ==============================================
# ИМИТАЦИЯ ЗАТРАТ (интегрирована в main.tf)
# ==============================================

locals {
  # Параметры для расчета затрат (можно переопределить через переменные)
  estimated_queries_per_month = 100000  # Количество DNS-запросов в месяц
  health_checks_count        = 2        # Количество проверок работоспособности
  
  # Стоимость компонентов (в долларах США)
  traffic_policy_cost        = 50.00    # $50 в месяц за политику
  standard_query_cost        = 0.40     # $0.40 за 1 млн запросов
  health_check_cost          = 0.50     # $0.50 за одну проверку в месяц
  hosted_zone_cost           = 0.50     # $0.50 за зону хостинга в месяц
  
  # Расчет затрат
  query_cost = (local.estimated_queries_per_month / 1000000) * local.standard_query_cost
  health_checks_total = local.health_checks_count * local.health_check_cost
  
  total_monthly_cost = local.traffic_policy_cost + local.query_cost + local.health_checks_total + local.hosted_zone_cost
  
  # Детализация затрат для вывода
  cost_breakdown = {
    "Политика трафика (Traffic Policy)"     = format("$%.2f", local.traffic_policy_cost)
    "DNS-запросы (${local.estimated_queries_per_month} запросов)" = format("$%.2f", local.query_cost)
    "Проверки работоспособности (${local.health_checks_count} шт)" = format("$%.2f", local.health_checks_total)
    "Зона хостинга (Hosted Zone)"           = format("$%.2f", local.hosted_zone_cost)
    "---------------------------------"     = "------"
    "ИТОГО в месяц"                         = format("$%.2f", local.total_monthly_cost)
  }
}

# Выходные данные с имитацией затрат
output "cost_estimate" {
  description = "Имитация затрат на использование ресурсов Route53"
  value       = local.cost_breakdown
}

# Дополнительный вывод с общей суммой для удобства
output "total_monthly_cost" {
  description = "Общая ориентировочная стоимость в месяц"
  value       = format("$%.2f", local.total_monthly_cost)
}