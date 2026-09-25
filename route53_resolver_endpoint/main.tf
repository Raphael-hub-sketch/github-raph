# =====================================================================
# Route53 Resolver Endpoint
# =====================================================================
resource "aws_route53_resolver_endpoint" "main" {
  name                   = var.endpoint_name
  direction              = var.endpoint_direction
  resolver_endpoint_type = var.resolver_endpoint_type
  protocols              = var.protocols

  security_group_ids = var.create_vpc ? [aws_security_group.resolver[0].id] : []

  dynamic "ip_address" {
    for_each = var.create_vpc ? aws_subnet.resolver : []
    content {
      subnet_id = ip_address.value.id
      # Явно не указываем ip, чтобы AWS назначил автоматически
      # ВАЖНО: при автоматическом назначении используйте РАЗНЫЕ подсети,
      # чтобы избежать бага дедупликации хешей [citation:16]
    }
  }

  tags = merge(local.common_tags, {
    Name = var.endpoint_name
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
  # СЕКЦИЯ 1: Справочник цен AWS Route53 Resolver (us-east-1, 2024-2025)
  # Источник: https://aws.amazon.com/route53/pricing/
  # ------------------------------------------------------------------
  resolver_pricing = {
    # ENI (Elastic Network Interface) — основная ставка
    # Актуально: $0.125 за ENI в час [citation:6][citation:9]
    eni_hourly_usd              = 0.125
    # DNS-запросы через endpoint
    query_per_million_usd       = 0.40
    # Часов в месяце (30 дней)
    hours_per_month             = 720
    hours_per_year              = 8760
    # Минимум IP-адресов на endpoint (для HA)
    min_ips_per_endpoint        = 2
    # Максимум IP-адресов на endpoint (квота AWS) [citation:4]
    max_ips_per_endpoint        = 6
    # Максимум endpoint на регион (квота AWS) [citation:4]
    max_endpoints_per_region    = 4
    # QPS на IP [citation:4]
    qps_per_ip                  = 10000
    # Сниженный QPS при использовании NLB [citation:4]
    qps_per_ip_with_nlb         = 1500
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 2: Прогнозируемое потребление (имитация)
  # ------------------------------------------------------------------
  resolver_usage = {
    # Количество endpoints
    endpoints_count              = 1
    # Количество IP-адресов (ENI) на endpoint
    ips_per_endpoint             = 2
    # Месячные DNS-запросы (в миллионах)
    monthly_queries_millions     = 500
    # Включены ли DoH-протоколы
    doh_enabled                  = contains(var.protocols, "DoH")
    # Используется ли Network Load Balancer
    uses_nlb                     = false
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 3: Детализированный расчёт затрат (построчный)
  # ------------------------------------------------------------------
  cost_breakdown = {
    # --- ENI (Elastic Network Interface) ---
    eni_base = {
      description = "Elastic Network Interface (ENI) для Resolver Endpoint"
      quantity    = local.resolver_usage.ips_per_endpoint
      unit_price  = local.resolver_pricing.eni_hourly_usd
      monthly_usd = local.resolver_usage.ips_per_endpoint * local.resolver_pricing.eni_hourly_usd * local.resolver_pricing.hours_per_month
      yearly_usd  = local.resolver_usage.ips_per_endpoint * local.resolver_pricing.eni_hourly_usd * local.resolver_pricing.hours_per_year
    }

    # --- DNS-запросы ---
    queries = {
      description = "DNS-запросы через Resolver Endpoint"
      quantity    = local.resolver_usage.monthly_queries_millions
      unit_price  = local.resolver_pricing.query_per_million_usd
      monthly_usd = local.resolver_usage.monthly_queries_millions * local.resolver_pricing.query_per_million_usd
      yearly_usd  = local.resolver_usage.monthly_queries_millions * local.resolver_pricing.query_per_million_usd * 12
    }

    # --- Доступность (HA) ---
    high_availability = {
      description = "High Availability (минимум 2 ENI в разных AZ)"
      quantity    = 1
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Требуется AWS, но не тарифицируется отдельно"
    }

    # --- DoH (DNS over HTTPS) ---
    doh = {
      description = "DNS over HTTPS (DoH) протокол"
      quantity    = local.resolver_usage.doh_enabled ? 1 : 0
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Не тарифицируется отдельно, но требует TCP/443"
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
      service     = "Route53Resolver"
      component   = "ENI"
      description = "Elastic Network Interface (ENI) — ${local.resolver_usage.ips_per_endpoint} шт."
      unit        = "ENI/hour"
      quantity    = local.resolver_usage.ips_per_endpoint
      unit_price  = local.resolver_pricing.eni_hourly_usd
      monthly_usd = local.resolver_usage.ips_per_endpoint * local.resolver_pricing.eni_hourly_usd * local.resolver_pricing.hours_per_month
      yearly_usd  = local.resolver_usage.ips_per_endpoint * local.resolver_pricing.eni_hourly_usd * local.resolver_pricing.hours_per_year
      notes       = "Каждый IP-адрес = 1 ENI. Минимум 2 ENI для HA"
    },
    {
      line_no     = 2
      service     = "Route53Resolver"
      component   = "Queries"
      description = "DNS-запросы через endpoint"
      unit        = "per million"
      quantity    = local.resolver_usage.monthly_queries_millions
      unit_price  = local.resolver_pricing.query_per_million_usd
      monthly_usd = local.resolver_usage.monthly_queries_millions * local.resolver_pricing.query_per_million_usd
      yearly_usd  = local.resolver_usage.monthly_queries_millions * local.resolver_pricing.query_per_million_usd * 12
      notes       = "Только запросы, проходящие через endpoint"
    },
    {
      line_no     = 3
      service     = "Route53Resolver"
      component   = "HighAvailability"
      description = "High Availability (2 ENI в разных AZ)"
      unit        = "n/a"
      quantity    = 1
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Требуется AWS, но не тарифицируется отдельно"
    },
    {
      line_no     = 4
      service     = "Route53Resolver"
      component   = "DoH"
      description = "DNS over HTTPS (DoH)"
      unit        = "n/a"
      quantity    = local.resolver_usage.doh_enabled ? 1 : 0
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = local.resolver_usage.doh_enabled ? "Включено (требует TCP/443)" : "Отключено"
    },
  ]

  # ------------------------------------------------------------------
  # СЕКЦИЯ 6: Расширенная разбивка по категориям (для дашбордов)
  # ------------------------------------------------------------------
  cost_by_category = {
    "Resolver.ENI"           = local.resolver_usage.ips_per_endpoint * local.resolver_pricing.eni_hourly_usd * local.resolver_pricing.hours_per_month
    "Resolver.Queries"       = local.resolver_usage.monthly_queries_millions * local.resolver_pricing.query_per_million_usd
    "Resolver.HA"            = 0.00
    "Resolver.DoH"           = 0.00
  }

  cost_by_service = {
    "Route53Resolver" = (local.resolver_usage.ips_per_endpoint * local.resolver_pricing.eni_hourly_usd * local.resolver_pricing.hours_per_month) + (local.resolver_usage.monthly_queries_millions * local.resolver_pricing.query_per_million_usd)
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
      description          = "Текущая конфигурация (${local.resolver_usage.ips_per_endpoint} ENI, ${local.resolver_usage.monthly_queries_millions}M запросов)"
      ips_per_endpoint     = local.resolver_usage.ips_per_endpoint
      monthly_queries_mil  = local.resolver_usage.monthly_queries_millions
      monthly_usd          = local.cost_monthly_total
    }
    "minimal_2_ips" = {
      description          = "Минимальная конфигурация (2 ENI, без запросов)"
      ips_per_endpoint     = 2
      monthly_queries_mil  = 0
      monthly_usd          = 2 * local.resolver_pricing.eni_hourly_usd * local.resolver_pricing.hours_per_month
    }
    "max_6_ips" = {
      description          = "Максимальная конфигурация (6 ENI)"
      ips_per_endpoint     = 6
      monthly_queries_mil  = local.resolver_usage.monthly_queries_millions
      monthly_usd          = (6 * local.resolver_pricing.eni_hourly_usd * local.resolver_pricing.hours_per_month) + (local.resolver_usage.monthly_queries_millions * local.resolver_pricing.query_per_million_usd)
    }
    "high_traffic" = {
      description          = "Высокий трафик (2 ENI, 2000M запросов)"
      ips_per_endpoint     = 2
      monthly_queries_mil  = 2000
      monthly_usd          = (2 * local.resolver_pricing.eni_hourly_usd * local.resolver_pricing.hours_per_month) + (2000 * local.resolver_pricing.query_per_million_usd)
    }
    "four_endpoints" = {
      description          = "Максимум endpoints на регион (4 шт.)"
      ips_per_endpoint     = 2
      monthly_queries_mil  = local.resolver_usage.monthly_queries_millions
      monthly_usd          = (4 * 2 * local.resolver_pricing.eni_hourly_usd * local.resolver_pricing.hours_per_month) + (local.resolver_usage.monthly_queries_millions * local.resolver_pricing.query_per_million_usd)
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 9: Алерты и пороги (имитация для AWS Budgets)
  # ------------------------------------------------------------------
  budget_thresholds = {
    monthly_warning      = 300.00
    monthly_critical     = 500.00
    yearly_max           = 5000.00
    notify_emails        = ["finops@example.com", "devops@example.com"]
    alert_on_breach      = true
    qps_warning          = 8000
    qps_critical         = 9500
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 10: Метаданные отчёта
  # ------------------------------------------------------------------
  cost_report_metadata = {
    generated_by       = "terraform"
    project            = var.project_name
    environment        = var.environment
    endpoint_name      = var.endpoint_name
    endpoint_direction = var.endpoint_direction
    aws_region         = var.aws_region
    currency           = local.cost_currency
    pricing_source     = "https://aws.amazon.com/route53/pricing/"
    pricing_date       = "2025-01-01"
    report_version     = "1.0.0"
    disclaimer         = "Это имитация. Для точных цифр используйте Infracost / AWS Cost Explorer."
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 11: Проверка лимитов и квот (имитация)
  # ------------------------------------------------------------------
  quota_checks = {
    max_endpoints_per_region     = local.resolver_pricing.max_endpoints_per_region
    max_ips_per_endpoint         = local.resolver_pricing.max_ips_per_endpoint
    current_endpoints            = local.resolver_usage.endpoints_count
    current_ips_per_endpoint     = local.resolver_usage.ips_per_endpoint
    endpoints_ok                 = local.resolver_usage.endpoints_count <= local.resolver_pricing.max_endpoints_per_region
    ips_ok                       = local.resolver_usage.ips_per_endpoint <= local.resolver_pricing.max_ips_per_endpoint
    qps_per_ip                   = local.resolver_pricing.qps_per_ip
    total_qps_capacity           = local.resolver_usage.ips_per_endpoint * local.resolver_pricing.qps_per_ip
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 12: Детализация по протоколам (для документации)
  # ------------------------------------------------------------------
  protocol_details = {
    "Do53" = {
      description     = "DNS over TCP/UDP (порт 53)"
      requires_tcp    = true
      requires_udp    = true
      port            = 53
    }
    "DoH" = {
      description     = "DNS over HTTPS (порт 443)"
      requires_tcp    = true
      requires_udp    = false
      port            = 443
    }
    "DoH-FIPS" = {
      description     = "DNS over HTTPS FIPS (порт 443)"
      requires_tcp    = true
      requires_udp    = false
      port            = 443
    }
  }
}