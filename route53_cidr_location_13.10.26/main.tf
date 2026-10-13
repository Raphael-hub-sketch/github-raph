# =====================================================================
# Route53 CIDR Location (основной ресурс)
# ---------------------------------------------------------------------
# Добавляет CIDR-блоки в CIDR-коллекцию для IP-based routing.
# Сама локация не тарифицируется — только хранение блоков.
# =====================================================================
resource "aws_route53_cidr_location" "main" {
  cidr_collection_id = local.collection_id
  name               = var.location_name
  cidr_blocks        = var.cidr_blocks
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
  # СЕКЦИЯ 1: Справочник цен AWS Route53 CIDR Locations
  # Источник: https://aws.amazon.com/route53/pricing/ [citation:10]
  # ------------------------------------------------------------------
  cidr_pricing = {
    # Хранение CIDR-блоков
    free_blocks_limit             = 1000   # первые 1000 блоков бесплатно [citation:2]
    block_per_month_usd           = 0.0015 # $0.0015 за блок свыше 1000
    block_per_hour_usd            = 0.0015 / 730

    # Часов в месяце (30 дней)
    hours_per_month               = 730
    hours_per_year                = 8760
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 2: Прогнозируемое потребление (имитация)
  # ------------------------------------------------------------------
  cidr_usage = {
    # Количество блоков в этой локации
    location_blocks_count   = length(var.cidr_blocks)
    # Общее количество блоков в коллекции (для расчёта free tier)
    total_collection_blocks = length(var.cidr_blocks)
    # Количество локаций в коллекции
    locations_count         = 1
    # Месячные IP-based DNS-запросы (в миллионах)
    monthly_ip_queries_millions = 10
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 3: Детализированный расчёт затрат (построчный)
  # ------------------------------------------------------------------
  cost_breakdown = {
    # --- Хранение CIDR-блоков ---
    cidr_storage = {
      description = "Хранение CIDR-блоков (${local.cidr_usage.location_blocks_count} шт.)"
      quantity    = max(0, local.cidr_usage.total_collection_blocks - local.cidr_pricing.free_blocks_limit)
      unit_price  = local.cidr_pricing.block_per_month_usd
      monthly_usd = max(0, local.cidr_usage.total_collection_blocks - local.cidr_pricing.free_blocks_limit) * local.cidr_pricing.block_per_month_usd
      yearly_usd  = max(0, local.cidr_usage.total_collection_blocks - local.cidr_pricing.free_blocks_limit) * local.cidr_pricing.block_per_month_usd * 12
      notes       = "Первые 1000 блоков бесплатно [citation:2]"
    }

    # --- IP-based DNS-запросы (тарифицируются как обычные) ---
    ip_queries = {
      description = "IP-based DNS-запросы (${local.cidr_usage.monthly_ip_queries_millions}M/мес)"
      quantity    = local.cidr_usage.monthly_ip_queries_millions
      unit_price  = 0.40  # стандартная ставка Route53
      monthly_usd = local.cidr_usage.monthly_ip_queries_millions * 0.40
      yearly_usd  = local.cidr_usage.monthly_ip_queries_millions * 0.40 * 12
      notes       = "Тарифицируются как Intra-AWS-Cidr-Queries"
    }

    # --- CIDR Location (не тарифицируется) ---
    cidr_location = {
      description = "CIDR Location (${var.location_name})"
      quantity    = 1
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Сама локация не тарифицируется"
    }

    # --- CIDR Collection (не тарифицируется) ---
    cidr_collection = {
      description = "CIDR Collection (${var.collection_name})"
      quantity    = 1
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Коллекция не тарифицируется"
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
      component   = "CIDRStorage"
      description = "Хранение CIDR-блоков (${local.cidr_usage.location_blocks_count} шт.)"
      unit        = "per block/month"
      quantity    = max(0, local.cidr_usage.total_collection_blocks - local.cidr_pricing.free_blocks_limit)
      unit_price  = local.cidr_pricing.block_per_month_usd
      monthly_usd = max(0, local.cidr_usage.total_collection_blocks - local.cidr_pricing.free_blocks_limit) * local.cidr_pricing.block_per_month_usd
      yearly_usd  = max(0, local.cidr_usage.total_collection_blocks - local.cidr_pricing.free_blocks_limit) * local.cidr_pricing.block_per_month_usd * 12
      notes       = "Free tier: 1000 blocks [citation:2]"
    },
    {
      line_no     = 2
      service     = "Route53"
      component   = "IPBasedQueries"
      description = "IP-based DNS-запросы"
      unit        = "per million"
      quantity    = local.cidr_usage.monthly_ip_queries_millions
      unit_price  = 0.40
      monthly_usd = local.cidr_usage.monthly_ip_queries_millions * 0.40
      yearly_usd  = local.cidr_usage.monthly_ip_queries_millions * 0.40 * 12
      notes       = "Billed as Intra-AWS-Cidr-Queries"
    },
    {
      line_no     = 3
      service     = "Route53"
      component   = "CIDRLocation"
      description = "CIDR Location (${var.location_name})"
      unit        = "n/a"
      quantity    = 1
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Location itself is free"
    },
    {
      line_no     = 4
      service     = "Route53"
      component   = "CIDRCollection"
      description = "CIDR Collection"
      unit        = "n/a"
      quantity    = 1
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Collection is free"
    },
  ]

  # ------------------------------------------------------------------
  # СЕКЦИЯ 6: Расширенная разбивка по категориям (для дашбордов)
  # ------------------------------------------------------------------
  cost_by_category = {
    "CIDR.Storage"    = max(0, local.cidr_usage.total_collection_blocks - local.cidr_pricing.free_blocks_limit) * local.cidr_pricing.block_per_month_usd
    "CIDR.Queries"    = local.cidr_usage.monthly_ip_queries_millions * 0.40
    "CIDR.Location"   = 0.00
    "CIDR.Collection" = 0.00
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
      description          = "Текущая конфигурация (${local.cidr_usage.location_blocks_count} блоков, ${local.cidr_usage.monthly_ip_queries_millions}M запросов)"
      location_blocks      = local.cidr_usage.location_blocks_count
      monthly_queries      = local.cidr_usage.monthly_ip_queries_millions
      monthly_usd          = local.cost_monthly_total
    }
    "within_free_tier" = {
      description          = "В пределах Free Tier (1000 блоков, без запросов)"
      location_blocks      = 1000
      monthly_usd          = 0.00
    }
    "large_location" = {
      description          = "Большая локация (2000 блоков)"
      location_blocks      = 2000
      monthly_usd          = (2000 - 1000) * local.cidr_pricing.block_per_month_usd
    }
    "no_queries" = {
      description          = "Без IP-based запросов"
      location_blocks      = local.cidr_usage.location_blocks_count
      monthly_usd          = max(0, local.cidr_usage.total_collection_blocks - local.cidr_pricing.free_blocks_limit) * local.cidr_pricing.block_per_month_usd
    }
    "high_traffic" = {
      description          = "Высокий трафик (100M IP-запросов)"
      location_blocks      = local.cidr_usage.location_blocks_count
      monthly_usd          = local.cost_monthly_total + (100 - local.cidr_usage.monthly_ip_queries_millions) * 0.40
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 9: Алерты и пороги (имитация для AWS Budgets)
  # ------------------------------------------------------------------
  budget_thresholds = {
    monthly_warning      = 10.00
    monthly_critical     = 25.00
    yearly_max           = 200.00
    notify_emails        = ["finops@example.com", "devops@example.com"]
    alert_on_breach      = true
    cidr_blocks_warning  = 5000
    cidr_blocks_crit     = 10000
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 10: Метаданные отчёта
  # ------------------------------------------------------------------
  cost_report_metadata = {
    generated_by       = "terraform"
    project            = var.project_name
    environment        = var.environment
    collection_name    = var.collection_name
    location_name      = var.location_name
    aws_region         = var.aws_region
    currency           = local.cost_currency
    pricing_source     = "https://aws.amazon.com/route53/pricing/"
    pricing_date       = "2025-01-01"
    report_version     = "1.0.0"
    disclaimer         = "Это имитация. Для точных цифр используйте Infracost / AWS Cost Explorer."
    billing_note       = "CIDR locations are free. Only storage over 1000 blocks is billed [citation:2][citation:10]"
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 11: Проверка лимитов и квот (имитация)
  # Источник: AWS quotas [citation:6]
  # ------------------------------------------------------------------
  quota_checks = {
    max_collections_per_account = 5
    max_blocks_per_collection   = 1000
    max_location_name_length    = 16
    current_blocks              = local.cidr_usage.total_collection_blocks
    current_location_name_len   = length(var.location_name)
    blocks_ok                   = local.cidr_usage.total_collection_blocks <= 1000
    location_name_ok            = length(var.location_name) <= 16
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 12: Детализация по CIDR-блокам (для документации)
  # ------------------------------------------------------------------
  cidr_details = {
    for cidr in var.cidr_blocks : cidr => {
      ip_version  = strcontains(cidr, ":") ? "IPv6" : "IPv4"
      prefix      = tonumber(split("/", cidr)[1])
      valid_ipv4  = strcontains(cidr, ":") ? false : (tonumber(split("/", cidr)[1]) >= 0 && tonumber(split("/", cidr)[1]) <= 24)
      valid_ipv6  = strcontains(cidr, ":") ? (tonumber(split("/", cidr)[1]) >= 0 && tonumber(split("/", cidr)[1]) <= 48) : false
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 13: Справочник по IP-based Routing (для документации)
  # ------------------------------------------------------------------
  ip_based_routing_info = {
    use_cases = [
      "Route users to different endpoints based on their IP address",
      "Direct traffic from specific offices to local resources",
      "A/B testing based on client IP ranges",
      "Compliance routing (data residency requirements)"
    ]
    limitations = [
      "Maximum 16 characters for location name [citation:6]",
      "IPv4 CIDR blocks from /0 to /24 [citation:6]",
      "IPv6 CIDR blocks from /0 to /48 [citation:6]",
      "Maximum 1000 CIDR blocks per collection [citation:2]",
      "Not supported for private hosted zones"
    ]
    how_it_works = "Route 53 matches client IP against CIDR blocks. Longest prefix match wins. If no match, default routing applies."
  }
}