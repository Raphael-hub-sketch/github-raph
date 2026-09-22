# =====================================================================
# Route53 Profiles Resource Association
# =====================================================================
resource "aws_route53profiles_resource_association" "main" {
  name         = var.resource_association_name
  profile_id   = aws_route53profiles_profile.main.id
  resource_arn = var.resource_arn

  # resource_properties опционально
  resource_properties = var.resource_properties

  # Известный баг провайдера с resource_properties — игнорируем изменения
  # если не хотим ловить "inconsistent result after apply"
  # Исправлено в v6.3.0 (атрибут Computed) [citation:11]
  lifecycle {
    ignore_changes = [resource_properties]
  }

  tags = merge(local.common_tags, {
    Name         = var.resource_association_name
    ResourceArn  = var.resource_arn
  })
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
  # СЕКЦИЯ 1: Справочник цен AWS Route53 Profiles (us-east-1, 2024-2025)
  # Источник: https://aws.amazon.com/route53/pricing/
  # ------------------------------------------------------------------
  profiles_pricing = {
    # Базовая ставка за аккаунт в регионе (включает до 100 Profile-VPC ассоциаций)
    base_hourly_usd              = 0.75
    # Дополнительные Profile-VPC ассоциации сверх 100
    additional_assoc_hourly_usd  = 0.0014
    # Включено в базовую ставку
    included_associations        = 100
    # Часов в месяце (30 дней)
    hours_per_month              = 720
    hours_per_year               = 8760
  }

  # Дополнительные услуги Route53 (для полноты картины)
  route53_addons = {
    hosted_zone_monthly          = 0.50
    hosted_zone_additional       = 0.10
    query_standard_per_million   = 0.40
    query_latency_per_million    = 0.60
    query_geo_per_million        = 0.70
    health_check_monthly         = 0.50
    dnssec_monthly               = 1.00
    query_logging_per_gb         = 0.50
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 2: Прогнозируемое потребление (имитация)
  # ------------------------------------------------------------------
  profiles_usage = {
    # Количество VPC-ассоциаций с профилем (основной драйвер затрат)
    vpc_associations             = 120
    # Количество resource associations (НЕ влияет на биллинг, но документируем)
    resource_associations        = 5
    # Количество профилей в аккаунте
    profiles_count               = 2
    # Количество запросов (для полноты)
    monthly_queries_millions     = 250
    latency_queries_millions     = 40
    geo_queries_millions         = 15
    health_checks_basic          = 3
    dnssec_enabled               = false
    query_log_gb_per_month       = 12
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 3: Детализированный расчёт затрат (построчный)
  # ------------------------------------------------------------------
  cost_breakdown = {
    # --- Route53 Profiles: базовая ставка ---
    profiles_base = {
      description = "Route53 Profiles: базовая ставка (до ${local.profiles_pricing.included_associations} Profile-VPC ассоциаций)"
      quantity    = local.profiles_usage.profiles_count
      unit_price  = local.profiles_pricing.base_hourly_usd
      monthly_usd = local.profiles_pricing.base_hourly_usd * local.profiles_pricing.hours_per_month
      yearly_usd  = local.profiles_pricing.base_hourly_usd * local.profiles_pricing.hours_per_year
    }

    # --- Route53 Profiles: дополнительные ассоциации ---
    profiles_additional_assoc = {
      description = "Route53 Profiles: дополнительные Profile-VPC ассоциации (сверх ${local.profiles_pricing.included_associations})"
      quantity    = max(0, local.profiles_usage.vpc_associations - local.profiles_pricing.included_associations)
      unit_price  = local.profiles_pricing.additional_assoc_hourly_usd
      monthly_usd = max(0, local.profiles_usage.vpc_associations - local.profiles_pricing.included_associations) * local.profiles_pricing.additional_assoc_hourly_usd * local.profiles_pricing.hours_per_month
      yearly_usd  = max(0, local.profiles_usage.vpc_associations - local.profiles_pricing.included_associations) * local.profiles_pricing.additional_assoc_hourly_usd * local.profiles_pricing.hours_per_year
    }

    # --- Hosted Zone ---
    hosted_zone = {
      description = "Route53 Hosted Zone (для приватной зоны)"
      quantity    = 1
      unit_price  = local.route53_addons.hosted_zone_monthly
      monthly_usd = local.route53_addons.hosted_zone_monthly
      yearly_usd  = local.route53_addons.hosted_zone_monthly * 12
    }

    # --- Queries: Standard ---
    queries_standard = {
      description = "Standard DNS queries"
      quantity    = local.profiles_usage.monthly_queries_millions
      unit_price  = local.route53_addons.query_standard_per_million
      monthly_usd = local.profiles_usage.monthly_queries_millions * local.route53_addons.query_standard_per_million
      yearly_usd  = local.profiles_usage.monthly_queries_millions * local.route53_addons.query_standard_per_million * 12
    }

    # --- Queries: Latency-based ---
    queries_latency = {
      description = "Latency-based routing queries"
      quantity    = local.profiles_usage.latency_queries_millions
      unit_price  = local.route53_addons.query_latency_per_million
      monthly_usd = local.profiles_usage.latency_queries_millions * local.route53_addons.query_latency_per_million
      yearly_usd  = local.profiles_usage.latency_queries_millions * local.route53_addons.query_latency_per_million * 12
    }

    # --- Queries: Geolocation ---
    queries_geo = {
      description = "Geolocation routing queries"
      quantity    = local.profiles_usage.geo_queries_millions
      unit_price  = local.route53_addons.query_geo_per_million
      monthly_usd = local.profiles_usage.geo_queries_millions * local.route53_addons.query_geo_per_million
      yearly_usd  = local.profiles_usage.geo_queries_millions * local.route53_addons.query_geo_per_million * 12
    }

    # --- Health checks ---
    health_checks = {
      description = "Basic health checks (TCP/HTTP)"
      quantity    = local.profiles_usage.health_checks_basic
      unit_price  = local.route53_addons.health_check_monthly
      monthly_usd = local.profiles_usage.health_checks_basic * local.route53_addons.health_check_monthly
      yearly_usd  = local.profiles_usage.health_checks_basic * local.route53_addons.health_check_monthly * 12
    }

    # --- DNSSEC ---
    dnssec = {
      description = "DNSSEC signing"
      quantity    = local.profiles_usage.dnssec_enabled ? 1 : 0
      unit_price  = local.route53_addons.dnssec_monthly
      monthly_usd = local.profiles_usage.dnssec_enabled ? local.route53_addons.dnssec_monthly : 0
      yearly_usd  = local.profiles_usage.dnssec_enabled ? local.route53_addons.dnssec_monthly * 12 : 0
    }

    # --- Query logging ---
    query_logging = {
      description = "Query logging to CloudWatch Logs"
      quantity    = local.profiles_usage.query_log_gb_per_month
      unit_price  = local.route53_addons.query_logging_per_gb
      monthly_usd = local.profiles_usage.query_log_gb_per_month * local.route53_addons.query_logging_per_gb
      yearly_usd  = local.profiles_usage.query_log_gb_per_month * local.route53_addons.query_logging_per_gb * 12
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
      service     = "Route53Profiles"
      component   = "BaseHourlyRate"
      description = "Базовая почасовая ставка за аккаунт в регионе (включает до ${local.profiles_pricing.included_associations} Profile-VPC ассоциаций)"
      unit        = "hour"
      quantity    = local.profiles_pricing.hours_per_month
      unit_price  = local.profiles_pricing.base_hourly_usd
      monthly_usd = local.profiles_pricing.base_hourly_usd * local.profiles_pricing.hours_per_month
      yearly_usd  = local.profiles_pricing.base_hourly_usd * local.profiles_pricing.hours_per_year
      notes       = "Ставка применяется независимо от количества профилей (в пределах 100 ассоциаций)"
    },
    {
      line_no     = 2
      service     = "Route53Profiles"
      component   = "AdditionalVpcAssociations"
      description = "Дополнительные Profile-VPC ассоциации (сверх ${local.profiles_pricing.included_associations})"
      unit        = "assoc/hour"
      quantity    = max(0, local.profiles_usage.vpc_associations - local.profiles_pricing.included_associations)
      unit_price  = local.profiles_pricing.additional_assoc_hourly_usd
      monthly_usd = max(0, local.profiles_usage.vpc_associations - local.profiles_pricing.included_associations) * local.profiles_pricing.additional_assoc_hourly_usd * local.profiles_pricing.hours_per_month
      yearly_usd  = max(0, local.profiles_usage.vpc_associations - local.profiles_pricing.included_associations) * local.profiles_pricing.additional_assoc_hourly_usd * local.profiles_pricing.hours_per_year
      notes       = "Только ассоциации Profile-VPC, а не resource associations"
    },
    {
      line_no     = 3
      service     = "Route53"
      component   = "HostedZone"
      description = "Приватная hosted zone для DNS-разрешения"
      unit        = "zone/month"
      quantity    = 1
      unit_price  = local.route53_addons.hosted_zone_monthly
      monthly_usd = local.route53_addons.hosted_zone_monthly
      yearly_usd  = local.route53_addons.hosted_zone_monthly * 12
      notes       = "Первая зона — $0.50/мес"
    },
    {
      line_no     = 4
      service     = "Route53"
      component   = "Queries.Standard"
      description = "Стандартные DNS-запросы через профиль"
      unit        = "per million"
      quantity    = local.profiles_usage.monthly_queries_millions
      unit_price  = local.route53_addons.query_standard_per_million
      monthly_usd = local.profiles_usage.monthly_queries_millions * local.route53_addons.query_standard_per_million
      yearly_usd  = local.profiles_usage.monthly_queries_millions * local.route53_addons.query_standard_per_million * 12
      notes       = "Оценка на основе исторических данных"
    },
    {
      line_no     = 5
      service     = "Route53"
      component   = "Queries.Latency"
      description = "Latency-based routing queries"
      unit        = "per million"
      quantity    = local.profiles_usage.latency_queries_millions
      unit_price  = local.route53_addons.query_latency_per_million
      monthly_usd = local.profiles_usage.latency_queries_millions * local.route53_addons.query_latency_per_million
      yearly_usd  = local.profiles_usage.latency_queries_millions * local.route53_addons.query_latency_per_million * 12
      notes       = "Используется для multi-region failover"
    },
    {
      line_no     = 6
      service     = "Route53"
      component   = "Queries.Geo"
      description = "Geolocation routing queries"
      unit        = "per million"
      quantity    = local.profiles_usage.geo_queries_millions
      unit_price  = local.route53_addons.query_geo_per_million
      monthly_usd = local.profiles_usage.geo_queries_millions * local.route53_addons.query_geo_per_million
      yearly_usd  = local.profiles_usage.geo_queries_millions * local.route53_addons.query_geo_per_million * 12
      notes       = "Гео-маршрутизация для EU/US"
    },
    {
      line_no     = 7
      service     = "Route53"
      component   = "HealthCheck.Basic"
      description = "Базовые health check (TCP/HTTP)"
      unit        = "check/month"
      quantity    = local.profiles_usage.health_checks_basic
      unit_price  = local.route53_addons.health_check_monthly
      monthly_usd = local.profiles_usage.health_checks_basic * local.route53_addons.health_check_monthly
      yearly_usd  = local.profiles_usage.health_checks_basic * local.route53_addons.health_check_monthly * 12
      notes       = "Для primary endpoints"
    },
    {
      line_no     = 8
      service     = "Route53"
      component   = "DNSSEC"
      description = "DNSSEC signing"
      unit        = "month"
      quantity    = local.profiles_usage.dnssec_enabled ? 1 : 0
      unit_price  = local.route53_addons.dnssec_monthly
      monthly_usd = local.profiles_usage.dnssec_enabled ? local.route53_addons.dnssec_monthly : 0
      yearly_usd  = local.profiles_usage.dnssec_enabled ? local.route53_addons.dnssec_monthly * 12 : 0
      notes       = local.profiles_usage.dnssec_enabled ? "Включено" : "Отключено"
    },
    {
      line_no     = 9
      service     = "CloudWatch"
      component   = "Logs.Ingestion"
      description = "Query logging в CloudWatch Logs"
      unit        = "per GB"
      quantity    = local.profiles_usage.query_log_gb_per_month
      unit_price  = local.route53_addons.query_logging_per_gb
      monthly_usd = local.profiles_usage.query_log_gb_per_month * local.route53_addons.query_logging_per_gb
      yearly_usd  = local.profiles_usage.query_log_gb_per_month * local.route53_addons.query_logging_per_gb * 12
      notes       = "Оценка: ~12 GB/мес DNS-логов"
    },
    {
      line_no     = 10
      service     = "Route53Profiles"
      component   = "ResourceAssociation"
      description = "Ассоциация ресурса (${var.resource_association_name}) с профилем"
      unit        = "association"
      quantity    = 1
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Не тарифицируется отдельно. Билинг только за Profile-VPC ассоциации"
    },
  ]

  # ------------------------------------------------------------------
  # СЕКЦИЯ 6: Расширенная разбивка по категориям (для дашбордов)
  # ------------------------------------------------------------------
  cost_by_category = {
    "Profiles.Base"          = local.profiles_pricing.base_hourly_usd * local.profiles_pricing.hours_per_month
    "Profiles.Additional"    = max(0, local.profiles_usage.vpc_associations - local.profiles_pricing.included_associations) * local.profiles_pricing.additional_assoc_hourly_usd * local.profiles_pricing.hours_per_month
    "DNS.Zones"              = local.route53_addons.hosted_zone_monthly
    "DNS.Queries"            = (local.profiles_usage.monthly_queries_millions * local.route53_addons.query_standard_per_million) + (local.profiles_usage.latency_queries_millions * local.route53_addons.query_latency_per_million) + (local.profiles_usage.geo_queries_millions * local.route53_addons.query_geo_per_million)
    "DNS.HealthCheck"        = local.profiles_usage.health_checks_basic * local.route53_addons.health_check_monthly
    "DNS.Security"           = local.profiles_usage.dnssec_enabled ? local.route53_addons.dnssec_monthly : 0
    "Logging"                = local.profiles_usage.query_log_gb_per_month * local.route53_addons.query_logging_per_gb
    "ResourceAssociations"   = 0.00
  }

  cost_by_service = {
    "Route53Profiles" = (local.profiles_pricing.base_hourly_usd * local.profiles_pricing.hours_per_month) + (max(0, local.profiles_usage.vpc_associations - local.profiles_pricing.included_associations) * local.profiles_pricing.additional_assoc_hourly_usd * local.profiles_pricing.hours_per_month)
    "Route53"         = local.route53_addons.hosted_zone_monthly + (local.profiles_usage.monthly_queries_millions * local.route53_addons.query_standard_per_million) + (local.profiles_usage.latency_queries_millions * local.route53_addons.query_latency_per_million) + (local.profiles_usage.geo_queries_millions * local.route53_addons.query_geo_per_million) + (local.profiles_usage.health_checks_basic * local.route53_addons.health_check_monthly) + (local.profiles_usage.dnssec_enabled ? local.route53_addons.dnssec_monthly : 0)
    "CloudWatch"      = local.profiles_usage.query_log_gb_per_month * local.route53_addons.query_logging_per_gb
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
      growth_rate  = 0.02 # 2% ежемесячный рост трафика
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
      description          = "Текущая конфигурация (${local.profiles_usage.vpc_associations} VPC-ассоциаций)"
      vpc_associations     = local.profiles_usage.vpc_associations
      additional_assoc     = max(0, local.profiles_usage.vpc_associations - local.profiles_pricing.included_associations)
      monthly_usd          = local.cost_monthly_total
    }
    "within_free_tier" = {
      description          = "Только базовые 100 ассоциаций"
      vpc_associations     = local.profiles_pricing.included_associations
      additional_assoc     = 0
      monthly_usd          = local.profiles_pricing.base_hourly_usd * local.profiles_pricing.hours_per_month + (local.cost_monthly_total - local.profiles_pricing.base_hourly_usd * local.profiles_pricing.hours_per_month - max(0, local.profiles_usage.vpc_associations - local.profiles_pricing.included_associations) * local.profiles_pricing.additional_assoc_hourly_usd * local.profiles_pricing.hours_per_month)
    }
    "double_associations" = {
      description          = "Удвоенное количество VPC-ассоциаций"
      vpc_associations     = local.profiles_usage.vpc_associations * 2
      additional_assoc     = max(0, local.profiles_usage.vpc_associations * 2 - local.profiles_pricing.included_associations)
      monthly_usd          = local.cost_monthly_total + max(0, local.profiles_usage.vpc_associations * 2 - local.profiles_pricing.included_associations) * local.profiles_pricing.additional_assoc_hourly_usd * local.profiles_pricing.hours_per_month - max(0, local.profiles_usage.vpc_associations - local.profiles_pricing.included_associations) * local.profiles_pricing.additional_assoc_hourly_usd * local.profiles_pricing.hours_per_month
    }
    "minimal" = {
      description          = "Минимальная конфигурация (без логов, DNSSEC, health checks)"
      vpc_associations     = local.profiles_usage.vpc_associations
      additional_assoc     = max(0, local.profiles_usage.vpc_associations - local.profiles_pricing.included_associations)
      monthly_usd          = local.cost_monthly_total - (local.profiles_usage.health_checks_basic * local.route53_addons.health_check_monthly) - (local.profiles_usage.dnssec_enabled ? local.route53_addons.dnssec_monthly : 0) - (local.profiles_usage.query_log_gb_per_month * local.route53_addons.query_logging_per_gb)
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 9: Алерты и пороги (имитация для AWS Budgets)
  # ------------------------------------------------------------------
  budget_thresholds = {
    monthly_warning      = 600.00
    monthly_critical     = 800.00
    yearly_max           = 8000.00
    notify_emails        = ["finops@example.com", "devops@example.com"]
    alert_on_breach      = true
    vpc_association_warn = 150
    vpc_association_crit = 200
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 10: Метаданные отчёта
  # ------------------------------------------------------------------
  cost_report_metadata = {
    generated_by       = "terraform"
    project            = var.project_name
    environment        = var.environment
    profile_name       = var.profile_name
    resource_assoc     = var.resource_association_name
    resource_arn       = var.resource_arn
    aws_region         = var.aws_region
    currency           = local.cost_currency
    pricing_source     = "https://aws.amazon.com/route53/pricing/"
    pricing_date       = "2025-01-01"
    report_version     = "1.0.0"
    disclaimer         = "Это имитация. Для точных цифр используйте Infracost / AWS Cost Explorer."
    billing_note       = "Билинг Route53 Profiles основан на количестве Profile-VPC ассоциаций, а не resource associations"
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 11: Детализация по типам ресурсов (для документации)
  # ------------------------------------------------------------------
  resource_type_details = {
    "PrivateHostedZone" = {
      description     = "Приватная hosted zone"
      arn_pattern     = "arn:aws:route53:::hostedzone/Z*"
      billing_impact  = "hosted_zone_monthly"
      supports_props  = false
    }
    "ResolverRule" = {
      description     = "Route 53 Resolver rule (forward/system)"
      arn_pattern     = "arn:aws:route53resolver:*:*:resolver-rule/rslvr-rr-*"
      billing_impact  = "query_pricing"
      supports_props  = true
    }
    "FirewallRuleGroup" = {
      description     = "DNS Firewall rule group"
      arn_pattern     = "arn:aws:route53resolver:*:*:firewall-rule-group/rslvr-frg-*"
      billing_impact  = "firewall_query_pricing"
      supports_props  = true
      example_props   = jsonencode({ priority = 102 })
    }
    "VpcEndpoint" = {
      description     = "Interface VPC endpoint"
      arn_pattern     = "arn:aws:ec2:*:*:vpc-endpoint/vpce-*"
      billing_impact  = "vpc_endpoint_hourly"
      supports_props  = true
      known_issue     = "Провайдер может возвращать inconsistent result для resource_properties (исправлено в v6.3.0)"
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 12: Проверка лимитов и квот (имитация)
  # ------------------------------------------------------------------
  quota_checks = {
    max_resource_associations_per_profile = 100
    max_profiles_per_account              = 10
    max_vpc_associations_per_profile      = 1000
    current_resource_associations         = local.profiles_usage.resource_associations
    current_vpc_associations              = local.profiles_usage.vpc_associations
    resource_assoc_ok                     = local.profiles_usage.resource_associations <= 100
    vpc_assoc_ok                          = local.profiles_usage.vpc_associations <= 1000
  }
}