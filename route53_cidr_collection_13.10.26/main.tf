# =====================================================================
# Route53 CIDR Collection (основной ресурс)
# ---------------------------------------------------------------------
# Создаёт контейнер для CIDR-блоков. Для добавления блоков
# используется aws_route53_cidr_location.
# =====================================================================
resource "aws_route53_cidr_collection" "main" {
  name = var.collection_name

  tags = merge(local.common_tags, {
    Name = var.collection_name
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
  # СЕКЦИЯ 1: Справочник цен AWS Route53 CIDR Collections
  # Источник: https://aws.amazon.com/route53/pricing/ [citation:19]
  # ------------------------------------------------------------------
  cidr_pricing = {
    # Хранение CIDR-блоков
    free_blocks_limit             = 1000   # первые 1000 блоков бесплатно [citation:19]
    block_per_month_usd           = 0.0015 # $0.0015 за блок свыше 1000 [citation:19]
    block_per_hour_usd            = 0.0015 / 730

    # Часов в месяце (30 дней)
    hours_per_month               = 730
    hours_per_year                = 8760
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 2: Прогнозируемое потребление (имитация)
  # ------------------------------------------------------------------
  cidr_usage = {
    # Общее количество CIDR-блоков во всех локациях
    total_cidr_blocks = sum([for loc in var.locations : length(loc.cidr_blocks)])
    # Количество локаций
    locations_count   = length(var.locations)
    # Количество коллекций
    collections_count = 1
    # Месячные IP-based DNS-запросы (в миллионах)
    monthly_ip_queries_millions = 10
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 3: Детализированный расчёт затрат (построчный)
  # ------------------------------------------------------------------
  cost_breakdown = {
    # --- Хранение CIDR-блоков ---
    cidr_storage = {
      description = "Хранение CIDR-блоков (${local.cidr_usage.total_cidr_blocks} шт.)"
      quantity    = max(0, local.cidr_usage.total_cidr_blocks - local.cidr_pricing.free_blocks_limit)
      unit_price  = local.cidr_pricing.block_per_month_usd
      monthly_usd = max(0, local.cidr_usage.total_cidr_blocks - local.cidr_pricing.free_blocks_limit) * local.cidr_pricing.block_per_month_usd
      yearly_usd  = max(0, local.cidr_usage.total_cidr_blocks - local.cidr_pricing.free_blocks_limit) * local.cidr_pricing.block_per_month_usd * 12
      notes       = "Первые 1000 блоков бесплатно [citation:19]"
    }

    # --- IP-based DNS-запросы (тарифицируются как обычные) ---
    ip_queries = {
      description = "IP-based DNS-запросы (${local.cidr_usage.monthly_ip_queries_millions}M/мес)"
      quantity    = local.cidr_usage.monthly_ip_queries_millions
      unit_price  = 0.40  # стандартная ставка Route53
      monthly_usd = local.cidr_usage.monthly_ip_queries_millions * 0.40
      yearly_usd  = local.cidr_usage.monthly_ip_queries_millions * 0.40 * 12
      notes       = "Тарифицируются как Intra-AWS-Cidr-Queries [citation:24]"
    }

    # --- Сама коллекция (не тарифицируется) ---
    collection = {
      description = "CIDR Collection (${local.cidr_usage.collections_count} шт.)"
      quantity    = local.cidr_usage.collections_count
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Сам ресурс коллекции не тарифицируется"
    }

    # --- CIDR Locations (не тарифицируются) ---
    locations = {
      description = "CIDR Locations (${local.cidr_usage.locations_count} шт.)"
      quantity    = local.cidr_usage.locations_count
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Локации не тарифицируются отдельно"
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
      description = "Хранение CIDR-блоков (${local.cidr_usage.total_cidr_blocks} шт.)"
      unit        = "per block/month"
      quantity    = max(0, local.cidr_usage.total_cidr_blocks - local.cidr_pricing.free_blocks_limit)
      unit_price  = local.cidr_pricing.block_per_month_usd
      monthly_usd = max(0, local.cidr_usage.total_cidr_blocks - local.cidr_pricing.free_blocks_limit) * local.cidr_pricing.block_per_month_usd
      yearly_usd  = max(0, local.cidr_usage.total_cidr_blocks - local.cidr_pricing.free_blocks_limit) * local.cidr_pricing.block_per_month_usd * 12
      notes       = "Free tier: 1000 blocks [citation:19]"
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
      notes       = "Billed as Intra-AWS-Cidr-Queries [citation:24]"
    },
    {
      line_no     = 3
      service     = "Route53"
      component   = "Collection"
      description = "CIDR Collection"
      unit        = "n/a"
      quantity    = local.cidr_usage.collections_count
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Resource itself is free"
    },
    {
      line_no     = 4
      service     = "Route53"
      component   = "Locations"
      description = "CIDR Locations"
      unit        = "n/a"
      quantity    = local.cidr_usage.locations_count
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Locations are free"
    },
  ]

  # ------------------------------------------------------------------
  # СЕКЦИЯ 6: Расширенная разбивка по категориям (для дашбордов)
  # ------------------------------------------------------------------
  cost_by_category = {
    "CIDR.Storage"    = max(0, local.cidr_usage.total_cidr_blocks - local.cidr_pricing.free_blocks_limit) * local.cidr_pricing.block_per_month_usd
    "CIDR.Queries"    = local.cidr_usage.monthly_ip_queries_millions * 0.40
    "CIDR.Collection" = 0.00
    "CIDR.Locations"  = 0.00
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
      description          = "Текущая конфигурация (${local.cidr_usage.total_cidr_blocks} блоков, ${local.cidr_usage.locations_count} локаций)"
      total_cidr_blocks    = local.cidr_usage.total_cidr_blocks
      locations_count      = local.cidr_usage.locations_count
      monthly_usd          = local.cost_monthly_total
    }
    "within_free_tier" = {
      description          = "В пределах Free Tier (1000 блоков)"
      total_cidr_blocks    = 1000
      monthly_usd          = 0.00
    }
    "large_collection" = {
      description          = "Большая коллекция (5000 блоков)"
      total_cidr_blocks    = 5000
      monthly_usd          = (5000 - 1000) * local.cidr_pricing.block_per_month_usd
    }
    "no_queries" = {
      description          = "Без IP-based запросов"
      total_cidr_blocks    = local.cidr_usage.total_cidr_blocks
      monthly_usd          = max(0, local.cidr_usage.total_cidr_blocks - local.cidr_pricing.free_blocks_limit) * local.cidr_pricing.block_per_month_usd
    }
    "high_traffic" = {
      description          = "Высокий трафик (100M IP-запросов)"
      total_cidr_blocks    = local.cidr_usage.total_cidr_blocks
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
    aws_region         = var.aws_region
    currency           = local.cost_currency
    pricing_source     = "https://aws.amazon.com/route53/pricing/"
    pricing_date       = "2025-01-01"
    report_version     = "1.0.0"
    disclaimer         = "Это имитация. Для точных цифр используйте Infracost / AWS Cost Explorer."
    billing_note       = "CIDR collections are free. Only storage over 1000 blocks is billed [citation:19]"
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 11: Проверка лимитов и квот (имитация)
  # Источник: AWS quotas [citation:28]
  # ------------------------------------------------------------------
  quota_checks = {
    max_collections_per_account = 5
    max_blocks_per_collection   = 1000
    max_location_name_length    = 16
    current_collections         = local.cidr_usage.collections_count
    current_blocks              = local.cidr_usage.total_cidr_blocks
    max_location_name           = max([for loc in var.locations : length(loc.name)]...)
    collections_ok              = local.cidr_usage.collections_count <= 5
    blocks_ok                   = local.cidr_usage.total_cidr_blocks <= 1000
    location_names_ok           = max([for loc in var.locations : length(loc.name)]...) <= 16
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 12: Детализация по локациям (для документации)
  # ------------------------------------------------------------------
  location_details = {
    for loc in var.locations : loc.name => {
      cidr_blocks = loc.cidr_blocks
      block_count = length(loc.cidr_blocks)
      ipv4_blocks = [for cidr in loc.cidr_blocks : cidr if !strcontains(cidr, ":")]
      ipv6_blocks = [for cidr in loc.cidr_blocks : cidr if strcontains(cidr, ":")]
    }
  }
}