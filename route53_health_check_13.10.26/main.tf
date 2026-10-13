# =====================================================================
# Route53 Health Check (основной ресурс)
# =====================================================================
resource "aws_route53_health_check" "main" {
  fqdn              = var.fqdn
  port              = var.port
  type              = var.health_check_type
  resource_path     = var.resource_path
  failure_threshold = var.failure_threshold
  request_interval  = var.request_interval
  search_string     = var.health_check_type == "HTTP_STR_MATCH" || var.health_check_type == "HTTPS_STR_MATCH" ? var.search_string : null
  measure_latency   = var.measure_latency
  invert_healthcheck = var.invert_healthcheck
  disabled          = var.disabled

  tags = merge(local.common_tags, {
    Name = var.health_check_name
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
  # СЕКЦИЯ 1: Справочник цен AWS Route53 Health Checks
  # Источник: https://aws.amazon.com/route53/pricing/ 
  # ------------------------------------------------------------------
  health_check_pricing = {
    # Базовые ставки
    aws_endpoint_per_month_usd      = 0.50   # $0.50 для AWS endpoints [citation:1][citation:6]
    non_aws_endpoint_per_month_usd  = 0.75   # $0.75 для non-AWS endpoints [citation:6][citation:13]

    # Free tier
    free_aws_checks                 = 50     # первые 50 AWS checks бесплатно [citation:16]

    # Опции (дополнительно к базовой ставке)
    https_option_usd                = 0.50   # HTTPS мониторинг [citation:6]
    string_match_option_usd         = 0.50   # String matching [citation:6]
    fast_interval_option_usd        = 1.00   # Fast interval (10s) [citation:6]
    latency_measure_option_usd      = 1.00   # Latency measurement [citation:6]

    # Non-AWS опции дороже
    non_aws_https_option_usd        = 2.00   # HTTPS для non-AWS [citation:16]
    non_aws_string_option_usd       = 2.00   # String match для non-AWS [citation:16]

    # Часов в месяце (30 дней)
    hours_per_month                 = 730
    hours_per_year                  = 8760
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 2: Прогнозируемое потребление (имитация)
  # ------------------------------------------------------------------
  health_check_usage = {
    # Количество health checks
    checks_count                    = 1

    # Опции, включённые в этом health check
    https_enabled                   = var.health_check_type == "HTTPS" || var.health_check_type == "HTTPS_STR_MATCH"
    string_match_enabled            = var.health_check_type == "HTTP_STR_MATCH" || var.health_check_type == "HTTPS_STR_MATCH"
    fast_interval_enabled           = var.request_interval == 10
    latency_measure_enabled         = var.measure_latency

    # Является ли endpoint AWS-ресурсом
    is_aws_endpoint                 = var.is_aws_endpoint

    # CloudWatch Alarm
    cloudwatch_alarm_enabled        = var.create_cloudwatch_alarm
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 3: Детализированный расчёт затрат (построчный)
  # ------------------------------------------------------------------
  cost_breakdown = {
    # --- Базовая ставка за health check ---
    base_check = {
      description = "Health check базовая ставка (${local.health_check_usage.is_aws_endpoint ? "AWS" : "Non-AWS"} endpoint)"
      quantity    = local.health_check_usage.checks_count
      unit_price  = local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.aws_endpoint_per_month_usd : local.health_check_pricing.non_aws_endpoint_per_month_usd
      monthly_usd = local.health_check_usage.checks_count * (local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.aws_endpoint_per_month_usd : local.health_check_pricing.non_aws_endpoint_per_month_usd)
      yearly_usd  = local.health_check_usage.checks_count * (local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.aws_endpoint_per_month_usd : local.health_check_pricing.non_aws_endpoint_per_month_usd) * 12
      notes       = local.health_check_usage.is_aws_endpoint ? "Free tier: 50 checks/month [citation:16]" : "No free tier for non-AWS [citation:16]"
    }

    # --- HTTPS опция ---
    https_option = {
      description = "HTTPS опция мониторинга"
      quantity    = local.health_check_usage.https_enabled ? 1 : 0
      unit_price  = local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.https_option_usd : local.health_check_pricing.non_aws_https_option_usd
      monthly_usd = local.health_check_usage.https_enabled ? (local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.https_option_usd : local.health_check_pricing.non_aws_https_option_usd) : 0
      yearly_usd  = local.health_check_usage.https_enabled ? (local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.https_option_usd : local.health_check_pricing.non_aws_https_option_usd) * 12 : 0
      notes       = "Non-AWS HTTPS дороже ($2.00) [citation:16]"
    }

    # --- String matching опция ---
    string_match_option = {
      description = "String matching опция"
      quantity    = local.health_check_usage.string_match_enabled ? 1 : 0
      unit_price  = local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.string_match_option_usd : local.health_check_pricing.non_aws_string_option_usd
      monthly_usd = local.health_check_usage.string_match_enabled ? (local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.string_match_option_usd : local.health_check_pricing.non_aws_string_option_usd) : 0
      yearly_usd  = local.health_check_usage.string_match_enabled ? (local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.string_match_option_usd : local.health_check_pricing.non_aws_string_option_usd) * 12 : 0
      notes       = "Проверка содержимого ответа"
    }

    # --- Fast interval опция ---
    fast_interval_option = {
      description = "Fast interval (10s вместо 30s)"
      quantity    = local.health_check_usage.fast_interval_enabled ? 1 : 0
      unit_price  = local.health_check_pricing.fast_interval_option_usd
      monthly_usd = local.health_check_usage.fast_interval_enabled ? local.health_check_pricing.fast_interval_option_usd : 0
      yearly_usd  = local.health_check_usage.fast_interval_enabled ? local.health_check_pricing.fast_interval_option_usd * 12 : 0
      notes       = "Считается как 3 health checks [citation:16]"
    }

    # --- Latency measurement опция ---
    latency_measure_option = {
      description = "Latency measurement"
      quantity    = local.health_check_usage.latency_measure_enabled ? 1 : 0
      unit_price  = local.health_check_pricing.latency_measure_option_usd
      monthly_usd = local.health_check_usage.latency_measure_enabled ? local.health_check_pricing.latency_measure_option_usd : 0
      yearly_usd  = local.health_check_usage.latency_measure_enabled ? local.health_check_pricing.latency_measure_option_usd * 12 : 0
      notes       = "Измерение задержки между регионами"
    }

    # --- CloudWatch Alarm (вспомогательный ресурс) ---
    cloudwatch_alarm = {
      description = "CloudWatch Alarm (вспомогательный)"
      quantity    = local.health_check_usage.cloudwatch_alarm_enabled ? 1 : 0
      unit_price  = 0.10
      monthly_usd = local.health_check_usage.cloudwatch_alarm_enabled ? 0.10 : 0
      yearly_usd  = local.health_check_usage.cloudwatch_alarm_enabled ? 0.10 * 12 : 0
      notes       = "Тарифицируется CloudWatch, не Route53"
    }

    # --- Free tier discount (только для AWS endpoints) ---
    free_tier_discount = {
      description = "Free tier discount (первые 50 AWS checks)"
      quantity    = local.health_check_usage.is_aws_endpoint ? min(local.health_check_usage.checks_count, local.health_check_pricing.free_aws_checks) : 0
      unit_price  = -local.health_check_pricing.aws_endpoint_per_month_usd
      monthly_usd = local.health_check_usage.is_aws_endpoint ? -1 * min(local.health_check_usage.checks_count, local.health_check_pricing.free_aws_checks) * local.health_check_pricing.aws_endpoint_per_month_usd : 0
      yearly_usd  = local.health_check_usage.is_aws_endpoint ? -1 * min(local.health_check_usage.checks_count, local.health_check_pricing.free_aws_checks) * local.health_check_pricing.aws_endpoint_per_month_usd * 12 : 0
      notes       = "Применяется только для AWS endpoints [citation:16]"
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 4: Итоговые суммы (имитация)
  # ------------------------------------------------------------------
  cost_monthly_total = max(0, sum([
    for k, v in local.cost_breakdown : v.monthly_usd
  ]))

  cost_yearly_total = max(0, sum([
    for k, v in local.cost_breakdown : v.yearly_usd
  ]))

  cost_currency = "USD"

  # ------------------------------------------------------------------
  # СЕКЦИЯ 5: Построчная детализация по каждому элементу затрат
  # ------------------------------------------------------------------
  cost_line_items = [
    {
      line_no     = 1
      service     = "Route53"
      component   = "HealthCheck.Base"
      description = "Health check базовая ставка"
      unit        = "per check/month"
      quantity    = local.health_check_usage.checks_count
      unit_price  = local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.aws_endpoint_per_month_usd : local.health_check_pricing.non_aws_endpoint_per_month_usd
      monthly_usd = local.health_check_usage.checks_count * (local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.aws_endpoint_per_month_usd : local.health_check_pricing.non_aws_endpoint_per_month_usd)
      yearly_usd  = local.health_check_usage.checks_count * (local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.aws_endpoint_per_month_usd : local.health_check_pricing.non_aws_endpoint_per_month_usd) * 12
      notes       = "AWS endpoint = $0.50, Non-AWS = $0.75 [citation:6]"
    },
    {
      line_no     = 2
      service     = "Route53"
      component   = "HealthCheck.HTTPS"
      description = "HTTPS опция"
      unit        = "per check/month"
      quantity    = local.health_check_usage.https_enabled ? 1 : 0
      unit_price  = local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.https_option_usd : local.health_check_pricing.non_aws_https_option_usd
      monthly_usd = local.health_check_usage.https_enabled ? (local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.https_option_usd : local.health_check_pricing.non_aws_https_option_usd) : 0
      yearly_usd  = local.health_check_usage.https_enabled ? (local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.https_option_usd : local.health_check_pricing.non_aws_https_option_usd) * 12 : 0
      notes       = "Non-AWS HTTPS = $2.00 [citation:16]"
    },
    {
      line_no     = 3
      service     = "Route53"
      component   = "HealthCheck.StringMatch"
      description = "String matching опция"
      unit        = "per check/month"
      quantity    = local.health_check_usage.string_match_enabled ? 1 : 0
      unit_price  = local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.string_match_option_usd : local.health_check_pricing.non_aws_string_option_usd
      monthly_usd = local.health_check_usage.string_match_enabled ? (local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.string_match_option_usd : local.health_check_pricing.non_aws_string_option_usd) : 0
      yearly_usd  = local.health_check_usage.string_match_enabled ? (local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.string_match_option_usd : local.health_check_pricing.non_aws_string_option_usd) * 12 : 0
      notes       = "Проверка содержимого ответа"
    },
    {
      line_no     = 4
      service     = "Route53"
      component   = "HealthCheck.FastInterval"
      description = "Fast interval (10s)"
      unit        = "per check/month"
      quantity    = local.health_check_usage.fast_interval_enabled ? 1 : 0
      unit_price  = local.health_check_pricing.fast_interval_option_usd
      monthly_usd = local.health_check_usage.fast_interval_enabled ? local.health_check_pricing.fast_interval_option_usd : 0
      yearly_usd  = local.health_check_usage.fast_interval_enabled ? local.health_check_pricing.fast_interval_option_usd * 12 : 0
      notes       = "Считается как 3 health checks [citation:16]"
    },
    {
      line_no     = 5
      service     = "Route53"
      component   = "HealthCheck.Latency"
      description = "Latency measurement"
      unit        = "per check/month"
      quantity    = local.health_check_usage.latency_measure_enabled ? 1 : 0
      unit_price  = local.health_check_pricing.latency_measure_option_usd
      monthly_usd = local.health_check_usage.latency_measure_enabled ? local.health_check_pricing.latency_measure_option_usd : 0
      yearly_usd  = local.health_check_usage.latency_measure_enabled ? local.health_check_pricing.latency_measure_option_usd * 12 : 0
      notes       = "Измерение задержки между регионами"
    },
    {
      line_no     = 6
      service     = "CloudWatch"
      component   = "Alarm"
      description = "CloudWatch Alarm"
      unit        = "per alarm/month"
      quantity    = local.health_check_usage.cloudwatch_alarm_enabled ? 1 : 0
      unit_price  = 0.10
      monthly_usd = local.health_check_usage.cloudwatch_alarm_enabled ? 0.10 : 0
      yearly_usd  = local.health_check_usage.cloudwatch_alarm_enabled ? 0.10 * 12 : 0
      notes       = "Тарифицируется CloudWatch [citation:17]"
    },
    {
      line_no     = 7
      service     = "Route53"
      component   = "FreeTierDiscount"
      description = "Free tier discount (первые 50 AWS checks)"
      unit        = "per check/month"
      quantity    = local.health_check_usage.is_aws_endpoint ? min(local.health_check_usage.checks_count, local.health_check_pricing.free_aws_checks) : 0
      unit_price  = -local.health_check_pricing.aws_endpoint_per_month_usd
      monthly_usd = local.health_check_usage.is_aws_endpoint ? -1 * min(local.health_check_usage.checks_count, local.health_check_pricing.free_aws_checks) * local.health_check_pricing.aws_endpoint_per_month_usd : 0
      yearly_usd  = local.health_check_usage.is_aws_endpoint ? -1 * min(local.health_check_usage.checks_count, local.health_check_pricing.free_aws_checks) * local.health_check_pricing.aws_endpoint_per_month_usd * 12 : 0
      notes       = "Применяется только для AWS endpoints [citation:16]"
    },
  ]

  # ------------------------------------------------------------------
  # СЕКЦИЯ 6: Расширенная разбивка по категориям (для дашбордов)
  # ------------------------------------------------------------------
  cost_by_category = {
    "HealthCheck.Base"        = local.health_check_usage.checks_count * (local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.aws_endpoint_per_month_usd : local.health_check_pricing.non_aws_endpoint_per_month_usd)
    "HealthCheck.Options"     = (local.health_check_usage.https_enabled ? (local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.https_option_usd : local.health_check_pricing.non_aws_https_option_usd) : 0) + (local.health_check_usage.string_match_enabled ? (local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.string_match_option_usd : local.health_check_pricing.non_aws_string_option_usd) : 0) + (local.health_check_usage.fast_interval_enabled ? local.health_check_pricing.fast_interval_option_usd : 0) + (local.health_check_usage.latency_measure_enabled ? local.health_check_pricing.latency_measure_option_usd : 0)
    "CloudWatch.Alarm"        = local.health_check_usage.cloudwatch_alarm_enabled ? 0.10 : 0
    "FreeTierDiscount"        = local.health_check_usage.is_aws_endpoint ? -1 * min(local.health_check_usage.checks_count, local.health_check_pricing.free_aws_checks) * local.health_check_pricing.aws_endpoint_per_month_usd : 0
  }

  cost_by_service = {
    "Route53"   = max(0, (local.health_check_usage.checks_count * (local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.aws_endpoint_per_month_usd : local.health_check_pricing.non_aws_endpoint_per_month_usd)) + (local.health_check_usage.https_enabled ? (local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.https_option_usd : local.health_check_pricing.non_aws_https_option_usd) : 0) + (local.health_check_usage.string_match_enabled ? (local.health_check_usage.is_aws_endpoint ? local.health_check_pricing.string_match_option_usd : local.health_check_pricing.non_aws_string_option_usd) : 0) + (local.health_check_usage.fast_interval_enabled ? local.health_check_pricing.fast_interval_option_usd : 0) + (local.health_check_usage.latency_measure_enabled ? local.health_check_pricing.latency_measure_option_usd : 0) + (local.health_check_usage.is_aws_endpoint ? -1 * min(local.health_check_usage.checks_count, local.health_check_pricing.free_aws_checks) * local.health_check_pricing.aws_endpoint_per_month_usd : 0))
    "CloudWatch" = local.health_check_usage.cloudwatch_alarm_enabled ? 0.10 : 0
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
      growth_rate  = 0.02 # 2% ежемесячный рост
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
      description          = "Текущая конфигурация (${var.health_check_type}, ${local.health_check_usage.is_aws_endpoint ? "AWS" : "Non-AWS"})"
      check_type           = var.health_check_type
      is_aws               = local.health_check_usage.is_aws_endpoint
      monthly_usd          = local.cost_monthly_total
    }
    "aws_basic" = {
      description          = "AWS endpoint, базовый HTTP check (в пределах free tier)"
      check_type           = "HTTP"
      is_aws               = true
      monthly_usd          = 0.00
    }
    "aws_https" = {
      description          = "AWS endpoint, HTTPS check"
      check_type           = "HTTPS"
      is_aws               = true
      monthly_usd          = 0.00  # free tier покрывает
    }
    "aws_https_string" = {
      description          = "AWS endpoint, HTTPS + string matching"
      check_type           = "HTTPS_STR_MATCH"
      is_aws               = true
      monthly_usd          = local.health_check_pricing.string_match_option_usd  # только опция, база в free tier
    }
    "aws_https_fast" = {
      description          = "AWS endpoint, HTTPS + fast interval"
      check_type           = "HTTPS"
      is_aws               = true
      monthly_usd          = local.health_check_pricing.https_option_usd + local.health_check_pricing.fast_interval_option_usd
    }
    "non_aws_https_string" = {
      description          = "Non-AWS endpoint, HTTPS + string matching"
      check_type           = "HTTPS_STR_MATCH"
      is_aws               = false
      monthly_usd          = local.health_check_pricing.non_aws_endpoint_per_month_usd + local.health_check_pricing.non_aws_https_option_usd + local.health_check_pricing.non_aws_string_option_usd
    }
    "non_aws_all_options" = {
      description          = "Non-AWS endpoint, все опции"
      check_type           = "HTTPS_STR_MATCH"
      is_aws               = false
      monthly_usd          = local.health_check_pricing.non_aws_endpoint_per_month_usd + local.health_check_pricing.non_aws_https_option_usd + local.health_check_pricing.non_aws_string_option_usd + local.health_check_pricing.fast_interval_option_usd + local.health_check_pricing.latency_measure_option_usd
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 9: Алерты и пороги (имитация для AWS Budgets)
  # ------------------------------------------------------------------
  budget_thresholds = {
    monthly_warning      = 5.00
    monthly_critical     = 15.00
    yearly_max           = 100.00
    notify_emails        = ["finops@example.com", "devops@example.com"]
    alert_on_breach      = true
    checks_warning       = 100
    checks_crit          = 200
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 10: Метаданные отчёта
  # ------------------------------------------------------------------
  cost_report_metadata = {
    generated_by       = "terraform"
    project            = var.project_name
    environment        = var.environment
    health_check_name  = var.health_check_name
    health_check_type  = var.health_check_type
    fqdn               = var.fqdn
    is_aws_endpoint    = local.health_check_usage.is_aws_endpoint
    aws_region         = var.aws_region
    currency           = local.cost_currency
    pricing_source     = "https://aws.amazon.com/route53/pricing/"
    pricing_date       = "2025-01-01"
    report_version     = "1.0.0"
    disclaimer         = "Это имитация. Для точных цифр используйте Infracost / AWS Cost Explorer."
    billing_note       = "Health checks: $0.50 AWS / $0.75 Non-AWS. First 50 AWS checks free [citation:16]"
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 11: Проверка лимитов и квот (имитация)
  # ------------------------------------------------------------------
  quota_checks = {
    max_health_checks              = 200
    free_tier_aws_checks           = 50
    max_failure_threshold          = 10
    min_failure_threshold          = 1
    valid_intervals                = [10, 30]
    current_checks                 = local.health_check_usage.checks_count
    current_failure_threshold      = var.failure_threshold
    current_interval               = var.request_interval
    checks_ok                      = local.health_check_usage.checks_count <= 200
    failure_threshold_ok           = var.failure_threshold >= 1 && var.failure_threshold <= 10
    interval_ok                    = contains([10, 30], var.request_interval)
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 12: Детализация по типам health checks (для документации)
  # ------------------------------------------------------------------
  health_check_type_details = {
    "HTTP" = {
      description     = "HTTP status code check"
      base_price_aws  = "$0.50"
      base_price_non_aws = "$0.75"
      options         = "HTTPS, fast interval, latency"
    }
    "HTTPS" = {
      description     = "HTTPS status code check (SSL/TLS)"
      base_price_aws  = "$0.50"
      base_price_non_aws = "$0.75"
      options         = "HTTPS option (+$0.50 AWS, +$2.00 non-AWS), fast interval, latency"
    }
    "TCP" = {
      description     = "TCP connection check"
      base_price_aws  = "$0.50"
      base_price_non_aws = "$0.75"
      options         = "fast interval, latency"
    }
    "HTTP_STR_MATCH" = {
      description     = "HTTP + string matching"
      base_price_aws  = "$0.50"
      base_price_non_aws = "$0.75"
      options         = "String match (+$0.50 AWS, +$2.00 non-AWS)"
    }
    "HTTPS_STR_MATCH" = {
      description     = "HTTPS + string matching"
      base_price_aws  = "$0.50"
      base_price_non_aws = "$0.75"
      options         = "HTTPS + string match"
    }
    "CALCULATED" = {
      description     = "Aggregate check based on child checks"
      base_price_aws  = "Free (only children billed)"
      base_price_non_aws = "Free (only children billed)"
      options         = "child_health_threshold, child_healthchecks"
    }
  }
}