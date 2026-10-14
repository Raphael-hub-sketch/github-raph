# =====================================================================
# Route53 Traffic Policy (основной ресурс)
# ---------------------------------------------------------------------
# Управляет политикой маршрутизации трафика. Создание политики
# бесплатно. Плата взимается за traffic policy records (instances).
# =====================================================================
resource "aws_route53_traffic_policy" "main" {
  name     = var.policy_name
  comment  = var.policy_comment
  document = data.aws_route53_traffic_policy_document.main.json
}

# =====================================================================
# ИМИТАЦИЯ ЗАТРАТ (Cost Simulation)
# ---------------------------------------------------------------------
# Ниже — развёрнутый блок, документирующий предполагаемые расходы.
# Он не влияет на инфраструктуру, но служит единым источником правды
# для FinOps-команды и может быть распарсен внешними скриптами
# (например, через `terraform output -json cost_report`).
# =====================================================================

locals {
  # ------------------------------------------------------------------
  # СЕКЦИЯ 1: Справочник цен AWS Route53 Traffic Flow (us-east-1, 2024-2025)
  # Источник: https://aws.amazon.com/route53/pricing/ [citation:12][citation:16]
  # ------------------------------------------------------------------
  traffic_flow_pricing = {
    # Политики создаются бесплатно
    policy_creation_usd           = 0.00
    
    # Ежемесячная плата за каждую traffic policy record (instance)
    # Точная цена зависит от региона, для us-east-1 — около $50/мес
    policy_record_monthly_usd     = 50.00
    
    # Дополнительные запросы (стандартные тарифы Route53)
    query_standard_per_million    = 0.40
    query_latency_per_million     = 0.60
    query_geo_per_million         = 0.70
    
    # Hosted zone
    hosted_zone_monthly_usd       = 0.50
    
    # Часов в месяце (30 дней)
    hours_per_month               = 720
    hours_per_year                = 8760
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 2: Прогнозируемое потребление (имитация)
  # ------------------------------------------------------------------
  traffic_flow_usage = {
    # Количество политик (бесплатно)
    policies_count                = 1
    
    # Количество traffic policy records (платно)
    policy_records_count          = var.create_instance ? 1 : 0
    
    # Версии политики (до 1000 на политику) [citation:17]
    policy_versions               = 1
    
    # Месячные DNS-запросы (в миллионах)
    monthly_queries_millions      = 100
    
    # Количество endpoints
    endpoints_count               = 2
    
    # Количество правил
    rules_count                   = 1
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 3: Детализированный расчёт затрат (построчный)
  # ------------------------------------------------------------------
  cost_breakdown = {
    # --- Политики (бесплатно) ---
    policy_creation = {
      description = "Traffic Policy: создание политики"
      quantity    = local.traffic_flow_usage.policies_count
      unit_price  = local.traffic_flow_pricing.policy_creation_usd
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Политики создаются бесплатно [citation:12]"
    }

    # --- Traffic Policy Records (платно) ---
    policy_records = {
      description = "Traffic Policy Records (записи на основе политики)"
      quantity    = local.traffic_flow_usage.policy_records_count
      unit_price  = local.traffic_flow_pricing.policy_record_monthly_usd
      monthly_usd = local.traffic_flow_usage.policy_records_count * local.traffic_flow_pricing.policy_record_monthly_usd
      yearly_usd  = local.traffic_flow_usage.policy_records_count * local.traffic_flow_pricing.policy_record_monthly_usd * 12
      notes       = "Основная статья расходов Traffic Flow [citation:16]"
    }

    # --- Hosted Zone ---
    hosted_zone = {
      description = "Hosted Zone для traffic policy"
      quantity    = 1
      unit_price  = local.traffic_flow_pricing.hosted_zone_monthly_usd
      monthly_usd = local.traffic_flow_pricing.hosted_zone_monthly_usd
      yearly_usd  = local.traffic_flow_pricing.hosted_zone_monthly_usd * 12
      notes       = "Необходима для создания policy records"
    }

    # --- DNS-запросы ---
    queries = {
      description = "DNS-запросы через traffic policy"
      quantity    = local.traffic_flow_usage.monthly_queries_millions
      unit_price  = local.traffic_flow_pricing.query_standard_per_million
      monthly_usd = local.traffic_flow_usage.monthly_queries_millions * local.traffic_flow_pricing.query_standard_per_million
      yearly_usd  = local.traffic_flow_usage.monthly_queries_millions * local.traffic_flow_pricing.query_standard_per_million * 12
      notes       = "Стандартные тарифы Route53"
    }

    # --- Версии политики (бесплатно) ---
    policy_versions = {
      description = "Traffic Policy Versions"
      quantity    = local.traffic_flow_usage.policy_versions
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "До 1000 версий на политику бесплатно [citation:17]"
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 4: Итоговые суммы (имитация)
  # ------------------------------------------------------------------
  cost_monthly_total = sum([
    for k, v in local.cost_breakdown : v.monthly_usd
  ])

  cost_yearly_total = sum([
    for k, v in local.cost_breakdown : v.yearly_usd
  ])

  cost_currency = "USD"

  # ------------------------------------------------------------------
  # СЕКЦИЯ 5: Построчная детализация по каждому элементу затрат
  # ------------------------------------------------------------------
  cost_line_items = [
    {
      line_no     = 1
      service     = "Route53"
      component   = "TrafficPolicy.Creation"
      description = "Создание traffic policy"
      unit        = "n/a"
      quantity    = local.traffic_flow_usage.policies_count
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Политики бесплатны [citation:12]"
    },
    {
      line_no     = 2
      service     = "Route53"
      component   = "TrafficPolicy.Record"
      description = "Traffic Policy Record (запись)"
      unit        = "per record/month"
      quantity    = local.traffic_flow_usage.policy_records_count
      unit_price  = local.traffic_flow_pricing.policy_record_monthly_usd
      monthly_usd = local.traffic_flow_usage.policy_records_count * local.traffic_flow_pricing.policy_record_monthly_usd
      yearly_usd  = local.traffic_flow_usage.policy_records_count * local.traffic_flow_pricing.policy_record_monthly_usd * 12
      notes       = "~$50/мес за запись в us-east-1 [citation:16]"
    },
    {
      line_no     = 3
      service     = "Route53"
      component   = "HostedZone"
      description = "Hosted Zone"
      unit        = "zone/month"
      quantity    = 1
      unit_price  = local.traffic_flow_pricing.hosted_zone_monthly_usd
      monthly_usd = local.traffic_flow_pricing.hosted_zone_monthly_usd
      yearly_usd  = local.traffic_flow_pricing.hosted_zone_monthly_usd * 12
      notes       = "Необходима для policy records"
    },
    {
      line_no     = 4
      service     = "Route53"
      component   = "Queries.Standard"
      description = "Стандартные DNS-запросы"
      unit        = "per million"
      quantity    = local.traffic_flow_usage.monthly_queries_millions
      unit_price  = local.traffic_flow_pricing.query_standard_per_million
      monthly_usd = local.traffic_flow_usage.monthly_queries_millions * local.traffic_flow_pricing.query_standard_per_million
      yearly_usd  = local.traffic_flow_usage.monthly_queries_millions * local.traffic_flow_pricing.query_standard_per_million * 12
      notes       = "Стандартный тариф Route53"
    },
    {
      line_no     = 5
      service     = "Route53"
      component   = "TrafficPolicy.Versions"
      description = "Версии политики"
      unit        = "n/a"
      quantity    = local.traffic_flow_usage.policy_versions
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "До 1000 версий бесплатно [citation:17]"
    },
  ]

  # ------------------------------------------------------------------
  # СЕКЦИЯ 6: Расширенная разбивка по категориям (для дашбордов)
  # ------------------------------------------------------------------
  cost_by_category = {
    "TrafficPolicy.Creation" = 0.00
    "TrafficPolicy.Records"  = local.traffic_flow_usage.policy_records_count * local.traffic_flow_pricing.policy_record_monthly_usd
    "DNS.HostedZone"         = local.traffic_flow_pricing.hosted_zone_monthly_usd
    "DNS.Queries"            = local.traffic_flow_usage.monthly_queries_millions * local.traffic_flow_pricing.query_standard_per_million
    "TrafficPolicy.Versions" = 0.00
  }

  cost_by_service = {
    "Route53" = local.cost_monthly_total
  }

  cost_by_environment = {
    "${var.environment}" = local.cost_monthly_total
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 7: Прогноз на 12 месяцев (имитация)
  # ------------------------------------------------------------------
  monthly_forecast = [
    for m in range(1, 13) : {
      month        = m
      month_name   = element([
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
      ], m - 1)
      base_usd     = local.cost_monthly_total
      growth_rate  = 0.02
      projected_usd = local.cost_monthly_total * pow(1.02, m - 1)
    }
  ]

  yearly_projection = {
    total_usd       = sum([for m in local.monthly_forecast : m.projected_usd])
    average_monthly = sum([for m in local.monthly_forecast : m.projected_usd]) / 12
    peak_month      = max([for m in local.monthly_forecast : m.projected_usd]...)
    lowest_month    = min([for m in local.monthly_forecast : m.projected_usd]...)
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 8: Сравнение сценариев (What-If analysis)
  # ------------------------------------------------------------------
  scenario_comparison = {
    "current" = {
      description          = "Текущая конфигурация (${local.traffic_flow_usage.policy_records_count} records)"
      policy_records       = local.traffic_flow_usage.policy_records_count
      monthly_usd          = local.cost_monthly_total
    }
    "policy_only" = {
      description          = "Только политика без records (бесплатно)"
      policy_records       = 0
      monthly_usd          = 0.00
    }
    "one_record" = {
      description          = "Одна traffic policy record"
      policy_records       = 1
      monthly_usd          = local.traffic_flow_pricing.policy_record_monthly_usd + local.traffic_flow_pricing.hosted_zone_monthly_usd
    }
    "five_records" = {
      description          = "Пять traffic policy records"
      policy_records       = 5
      monthly_usd          = 5 * local.traffic_flow_pricing.policy_record_monthly_usd + local.traffic_flow_pricing.hosted_zone_monthly_usd
    }
    "alias_optimization" = {
      description          = "Оптимизация через alias records [citation:12]"
      policy_records       = 1
      monthly_usd          = local.traffic_flow_pricing.policy_record_monthly_usd + local.traffic_flow_pricing.hosted_zone_monthly_usd
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 9: Алерты и пороги (имитация для AWS Budgets)
  # ------------------------------------------------------------------
  budget_thresholds = {
    monthly_warning      = 100.00
    monthly_critical     = 200.00
    yearly_max           = 2000.00
    notify_emails        = ["finops@example.com", "devops@example.com"]
    alert_on_breach      = true
    policy_records_warn  = 3
    policy_records_crit  = 5
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 10: Метаданные отчёта
  # ------------------------------------------------------------------
  cost_report_metadata = {
    generated_by       = "terraform"
    project            = var.project_name
    environment        = var.environment
    policy_name        = var.policy_name
    record_type        = var.record_type
    aws_region         = var.aws_region
    currency           = local.cost_currency
    pricing_source     = "https://aws.amazon.com/route53/pricing/"
    pricing_date       = "2025-01-01"
    report_version     = "1.0.0"
    disclaimer         = "Это имитация. Для точных цифр используйте Infracost / AWS Cost Explorer."
    billing_note       = "Traffic Policies бесплатны. Плата за Traffic Policy Records (instances) [citation:12]"
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 11: Проверка лимитов и квот (имитация)
  # Источник: AWS Route53 quotas [citation:4][citation:17]
  # ------------------------------------------------------------------
  quota_checks = {
    max_traffic_policies_per_account    = 50
    max_traffic_policy_records_account  = 5
    max_versions_per_policy             = 1000
    current_policies                    = local.traffic_flow_usage.policies_count
    current_records                     = local.traffic_flow_usage.policy_records_count
    current_versions                    = local.traffic_flow_usage.policy_versions
    policies_ok                         = local.traffic_flow_usage.policies_count <= 50
    records_ok                          = local.traffic_flow_usage.policy_records_count <= 5
    versions_ok                         = local.traffic_flow_usage.policy_versions <= 1000
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 12: Детализация по типам правил (для документации)
  # Источник: AWS Traffic Policy Document Format [citation:5][citation:10]
  # ------------------------------------------------------------------
  rule_type_details = {
    "failover" = {
      description     = "Active-passive failover"
      primary         = "Основной endpoint (весь трафик при доступности)"
      secondary       = "Резервный endpoint (при недоступности primary)"
      health_check    = "Обязателен для корректной работы"
    }
    "weighted" = {
      description     = "Weighted routing по пропорциям"
      weight_range    = "0-255"
      example         = "Веса 4,5,5,6 (сумма 20) = 4/20, 5/20, 5/20, 6/20 трафика"
      health_check    = "Опционально"
    }
    "latency" = {
      description     = "Latency-based routing"
      region          = "Указывается AWS Region"
      health_check    = "Опционально"
    }
    "geo" = {
      description     = "Geolocation routing"
      locations       = "Continent, Country, Subdivision"
      default         = "IsDefault для неопределённых локаций"
    }
    "geoproximity" = {
      description     = "Geoproximity routing (2023-05-09 формат)"
      bias            = "Расширяет/сужает географическую зону"
      local_zone      = "Поддерживает Local Zones [citation:10]"
    }
    "multivalue" = {
      description     = "Multivalue answer routing"
      items           = "До 8 здоровых записей в ответе"
      health_check    = "Опционально"
    }
  }
}