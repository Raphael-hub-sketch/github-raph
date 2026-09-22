locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # ------------------------------------------------------------------
  # ИМИТАЦИЯ ЗАТРАТ: справочник цен AWS Route53 Profiles (us-east-1, 2024-2025)
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
  # Прогнозируемое потребление (имитация)
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
  # Детализированный расчёт затрат (построчный — для имитации объёма)
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
  # Итоговые суммы (имитация)
  # ------------------------------------------------------------------
  cost_monthly_total = sum([
    for k, v in local.cost_breakdown : v.monthly_usd
  ])

  cost_yearly_total = sum([
    for k, v in local.cost_breakdown : v.yearly_usd
  ])

  cost_currency = "USD"
}