locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # ------------------------------------------------------------------
  # ИМИТАЦИЯ ЗАТРАТ: справочник цен AWS Route53 (us-east-1, 2024)
  # Источник: https://aws.amazon.com/route53/pricing/
  # ------------------------------------------------------------------
  route53_pricing = {
    hosted_zone_monthly        = 0.50   # за первую зону
    hosted_zone_additional     = 0.10   # каждая дополнительная
    query_standard_per_million = 0.40   # стандартные запросы
    query_latency_per_million  = 0.60   # latency-based routing
    query_geo_per_million      = 0.70   # geolocation routing
    health_check_monthly       = 0.50   # basic health check
    health_check_https_monthly = 1.00   # HTTPS health check
    dnssec_monthly             = 1.00   # DNSSEC signing
    query_logging_per_gb       = 0.50   # CloudWatch Logs ingestion
  }

  # ------------------------------------------------------------------
  # Прогнозируемое потребление (имитация)
  # ------------------------------------------------------------------
  usage_forecast = {
    zones_count                = 1
    monthly_queries_millions   = 250
    latency_queries_millions   = 40
    geo_queries_millions       = 15
    health_checks_basic        = 3
    health_checks_https        = 2
    dnssec_enabled             = var.enable_dnssec
    query_log_gb_per_month     = 12
  }

  # ------------------------------------------------------------------
  # Детализированный расчёт затрат (построчный — для имитации объёма)
  # ------------------------------------------------------------------
  cost_breakdown = {
    # --- Hosted Zone ---
    hosted_zone_base = {
      description = "Route53 Hosted Zone: ${var.domain_name}"
      quantity    = local.usage_forecast.zones_count
      unit_price  = local.route53_pricing.hosted_zone_monthly
      monthly_usd = local.usage_forecast.zones_count * local.route53_pricing.hosted_zone_monthly
    }

    # --- Queries: Standard ---
    queries_standard = {
      description = "Standard DNS queries"
      quantity    = local.usage_forecast.monthly_queries_millions
      unit_price  = local.route53_pricing.query_standard_per_million
      monthly_usd = local.usage_forecast.monthly_queries_millions * local.route53_pricing.query_standard_per_million
    }

    # --- Queries: Latency-based ---
    queries_latency = {
      description = "Latency-based routing queries"
      quantity    = local.usage_forecast.latency_queries_millions
      unit_price  = local.route53_pricing.query_latency_per_million
      monthly_usd = local.usage_forecast.latency_queries_millions * local.route53_pricing.query_latency_per_million
    }

    # --- Queries: Geolocation ---
    queries_geo = {
      description = "Geolocation routing queries"
      quantity    = local.usage_forecast.geo_queries_millions
      unit_price  = local.route53_pricing.query_geo_per_million
      monthly_usd = local.usage_forecast.geo_queries_millions * local.route53_pricing.query_geo_per_million
    }

    # --- Health checks ---
    health_checks_basic = {
      description = "Basic health checks (TCP/HTTP)"
      quantity    = local.usage_forecast.health_checks_basic
      unit_price  = local.route53_pricing.health_check_monthly
      monthly_usd = local.usage_forecast.health_checks_basic * local.route53_pricing.health_check_monthly
    }

    health_checks_https = {
      description = "HTTPS health checks"
      quantity    = local.usage_forecast.health_checks_https
      unit_price  = local.route53_pricing.health_check_https_monthly
      monthly_usd = local.usage_forecast.health_checks_https * local.route53_pricing.health_check_https_monthly
    }

    # --- DNSSEC ---
    dnssec = {
      description = "DNSSEC signing"
      quantity    = local.usage_forecast.dnssec_enabled ? 1 : 0
      unit_price  = local.route53_pricing.dnssec_monthly
      monthly_usd = local.usage_forecast.dnssec_enabled ? local.route53_pricing.dnssec_monthly : 0
    }

    # --- Query logging ---
    query_logging = {
      description = "Query logging to CloudWatch Logs"
      quantity    = var.create_query_log ? local.usage_forecast.query_log_gb_per_month : 0
      unit_price  = local.route53_pricing.query_logging_per_gb
      monthly_usd = var.create_query_log ? local.usage_forecast.query_log_gb_per_month * local.route53_pricing.query_logging_per_gb : 0
    }
  }

  # ------------------------------------------------------------------
  # Итоговые суммы (имитация)
  # ------------------------------------------------------------------
  cost_monthly_total = sum([
    for k, v in local.cost_breakdown : v.monthly_usd
  ])

  cost_yearly_total = local.cost_monthly_total * 12

  cost_currency = "USD"
}