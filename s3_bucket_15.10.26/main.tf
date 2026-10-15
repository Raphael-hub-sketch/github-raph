# =====================================================================
# S3 Bucket (основной ресурс)
# ---------------------------------------------------------------------
# Управляет именем и тегами. Настройки (versioning, encryption,
# lifecycle) вынесены в отдельные ресурсы [citation:16][citation:20].
# =====================================================================
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "main" {
  bucket        = "${var.bucket_prefix}-${var.environment}-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy

  tags = merge(local.common_tags, {
    Name = "${var.bucket_prefix}-${var.environment}-${random_id.bucket_suffix.hex}"
  })
}

# =====================================================================
# Versioning Configuration
# =====================================================================
resource "aws_s3_bucket_versioning" "main" {
  count = var.enable_versioning ? 1 : 0

  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

# =====================================================================
# Server-Side Encryption Configuration (SSE-S3)
# =====================================================================
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count = var.enable_encryption ? 1 : 0

  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# =====================================================================
# Public Access Block
# =====================================================================
resource "aws_s3_bucket_public_access_block" "main" {
  count = var.block_public_access ? 1 : 0

  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
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
  # СЕКЦИЯ 1: Справочник цен AWS S3 (us-east-1, 2024-2026)
  # Источник: https://aws.amazon.com/s3/pricing/ [citation:5][citation:7][citation:17]
  # ------------------------------------------------------------------
  s3_pricing = {
    # --- Хранение (per GB/month) ---
    standard_per_gb_usd            = 0.023    # первые 50 TB [citation:5]
    standard_ia_per_gb_usd         = 0.0125   # Infrequent Access [citation:17]
    glacier_ir_per_gb_usd          = 0.004    # Glacier Instant Retrieval [citation:17]
    glacier_flex_per_gb_usd        = 0.0036   # Glacier Flexible Retrieval [citation:17]
    deep_archive_per_gb_usd        = 0.00099  # Deep Archive [citation:7]

    # --- Запросы (per 1000) ---
    put_requests_per_1k_usd        = 0.005    # PUT/POST/LIST (Standard) [citation:17]
    get_requests_per_1k_usd        = 0.0004   # GET (Standard) [citation:17]

    # --- Data Transfer ---
    internet_egress_per_gb_usd     = 0.09     # после 100 GB бесплатно [citation:5]
    cross_region_per_gb_usd        = 0.02     # между регионами [citation:19]

    # --- Intelligent-Tiering ---
    monitoring_per_1k_objects_usd  = 0.0025   # за 1000 объектов/мес [citation:19]

    # --- Lifecycle Transitions ---
    transition_per_1k_requests_usd = 0.01     # оценка [citation:3]

    # Часов в месяце
    hours_per_month                = 730
    hours_per_year                 = 8760
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 2: Прогнозируемое потребление (имитация)
  # ------------------------------------------------------------------
  s3_usage = {
    # Объём данных (GB)
    data_volume_gb                 = 1000     # 1 TB данных

    # Распределение по классам хранения (в процентах от общего объёма)
    standard_percent               = 30
    standard_ia_percent            = 20
    glacier_ir_percent             = 30
    deep_archive_percent           = 20

    # Запросы в месяц
    monthly_put_requests           = 100000   # 100K PUT
    monthly_get_requests           = 500000   # 500K GET

    # Data transfer
    internet_egress_gb             = 50       # 50 GB egress/мес
    cross_region_gb                = 10       # 10 GB cross-region

    # Versioning overhead (noncurrent версии)
    versioning_overhead_percent    = var.enable_versioning ? 20 : 0

    # Intelligent-Tiering (если используется)
    intelligent_tiering_objects    = 0
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 3: Расчёт объёмов по классам (с учётом versioning)
  # ------------------------------------------------------------------
  data_volume_with_versioning = local.s3_usage.data_volume_gb * (1 + local.s3_usage.versioning_overhead_percent / 100)

  volume_by_class = {
    standard       = local.data_volume_with_versioning * local.s3_usage.standard_percent / 100
    standard_ia    = local.data_volume_with_versioning * local.s3_usage.standard_ia_percent / 100
    glacier_ir     = local.data_volume_with_versioning * local.s3_usage.glacier_ir_percent / 100
    deep_archive   = local.data_volume_with_versioning * local.s3_usage.deep_archive_percent / 100
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 4: Детализированный расчёт затрат (построчный)
  # ------------------------------------------------------------------
  cost_breakdown = {
    # --- Хранение: Standard ---
    storage_standard = {
      description = "S3 Standard (${format("%.0f", local.volume_by_class.standard)} GB)"
      quantity    = local.volume_by_class.standard
      unit_price  = local.s3_pricing.standard_per_gb_usd
      monthly_usd = local.volume_by_class.standard * local.s3_pricing.standard_per_gb_usd
      yearly_usd  = local.volume_by_class.standard * local.s3_pricing.standard_per_gb_usd * 12
      notes       = "Самый дорогой класс, но с мгновенным доступом [citation:5]"
    }

    # --- Хранение: Standard-IA ---
    storage_standard_ia = {
      description = "S3 Standard-IA (${format("%.0f", local.volume_by_class.standard_ia)} GB)"
      quantity    = local.volume_by_class.standard_ia
      unit_price  = local.s3_pricing.standard_ia_per_gb_usd
      monthly_usd = local.volume_by_class.standard_ia * local.s3_pricing.standard_ia_per_gb_usd
      yearly_usd  = local.volume_by_class.standard_ia * local.s3_pricing.standard_ia_per_gb_usd * 12
      notes       = "На 46% дешевле Standard [citation:17]"
    }

    # --- Хранение: Glacier IR ---
    storage_glacier_ir = {
      description = "S3 Glacier Instant Retrieval (${format("%.0f", local.volume_by_class.glacier_ir)} GB)"
      quantity    = local.volume_by_class.glacier_ir
      unit_price  = local.s3_pricing.glacier_ir_per_gb_usd
      monthly_usd = local.volume_by_class.glacier_ir * local.s3_pricing.glacier_ir_per_gb_usd
      yearly_usd  = local.volume_by_class.glacier_ir * local.s3_pricing.glacier_ir_per_gb_usd * 12
      notes       = "На 83% дешевле Standard [citation:17]"
    }

    # --- Хранение: Deep Archive ---
    storage_deep_archive = {
      description = "S3 Glacier Deep Archive (${format("%.0f", local.volume_by_class.deep_archive)} GB)"
      quantity    = local.volume_by_class.deep_archive
      unit_price  = local.s3_pricing.deep_archive_per_gb_usd
      monthly_usd = local.volume_by_class.deep_archive * local.s3_pricing.deep_archive_per_gb_usd
      yearly_usd  = local.volume_by_class.deep_archive * local.s3_pricing.deep_archive_per_gb_usd * 12
      notes       = "В 23 раза дешевле Standard [citation:17]"
    }

    # --- PUT/POST/LIST запросы ---
    put_requests = {
      description = "PUT/POST/LIST запросы (${local.s3_usage.monthly_put_requests} шт.)"
      quantity    = local.s3_usage.monthly_put_requests
      unit_price  = local.s3_pricing.put_requests_per_1k_usd
      monthly_usd = local.s3_usage.monthly_put_requests / 1000 * local.s3_pricing.put_requests_per_1k_usd
      yearly_usd  = local.s3_usage.monthly_put_requests / 1000 * local.s3_pricing.put_requests_per_1k_usd * 12
      notes       = "Batch-запросы снижают стоимость"
    }

    # --- GET запросы ---
    get_requests = {
      description = "GET запросы (${local.s3_usage.monthly_get_requests} шт.)"
      quantity    = local.s3_usage.monthly_get_requests
      unit_price  = local.s3_pricing.get_requests_per_1k_usd
      monthly_usd = local.s3_usage.monthly_get_requests / 1000 * local.s3_pricing.get_requests_per_1k_usd
      yearly_usd  = local.s3_usage.monthly_get_requests / 1000 * local.s3_pricing.get_requests_per_1k_usd * 12
      notes       = "GET в 12.5 раз дешевле PUT [citation:17]"
    }

    # --- Internet Egress ---
    internet_egress = {
      description = "Internet Egress (${local.s3_usage.internet_egress_gb} GB)"
      quantity    = local.s3_usage.internet_egress_gb
      unit_price  = local.s3_pricing.internet_egress_per_gb_usd
      monthly_usd = local.s3_usage.internet_egress_gb * local.s3_pricing.internet_egress_per_gb_usd
      yearly_usd  = local.s3_usage.internet_egress_gb * local.s3_pricing.internet_egress_per_gb_usd * 12
      notes       = "Самый частый источник перерасхода [citation:5][citation:19]"
    }

    # --- Cross-Region Transfer ---
    cross_region = {
      description = "Cross-Region Transfer (${local.s3_usage.cross_region_gb} GB)"
      quantity    = local.s3_usage.cross_region_gb
      unit_price  = local.s3_pricing.cross_region_per_gb_usd
      monthly_usd = local.s3_usage.cross_region_gb * local.s3_pricing.cross_region_per_gb_usd
      yearly_usd  = local.s3_usage.cross_region_gb * local.s3_pricing.cross_region_per_gb_usd * 12
      notes       = "Держите compute и данные в одном регионе [citation:19]"
    }

    # --- Intelligent-Tiering monitoring ---
    intelligent_tiering = {
      description = "Intelligent-Tiering monitoring (${local.s3_usage.intelligent_tiering_objects} объектов)"
      quantity    = local.s3_usage.intelligent_tiering_objects
      unit_price  = local.s3_pricing.monitoring_per_1k_objects_usd
      monthly_usd = local.s3_usage.intelligent_tiering_objects / 1000 * local.s3_pricing.monitoring_per_1k_objects_usd
      yearly_usd  = local.s3_usage.intelligent_tiering_objects / 1000 * local.s3_pricing.monitoring_per_1k_objects_usd * 12
      notes       = "Только для объектов > 128 KB [citation:19]"
    }

    # --- Lifecycle transitions ---
    lifecycle_transitions = {
      description = "Lifecycle transitions (оценка)"
      quantity    = var.enable_lifecycle ? 1 : 0
      unit_price  = local.s3_pricing.transition_per_1k_requests_usd
      monthly_usd = var.enable_lifecycle ? local.s3_usage.monthly_put_requests / 1000 * local.s3_pricing.transition_per_1k_requests_usd : 0
      yearly_usd  = var.enable_lifecycle ? local.s3_usage.monthly_put_requests / 1000 * local.s3_pricing.transition_per_1k_requests_usd * 12 : 0
      notes       = "Одноразовая стоимость при переходе между классами [citation:3]"
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 5: Итоговые суммы (имитация)
  # ------------------------------------------------------------------
  cost_monthly_total = sum([
    for k, v in local.cost_breakdown : v.monthly_usd
  ])

  cost_yearly_total = sum([
    for k, v in local.cost_breakdown : v.yearly_usd
  ])

  cost_currency = "USD"

  # ------------------------------------------------------------------
  # СЕКЦИЯ 6: Построчная детализация по каждому элементу затрат
  # ------------------------------------------------------------------
  cost_line_items = [
    {
      line_no     = 1
      service     = "S3"
      component   = "Storage.Standard"
      description = "S3 Standard хранение"
      unit        = "per GB/month"
      quantity    = local.volume_by_class.standard
      unit_price  = local.s3_pricing.standard_per_gb_usd
      monthly_usd = local.volume_by_class.standard * local.s3_pricing.standard_per_gb_usd
      yearly_usd  = local.volume_by_class.standard * local.s3_pricing.standard_per_gb_usd * 12
      notes       = "$0.023/GB/мес [citation:5]"
    },
    {
      line_no     = 2
      service     = "S3"
      component   = "Storage.StandardIA"
      description = "S3 Standard-IA хранение"
      unit        = "per GB/month"
      quantity    = local.volume_by_class.standard_ia
      unit_price  = local.s3_pricing.standard_ia_per_gb_usd
      monthly_usd = local.volume_by_class.standard_ia * local.s3_pricing.standard_ia_per_gb_usd
      yearly_usd  = local.volume_by_class.standard_ia * local.s3_pricing.standard_ia_per_gb_usd * 12
      notes       = "$0.0125/GB/мес [citation:17]"
    },
    {
      line_no     = 3
      service     = "S3"
      component   = "Storage.GlacierIR"
      description = "S3 Glacier Instant Retrieval хранение"
      unit        = "per GB/month"
      quantity    = local.volume_by_class.glacier_ir
      unit_price  = local.s3_pricing.glacier_ir_per_gb_usd
      monthly_usd = local.volume_by_class.glacier_ir * local.s3_pricing.glacier_ir_per_gb_usd
      yearly_usd  = local.volume_by_class.glacier_ir * local.s3_pricing.glacier_ir_per_gb_usd * 12
      notes       = "$0.004/GB/мес [citation:17]"
    },
    {
      line_no     = 4
      service     = "S3"
      component   = "Storage.DeepArchive"
      description = "S3 Glacier Deep Archive хранение"
      unit        = "per GB/month"
      quantity    = local.volume_by_class.deep_archive
      unit_price  = local.s3_pricing.deep_archive_per_gb_usd
      monthly_usd = local.volume_by_class.deep_archive * local.s3_pricing.deep_archive_per_gb_usd
      yearly_usd  = local.volume_by_class.deep_archive * local.s3_pricing.deep_archive_per_gb_usd * 12
      notes       = "$0.00099/GB/мес [citation:7]"
    },
    {
      line_no     = 5
      service     = "S3"
      component   = "Requests.PUT"
      description = "PUT/POST/LIST запросы"
      unit        = "per 1K requests"
      quantity    = local.s3_usage.monthly_put_requests
      unit_price  = local.s3_pricing.put_requests_per_1k_usd
      monthly_usd = local.s3_usage.monthly_put_requests / 1000 * local.s3_pricing.put_requests_per_1k_usd
      yearly_usd  = local.s3_usage.monthly_put_requests / 1000 * local.s3_pricing.put_requests_per_1k_usd * 12
      notes       = "$0.005/1K [citation:17]"
    },
    {
      line_no     = 6
      service     = "S3"
      component   = "Requests.GET"
      description = "GET запросы"
      unit        = "per 1K requests"
      quantity    = local.s3_usage.monthly_get_requests
      unit_price  = local.s3_pricing.get_requests_per_1k_usd
      monthly_usd = local.s3_usage.monthly_get_requests / 1000 * local.s3_pricing.get_requests_per_1k_usd
      yearly_usd  = local.s3_usage.monthly_get_requests / 1000 * local.s3_pricing.get_requests_per_1k_usd * 12
      notes       = "$0.0004/1K [citation:17]"
    },
    {
      line_no     = 7
      service     = "S3"
      component   = "DataTransfer.Internet"
      description = "Internet Egress"
      unit        = "per GB"
      quantity    = local.s3_usage.internet_egress_gb
      unit_price  = local.s3_pricing.internet_egress_per_gb_usd
      monthly_usd = local.s3_usage.internet_egress_gb * local.s3_pricing.internet_egress_per_gb_usd
      yearly_usd  = local.s3_usage.internet_egress_gb * local.s3_pricing.internet_egress_per_gb_usd * 12
      notes       = "$0.09/GB после 100 GB [citation:5][citation:19]"
    },
  ]

  # ------------------------------------------------------------------
  # СЕКЦИЯ 7: Расширенная разбивка по категориям (для дашбордов)
  # ------------------------------------------------------------------
  cost_by_category = {
    "S3.Storage"       = (local.volume_by_class.standard * local.s3_pricing.standard_per_gb_usd) + (local.volume_by_class.standard_ia * local.s3_pricing.standard_ia_per_gb_usd) + (local.volume_by_class.glacier_ir * local.s3_pricing.glacier_ir_per_gb_usd) + (local.volume_by_class.deep_archive * local.s3_pricing.deep_archive_per_gb_usd)
    "S3.Requests"      = (local.s3_usage.monthly_put_requests / 1000 * local.s3_pricing.put_requests_per_1k_usd) + (local.s3_usage.monthly_get_requests / 1000 * local.s3_pricing.get_requests_per_1k_usd)
    "S3.DataTransfer"  = (local.s3_usage.internet_egress_gb * local.s3_pricing.internet_egress_per_gb_usd) + (local.s3_usage.cross_region_gb * local.s3_pricing.cross_region_per_gb_usd)
    "S3.IntelligentTiering" = local.s3_usage.intelligent_tiering_objects / 1000 * local.s3_pricing.monitoring_per_1k_objects_usd
    "S3.Lifecycle"     = var.enable_lifecycle ? local.s3_usage.monthly_put_requests / 1000 * local.s3_pricing.transition_per_1k_requests_usd : 0
  }

  cost_by_service = {
    "S3" = local.cost_monthly_total
  }

  cost_by_environment = {
    "${var.environment}" = local.cost_monthly_total
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 8: Прогноз на 12 месяцев (имитация)
  # ------------------------------------------------------------------
  monthly_forecast = [
    for m in range(1, 13) : {
      month        = m
      month_name   = element([
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
      ], m - 1)
      base_usd     = local.cost_monthly_total
      growth_rate  = 0.02 # 2% ежемесячный рост данных
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
  # СЕКЦИЯ 9: Сравнение сценариев (What-If analysis)
  # ------------------------------------------------------------------
  scenario_comparison = {
    "current" = {
      description          = "Текущая конфигурация (${local.s3_usage.data_volume_gb} GB, lifecycle enabled)"
      data_volume_gb       = local.s3_usage.data_volume_gb
      monthly_usd          = local.cost_monthly_total
    }
    "all_standard" = {
      description          = "Все данные в S3 Standard (без lifecycle)"
      data_volume_gb       = local.s3_usage.data_volume_gb
      monthly_usd          = local.s3_usage.data_volume_gb * local.s3_pricing.standard_per_gb_usd
    }
    "all_deep_archive" = {
      description          = "Все данные в Deep Archive"
      data_volume_gb       = local.s3_usage.data_volume_gb
      monthly_usd          = local.s3_usage.data_volume_gb * local.s3_pricing.deep_archive_per_gb_usd
    }
    "no_versioning" = {
      description          = "Без versioning (меньше объём)"
      data_volume_gb       = local.s3_usage.data_volume_gb
      monthly_usd          = local.s3_usage.data_volume_gb * local.s3_pricing.standard_per_gb_usd * 0.7
    }
    "high_egress" = {
      description          = "Высокий egress (500 GB/мес)"
      data_volume_gb       = local.s3_usage.data_volume_gb
      monthly_usd          = local.cost_monthly_total + (500 - local.s3_usage.internet_egress_gb) * local.s3_pricing.internet_egress_per_gb_usd
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 10: Алерты и пороги (имитация для AWS Budgets)
  # ------------------------------------------------------------------
  budget_thresholds = {
    monthly_warning      = 50.00
    monthly_critical     = 100.00
    yearly_max           = 1000.00    notify_emails        = ["finops@example.com", "devops@example.com"]
    alert_on_breach      = true
    egress_warning_gb    = 500
    egress_crit_gb       = 1000
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 11: Метаданные отчёта
  # ------------------------------------------------------------------
  cost_report_metadata = {
    generated_by       = "terraform"
    project            = var.project_name
    environment        = var.environment
    bucket_name        = aws_s3_bucket.main.bucket
    aws_region         = var.aws_region
    currency           = local.cost_currency
    pricing_source     = "https://aws.amazon.com/s3/pricing/"
    pricing_date       = "2025-01-01"
    report_version     = "1.0.0"
    disclaimer         = "Это имитация. Для точных цифр используйте Infracost / AWS Cost Explorer."
    billing_note       = "S3 bills storage + requests + data transfer. Lifecycle policies reduce storage costs 30-80% [citation:5]"
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 12: Проверка лимитов и квот (имитация)
  # ------------------------------------------------------------------
  quota_checks = {
    max_bucket_name_length       = 63
    max_object_size_tb           = 5
    current_bucket_name_length   = length(aws_s3_bucket.main.bucket)
    bucket_name_ok               = length(aws_s3_bucket.main.bucket) <= 63
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 13: Сравнение классов хранения (справочник)
  # ------------------------------------------------------------------
  storage_class_details = {
    "Standard" = {
      price_per_gb        = 0.023
      retrieval_time      = "Instant"
      min_duration_days   = 0
      use_cases           = "Hot data, frequently accessed [citation:10]"
    }
    "Standard-IA" = {
      price_per_gb        = 0.0125
      retrieval_time      = "Instant"
      min_duration_days   = 30
      use_cases           = "Warm data, backups [citation:10]"
    }
    "Glacier Instant Retrieval" = {
      price_per_gb        = 0.004
      retrieval_time      = "Instant"
      min_duration_days   = 90
      use_cases           = "Archive with instant access [citation:3]"
    }
    "Glacier Flexible Retrieval" = {
      price_per_gb        = 0.0036
      retrieval_time      = "Minutes to hours"
      min_duration_days   = 90
      use_cases           = "Archives, compliance [citation:10]"
    }
    "Glacier Deep Archive" = {
      price_per_gb        = 0.00099
      retrieval_time      = "12-48 hours"
      min_duration_days   = 180
      use_cases           = "Long-term compliance [citation:17]"
    }
    "Intelligent-Tiering" = {
      price_per_gb        = "Varies by tier"
      retrieval_time      = "Instant"
      min_duration_days   = 0
      use_cases           = "Unknown access patterns [citation:10][citation:19]"
    }
  }
}