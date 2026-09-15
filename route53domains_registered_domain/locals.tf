locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # ------------------------------------------------------------------
  # ИМИТАЦИЯ ЗАТРАТ: справочник цен AWS Route53 Domains (2024-2025)
  # Источник: https://aws.amazon.com/route53/pricing/
  # ------------------------------------------------------------------
  domain_pricing = {
    # Цены за регистрацию/продление (USD/год)
    "com"    = 15.00
    "net"    = 18.00
    "org"    = 18.00
    "io"     = 45.00
    "dev"    = 17.00
    "app"    = 20.00
    "page"   = 14.00
    "click"  = 3.00
    "link"   = 12.00
    "info"   = 20.00
    "biz"    = 18.00
    "me"     = 20.00
    "co"     = 30.00
    "ai"     = 79.00
    "health" = 96.00
    "realty" = 199.00
    "build"  = 44.00
    "zip"    = 14.00
    "mov"    = 14.00
    "win"    = 35.00
  }

  # Дополнительные услуги
  domain_addons = {
    privacy_protection_yearly = 0.00    # Часто бесплатно, но может отличаться
    transfer_lock_yearly      = 0.00    # Бесплатно
    dnssec_yearly             = 12.00   # $1/мес
    hosted_zone_monthly       = 0.50    # $0.50/мес за hosted zone
    hosted_zone_additional    = 0.10    # Доп. зоны
    query_standard_per_mil    = 0.40    # Стандартные запросы
    query_latency_per_mil     = 0.60    # Latency-based
    query_geo_per_mil         = 0.70    # Geolocation
    health_check_monthly      = 0.50    # Basic health check
  }

  # ------------------------------------------------------------------
  # Прогнозируемое потребление (имитация)
  # ------------------------------------------------------------------
  domain_usage = {
    tld                    = "com"
    registration_years     = 1
    auto_renew             = var.auto_renew
    transfer_lock          = var.transfer_lock
    privacy_protection     = var.privacy_protection
    dnssec_enabled         = false
    monthly_queries_mil    = 250
    latency_queries_mil    = 40
    geo_queries_mil        = 15
    health_checks_basic    = 3
  }

  # ------------------------------------------------------------------
  # Детализированный расчёт затрат (построчный — для имитации объёма)
  # ------------------------------------------------------------------
  cost_breakdown = {
    # --- Регистрация домена ---
    domain_registration = {
      description = "Регистрация домена ${var.domain_name} (TLD: .${local.domain_usage.tld})"
      quantity    = local.domain_usage.registration_years
      unit_price  = lookup(local.domain_pricing, local.domain_usage.tld, 15.00)
      yearly_usd  = local.domain_usage.registration_years * lookup(local.domain_pricing, local.domain_usage.tld, 15.00)
      monthly_usd = (local.domain_usage.registration_years * lookup(local.domain_pricing, local.domain_usage.tld, 15.00)) / 12
    }

    # --- Hosted Zone ---
    hosted_zone = {
      description = "Route53 Hosted Zone для ${var.domain_name}"
      quantity    = 1
      unit_price  = local.domain_addons.hosted_zone_monthly
      monthly_usd = local.domain_addons.hosted_zone_monthly
      yearly_usd  = local.domain_addons.hosted_zone_monthly * 12
    }

    # --- Queries: Standard ---
    queries_standard = {
      description = "Standard DNS queries"
      quantity    = local.domain_usage.monthly_queries_mil
      unit_price  = local.domain_addons.query_standard_per_mil
      monthly_usd = local.domain_usage.monthly_queries_mil * local.domain_addons.query_standard_per_mil
      yearly_usd  = local.domain_usage.monthly_queries_mil * local.domain_addons.query_standard_per_mil * 12
    }

    # --- Queries: Latency-based ---
    queries_latency = {
      description = "Latency-based routing queries"
      quantity    = local.domain_usage.latency_queries_mil
      unit_price  = local.domain_addons.query_latency_per_mil
      monthly_usd = local.domain_usage.latency_queries_mil * local.domain_addons.query_latency_per_mil
      yearly_usd  = local.domain_usage.latency_queries_mil * local.domain_addons.query_latency_per_mil * 12
    }

    # --- Queries: Geolocation ---
    queries_geo = {
      description = "Geolocation routing queries"
      quantity    = local.domain_usage.geo_queries_mil
      unit_price  = local.domain_addons.query_geo_per_mil
      monthly_usd = local.domain_usage.geo_queries_mil * local.domain_addons.query_geo_per_mil
      yearly_usd  = local.domain_usage.geo_queries_mil * local.domain_addons.query_geo_per_mil * 12
    }

    # --- Health checks ---
    health_checks = {
      description = "Basic health checks (TCP/HTTP)"
      quantity    = local.domain_usage.health_checks_basic
      unit_price  = local.domain_addons.health_check_monthly
      monthly_usd = local.domain_usage.health_checks_basic * local.domain_addons.health_check_monthly
      yearly_usd  = local.domain_usage.health_checks_basic * local.domain_addons.health_check_monthly * 12
    }

    # --- DNSSEC ---
    dnssec = {
      description = "DNSSEC signing"
      quantity    = local.domain_usage.dnssec_enabled ? 1 : 0
      unit_price  = local.domain_addons.dnssec_yearly / 12
      monthly_usd = local.domain_usage.dnssec_enabled ? local.domain_addons.dnssec_yearly / 12 : 0
      yearly_usd  = local.domain_usage.dnssec_enabled ? local.domain_addons.dnssec_yearly : 0
    }

    # --- Privacy Protection ---
    privacy = {
      description = "WHOIS Privacy Protection"
      quantity    = local.domain_usage.privacy_protection ? 1 : 0
      unit_price  = local.domain_addons.privacy_protection_yearly
      monthly_usd = 0
      yearly_usd  = local.domain_usage.privacy_protection ? local.domain_addons.privacy_protection_yearly : 0
    }

    # --- Transfer Lock ---
    transfer_lock = {
      description = "Transfer Lock (защита от несанкционированного трансфера)"
      quantity    = local.domain_usage.transfer_lock ? 1 : 0
      unit_price  = local.domain_addons.transfer_lock_yearly
      monthly_usd = 0
      yearly_usd  = local.domain_usage.transfer_lock ? local.domain_addons.transfer_lock_yearly : 0
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