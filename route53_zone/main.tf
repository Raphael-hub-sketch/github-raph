# =====================================================================
# Route53 Hosted Zone
# =====================================================================
resource "aws_route53_zone" "main" {
  name          = var.domain_name
  comment       = "Managed by Terraform. Env: ${var.environment}. Project: ${var.project_name}."
  force_destroy = var.environment != "prod"

  tags = merge(local.common_tags, {
    Name        = var.domain_name
    ZoneType    = "public"
    MonthlyCost = format("%.2f %s", local.cost_monthly_total, local.cost_currency)
  })

  # DNSSEC — опционально
  dynamic "dnssec_config" {
    for_each = var.enable_dnssec ? [1] : []
    content {
      signing_enabled = true
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}

# =====================================================================
# CloudWatch Log Group для query logging (имитация отдельного ресурса)
# =====================================================================
resource "aws_cloudwatch_log_group" "dns_query_log" {
  count             = var.create_query_log ? 1 : 0
  name              = "/aws/route53/${var.domain_name}"
  retention_in_days = var.query_log_retention_days

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-route53-query-log"
  })
}

# =====================================================================
# Query Logging Config
# =====================================================================
resource "aws_route53_query_log" "main" {
  count = var.create_query_log ? 1 : 0

  depends_on = [
    aws_cloudwatch_log_group.dns_query_log,
    aws_route53_zone.main
  ]

  cloudwatch_log_group_arn = aws_cloudwatch_log_group.dns_query_log[0].arn
  zone_id                  = aws_route53_zone.main.zone_id
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
  # СЕКЦИЯ 1: Построчная детализация по каждому элементу затрат
  # ------------------------------------------------------------------
  cost_line_items = [
    {
      line_no     = 1
      service     = "Route53"
      component   = "HostedZone"
      description = "Публичная hosted zone для ${var.domain_name}"
      unit        = "zone/month"
      quantity    = 1
      unit_price  = 0.50
      monthly_usd = 0.50
      yearly_usd  = 6.00
      notes       = "Первая зона в аккаунте — $0.50/мес"
    },
    {
      line_no     = 2
      service     = "Route53"
      component   = "Queries.Standard"
      description = "Стандартные DNS-запросы (первые 1 млрд/мес)"
      unit        = "per million"
      quantity    = 250
      unit_price  = 0.40
      monthly_usd = 100.00
      yearly_usd  = 1200.00
      notes       = "Оценка трафика на основе исторических данных"
    },
    {
      line_no     = 3
      service     = "Route53"
      component   = "Queries.Latency"
      description = "Запросы с latency-based routing"
      unit        = "per million"
      quantity    = 40
      unit_price  = 0.60
      monthly_usd = 24.00
      yearly_usd  = 288.00
      notes       = "Используется для multi-region failover"
    },
    {
      line_no     = 4
      service     = "Route53"
      component   = "Queries.Geo"
      description = "Запросы с geolocation routing"
      unit        = "per million"
      quantity    = 15
      unit_price  = 0.70
      monthly_usd = 10.50
      yearly_usd  = 126.00
      notes       = "Гео-маршрутизация для EU/US"
    },
    {
      line_no     = 5
      service     = "Route53"
      component   = "HealthCheck.Basic"
      description = "Базовые health check (TCP/HTTP)"
      unit        = "check/month"
      quantity    = 3
      unit_price  = 0.50
      monthly_usd = 1.50
      yearly_usd  = 18.00
      notes       = "Для primary endpoints"
    },
    {
      line_no     = 6
      service     = "Route53"
      component   = "HealthCheck.HTTPS"
      description = "HTTPS health check"
      unit        = "check/month"
      quantity    = 2
      unit_price  = 1.00
      monthly_usd = 2.00
      yearly_usd  = 24.00
      notes       = "Для SSL-endpoints"
    },
    {
      line_no     = 7
      service     = "Route53"
      component   = "DNSSEC"
      description = "DNSSEC signing"
      unit        = "zone/month"
      quantity    = var.enable_dnssec ? 1 : 0
      unit_price  = 1.00
      monthly_usd = var.enable_dnssec ? 1.00 : 0
      yearly_usd  = var.enable_dnssec ? 12.00 : 0
      notes       = var.enable_dnssec ? "Включено" : "Отключено (по умолчанию)"
    },
    {
      line_no     = 8
      service     = "CloudWatch"
      component   = "Logs.Ingestion"
      description = "Query logging в CloudWatch Logs"
      unit        = "per GB"
      quantity    = var.create_query_log ? 12 : 0
      unit_price  = 0.50
      monthly_usd = var.create_query_log ? 6.00 : 0
      yearly_usd  = var.create_query_log ? 72.00 : 0
      notes       = "Оценка: ~12 GB/мес DNS-логов"
    },
    {
      line_no     = 9
      service     = "CloudWatch"
      component   = "Logs.Storage"
      description = "Хранение логов (30 дней)"
      unit        = "per GB/month"
      quantity    = 12
      unit_price  = 0.03
      monthly_usd = 0.36
      yearly_usd  = 4.32
      notes       = "Стандартный класс хранения"
    },
    {
      line_no     = 10
      service     = "DataTransfer"
      component   = "Out"
      description = "Исходящий трафик DNS-ответов"
      unit        = "per GB"
      quantity    = 5
      unit_price  = 0.09
      monthly_usd = 0.45
      yearly_usd  = 5.40
      notes       = "Незначительный объём"
    },
  ]

  # ------------------------------------------------------------------
  # СЕКЦИЯ 2: Расширенная разбивка по категориям (для дашбордов)
  # ------------------------------------------------------------------
  cost_by_category = {
    "DNS.Queries"     = 100.00 + 24.00 + 10.50
    "DNS.Zones"       = 0.50
    "DNS.HealthCheck" = 1.50 + 2.00
    "DNS.Security"    = var.enable_dnssec ? 1.00 : 0
    "Logging"         = (var.create_query_log ? 6.00 : 0) + 0.36
    "DataTransfer"    = 0.45
  }

  cost_by_service = {
    "Route53"    = 0.50 + 100.00 + 24.00 + 10.50 + 1.50 + 2.00 + (var.enable_dnssec ? 1.00 : 0)
    "CloudWatch" = (var.create_query_log ? 6.00 : 0) + 0.36
    "Other"      = 0.45
  }

  cost_by_environment = {
    "${var.environment}" = local.cost_monthly_total
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 3: Прогноз на 12 месяцев (имитация)
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
  # СЕКЦИЯ 4: Сравнение сценариев (What-If analysis)
  # ------------------------------------------------------------------
  scenario_comparison = {
    "current" = {
      description          = "Текущая конфигурация"
      dnssec               = var.enable_dnssec
      query_logging        = var.create_query_log
      monthly_usd          = local.cost_monthly_total
    }
    "no_logging" = {
      description          = "Без query logging"
      dnssec               = var.enable_dnssec
      query_logging        = false
      monthly_usd          = local.cost_monthly_total - (var.create_query_log ? 6.36 : 0)
    }
    "with_dnssec" = {
      description          = "С включённым DNSSEC"
      dnssec               = true
      query_logging        = var.create_query_log
      monthly_usd          = local.cost_monthly_total + (var.enable_dnssec ? 0 : 1.00)
    }
    "minimal" = {
      description          = "Минимальная конфигурация (без логов и DNSSEC)"
      dnssec               = false
      query_logging        = false
      monthly_usd          = local.cost_monthly_total - (var.create_query_log ? 6.36 : 0) - (var.enable_dnssec ? 1.00 : 0)
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 5: Алерты и пороги (имитация для AWS Budgets)
  # ------------------------------------------------------------------
  budget_thresholds = {
    monthly_warning  = 100.00
    monthly_critical = 150.00
    yearly_max       = 1800.00
    notify_emails    = ["finops@example.com", "devops@example.com"]
    alert_on_breach  = true
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 6: Метаданные отчёта
  # ------------------------------------------------------------------
  cost_report_metadata = {
    generated_by    = "terraform"
    project         = var.project_name
    environment     = var.environment
    domain          = var.domain_name
    aws_region      = var.aws_region
    currency        = local.cost_currency
    pricing_source  = "https://aws.amazon.com/route53/pricing/"
    pricing_date    = "2024-01-01"
    report_version  = "1.0.0"
    disclaimer      = "Это имитация. Для точных цифр используйте Infracost / AWS Cost Explorer."
  }
}