# =====================================================================
# Route53 Resolver Query Log Config Association (основной ресурс)
# ---------------------------------------------------------------------
# Связывает VPC с конфигурацией логирования DNS-запросов.
# Сам ресурс не тарифицируется — плата за целевой сервис логов.
# =====================================================================
resource "aws_route53_resolver_query_log_config_association" "main" {
  count = var.create_vpc ? 1 : 0

  resolver_query_log_config_id = aws_route53_resolver_query_log_config.main.id
  resource_id                  = aws_vpc.main[0].id

  # Теги не поддерживаются этим ресурсом напрямую,
  # но добавляем метаданные через default_tags провайдера
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
  # СЕКЦИЯ 1: Справочник цен на целевые сервисы логов (2024-2025)
  # Источник: AWS Pricing / CloudWatch Pricing / S3 Pricing
  # ------------------------------------------------------------------
  log_destination_pricing = {
    cloudwatch = {
      ingestion_per_gb_usd    = 0.50   # CloudWatch Logs ingestion
      storage_per_gb_usd      = 0.03   # CloudWatch Logs storage (Standard)
      vended_logs_per_gb_usd  = 0.03   # CloudWatch Vended Logs (применяется даже при S3) [citation:5][citation:10]
      api_requests_per_1k_usd = 0.005  # PutLogEvents requests
    }
    s3 = {
      storage_per_gb_usd      = 0.023  # S3 Standard
      put_requests_per_1k_usd = 0.005  # PUT requests
      get_requests_per_1k_usd = 0.0004 # GET requests
      vended_logs_per_gb_usd  = 0.03   # CloudWatch Vended Logs applies [citation:5][citation:10]
    }
    firehose = {
      data_transfer_per_gb_usd = 0.029 # Kinesis Data Firehose delivery
      storage_per_gb_usd       = 0.023 # S3 storage (если назначение S3)
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 2: Прогнозируемое потребление (имитация)
  # ------------------------------------------------------------------
  logging_usage = {
    # Количество VPC, ассоциированных с конфигурацией
    vpc_associations             = 1
    # Оценка объёма логов в месяц (GB)
    estimated_log_volume_gb      = var.estimated_log_volume_gb
    # Количество DNS-запросов, генерирующих логи (в миллионах)
    monthly_queries_millions     = 500
    # Средний размер одной записи лога (байт)
    avg_log_record_bytes         = 500
    # Срок хранения логов (дни)
    retention_days               = var.log_destination_type == "cloudwatch" ? var.cloudwatch_log_retention_days : var.s3_log_retention_days
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 3: Детализированный расчёт затрат (построчный)
  # ------------------------------------------------------------------
  cost_breakdown = {
    # --- CloudWatch Logs: Ingestion ---
    cloudwatch_ingestion = {
      description = "CloudWatch Logs: Ingestion (${local.logging_usage.estimated_log_volume_gb} GB/мес)"
      quantity    = var.log_destination_type == "cloudwatch" ? local.logging_usage.estimated_log_volume_gb : 0
      unit_price  = local.log_destination_pricing.cloudwatch.ingestion_per_gb_usd
      monthly_usd = (var.log_destination_type == "cloudwatch" ? local.logging_usage.estimated_log_volume_gb : 0) * local.log_destination_pricing.cloudwatch.ingestion_per_gb_usd
      yearly_usd  = (var.log_destination_type == "cloudwatch" ? local.logging_usage.estimated_log_volume_gb : 0) * local.log_destination_pricing.cloudwatch.ingestion_per_gb_usd * 12
      notes       = "Тарифицируется CloudWatch, не Route53 [citation:2]"
    }

    # --- CloudWatch Logs: Storage ---
    cloudwatch_storage = {
      description = "CloudWatch Logs: Хранение (${local.logging_usage.retention_days} дней)"
      quantity    = var.log_destination_type == "cloudwatch" ? local.logging_usage.estimated_log_volume_gb * (local.logging_usage.retention_days / 30) : 0
      unit_price  = local.log_destination_pricing.cloudwatch.storage_per_gb_usd
      monthly_usd = (var.log_destination_type == "cloudwatch" ? local.logging_usage.estimated_log_volume_gb * (local.logging_usage.retention_days / 30) : 0) * local.log_destination_pricing.cloudwatch.storage_per_gb_usd
      yearly_usd  = (var.log_destination_type == "cloudwatch" ? local.logging_usage.estimated_log_volume_gb * (local.logging_usage.retention_days / 30) : 0) * local.log_destination_pricing.cloudwatch.storage_per_gb_usd * 12
      notes       = "Хранение пропорционально retention days"
    }

    # --- CloudWatch Vended Logs (применяется даже при S3) ---
    cloudwatch_vended_logs = {
      description = "CloudWatch Vended Logs (применяется ко всем назначениям)"
      quantity    = local.logging_usage.estimated_log_volume_gb
      unit_price  = local.log_destination_pricing.cloudwatch.vended_logs_per_gb_usd
      monthly_usd = local.logging_usage.estimated_log_volume_gb * local.log_destination_pricing.cloudwatch.vended_logs_per_gb_usd
      yearly_usd  = local.logging_usage.estimated_log_volume_gb * local.log_destination_pricing.cloudwatch.vended_logs_per_gb_usd * 12
      notes       = "Применяется даже при публикации напрямую в S3 [citation:5][citation:10]"
    }

    # --- S3: Storage ---
    s3_storage = {
      description = "S3: Хранение логов (${local.logging_usage.retention_days} дней)"
      quantity    = var.log_destination_type == "s3" ? local.logging_usage.estimated_log_volume_gb * (local.logging_usage.retention_days / 30) : 0
      unit_price  = local.log_destination_pricing.s3.storage_per_gb_usd
      monthly_usd = (var.log_destination_type == "s3" ? local.logging_usage.estimated_log_volume_gb * (local.logging_usage.retention_days / 30) : 0) * local.log_destination_pricing.s3.storage_per_gb_usd
      yearly_usd  = (var.log_destination_type == "s3" ? local.logging_usage.estimated_log_volume_gb * (local.logging_usage.retention_days / 30) : 0) * local.log_destination_pricing.s3.storage_per_gb_usd * 12
      notes       = "S3 Standard — экономичен для долгосрочного хранения [citation:7]"
    }

    # --- S3: PUT Requests ---
    s3_put_requests = {
      description = "S3: PUT-запросы"
      quantity    = var.log_destination_type == "s3" ? ceil(local.logging_usage.monthly_queries_millions * 1000000 / 1000) : 0
      unit_price  = local.log_destination_pricing.s3.put_requests_per_1k_usd
      monthly_usd = (var.log_destination_type == "s3" ? ceil(local.logging_usage.monthly_queries_millions * 1000000 / 1000) : 0) * local.log_destination_pricing.s3.put_requests_per_1k_usd
      yearly_usd  = (var.log_destination_type == "s3" ? ceil(local.logging_usage.monthly_queries_millions * 1000000 / 1000) : 0) * local.log_destination_pricing.s3.put_requests_per_1k_usd * 12
      notes       = "Batch-запросы снижают стоимость"
    }

    # --- Kinesis Data Firehose: Data Transfer ---
    firehose_transfer = {
      description = "Kinesis Data Firehose: Передача данных"
      quantity    = var.log_destination_type == "firehose" ? local.logging_usage.estimated_log_volume_gb : 0
      unit_price  = local.log_destination_pricing.firehose.data_transfer_per_gb_usd
      monthly_usd = (var.log_destination_type == "firehose" ? local.logging_usage.estimated_log_volume_gb : 0) * local.log_destination_pricing.firehose.data_transfer_per_gb_usd
      yearly_usd  = (var.log_destination_type == "firehose" ? local.logging_usage.estimated_log_volume_gb : 0) * local.log_destination_pricing.firehose.data_transfer_per_gb_usd * 12
      notes       = "Для стриминга в реальном времени [citation:7]"
    }

    # --- Route53 Resolver Query Logging (бесплатно) ---
    route53_logging = {
      description = "Route53 Resolver Query Logging (функция)"
      quantity    = local.logging_usage.vpc_associations
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Route 53 не взимает плату за функцию [citation:2][citation:8]"
    }

    # --- Association (бесплатно) ---
    association = {
      description = "Query Log Config Association (${local.logging_usage.vpc_associations} VPC)"
      quantity    = local.logging_usage.vpc_associations
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Ресурс не тарифицируется"
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
      component   = "QueryLogging.Feature"
      description = "Функция логирования DNS-запросов"
      unit        = "n/a"
      quantity    = 1
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Бесплатно [citation:2][citation:8]"
    },
    {
      line_no     = 2
      service     = "CloudWatch"
      component   = "Logs.Ingestion"
      description = "CloudWatch Logs: Ingestion (${local.logging_usage.estimated_log_volume_gb} GB/мес)"
      unit        = "per GB"
      quantity    = var.log_destination_type == "cloudwatch" ? local.logging_usage.estimated_log_volume_gb : 0
      unit_price  = local.log_destination_pricing.cloudwatch.ingestion_per_gb_usd
      monthly_usd = (var.log_destination_type == "cloudwatch" ? local.logging_usage.estimated_log_volume_gb : 0) * local.log_destination_pricing.cloudwatch.ingestion_per_gb_usd
      yearly_usd  = (var.log_destination_type == "cloudwatch" ? local.logging_usage.estimated_log_volume_gb : 0) * local.log_destination_pricing.cloudwatch.ingestion_per_gb_usd * 12
      notes       = "Основная статья расходов при CloudWatch [citation:2]"
    },
    {
      line_no     = 3
      service     = "CloudWatch"
      component   = "Logs.Storage"
      description = "CloudWatch Logs: Хранение (${local.logging_usage.retention_days} дней)"
      unit        = "per GB/month"
      quantity    = var.log_destination_type == "cloudwatch" ? local.logging_usage.estimated_log_volume_gb * (local.logging_usage.retention_days / 30) : 0
      unit_price  = local.log_destination_pricing.cloudwatch.storage_per_gb_usd
      monthly_usd = (var.log_destination_type == "cloudwatch" ? local.logging_usage.estimated_log_volume_gb * (local.logging_usage.retention_days / 30) : 0) * local.log_destination_pricing.cloudwatch.storage_per_gb_usd
      yearly_usd  = (var.log_destination_type == "cloudwatch" ? local.logging_usage.estimated_log_volume_gb * (local.logging_usage.retention_days / 30) : 0) * local.log_destination_pricing.cloudwatch.storage_per_gb_usd * 12
      notes       = "Пропорционально retention days"
    },
    {
      line_no     = 4
      service     = "CloudWatch"
      component   = "VendedLogs"
      description = "CloudWatch Vended Logs (применяется ко всем назначениям)"
      unit        = "per GB"
      quantity    = local.logging_usage.estimated_log_volume_gb
      unit_price  = local.log_destination_pricing.cloudwatch.vended_logs_per_gb_usd
      monthly_usd = local.logging_usage.estimated_log_volume_gb * local.log_destination_pricing.cloudwatch.vended_logs_per_gb_usd
      yearly_usd  = local.logging_usage.estimated_log_volume_gb * local.log_destination_pricing.cloudwatch.vended_logs_per_gb_usd * 12
      notes       = "Применяется даже при S3 [citation:5][citation:10]"
    },
    {
      line_no     = 5
      service     = "S3"
      component   = "Storage"
      description = "S3: Хранение (${local.logging_usage.retention_days} дней)"
      unit        = "per GB/month"
      quantity    = var.log_destination_type == "s3" ? local.logging_usage.estimated_log_volume_gb * (local.logging_usage.retention_days / 30) : 0
      unit_price  = local.log_destination_pricing.s3.storage_per_gb_usd
      monthly_usd = (var.log_destination_type == "s3" ? local.logging_usage.estimated_log_volume_gb * (local.logging_usage.retention_days / 30) : 0) * local.log_destination_pricing.s3.storage_per_gb_usd
      yearly_usd  = (var.log_destination_type == "s3" ? local.logging_usage.estimated_log_volume_gb * (local.logging_usage.retention_days / 30) : 0) * local.log_destination_pricing.s3.storage_per_gb_usd * 12
      notes       = "Экономичен для архива [citation:7]"
    },
    {
      line_no     = 6
      service     = "S3"
      component   = "PUTRequests"
      description = "S3: PUT-запросы"
      unit        = "per 1k requests"
      quantity    = var.log_destination_type == "s3" ? ceil(local.logging_usage.monthly_queries_millions * 1000000 / 1000) : 0
      unit_price  = local.log_destination_pricing.s3.put_requests_per_1k_usd
      monthly_usd = (var.log_destination_type == "s3" ? ceil(local.logging_usage.monthly_queries_millions * 1000000 / 1000) : 0) * local.log_destination_pricing.s3.put_requests_per_1k_usd
      yearly_usd  = (var.log_destination_type == "s3" ? ceil(local.logging_usage.monthly_queries_millions * 1000000 / 1000) : 0) * local.log_destination_pricing.s3.put_requests_per_1k_usd * 12
      notes       = "Batch-запросы снижают стоимость"
    },
    {
      line_no     = 7
      service     = "Firehose"
      component   = "DataTransfer"
      description = "Kinesis Data Firehose: Передача"
      unit        = "per GB"
      quantity    = var.log_destination_type == "firehose" ? local.logging_usage.estimated_log_volume_gb : 0
      unit_price  = local.log_destination_pricing.firehose.data_transfer_per_gb_usd
      monthly_usd = (var.log_destination_type == "firehose" ? local.logging_usage.estimated_log_volume_gb : 0) * local.log_destination_pricing.firehose.data_transfer_per_gb_usd
      yearly_usd  = (var.log_destination_type == "firehose" ? local.logging_usage.estimated_log_volume_gb : 0) * local.log_destination_pricing.firehose.data_transfer_per_gb_usd * 12
      notes       = "Для стриминга в реальном времени [citation:7]"
    },
    {
      line_no     = 8
      service     = "Route53Resolver"
      component   = "Association"
      description = "Query Log Config Association"
      unit        = "n/a"
      quantity    = local.logging_usage.vpc_associations
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Ресурс не тарифицируется"
    },
  ]

  # ------------------------------------------------------------------
  # СЕКЦИЯ 6: Расширенная разбивка по категориям (для дашбордов)
  # ------------------------------------------------------------------
  cost_by_category = {
    "Logging.Route53"     = 0.00
    "Logging.CloudWatch"  = (var.log_destination_type == "cloudwatch" ? local.logging_usage.estimated_log_volume_gb * local.log_destination_pricing.cloudwatch.ingestion_per_gb_usd : 0) + (var.log_destination_type == "cloudwatch" ? local.logging_usage.estimated_log_volume_gb * (local.logging_usage.retention_days / 30) * local.log_destination_pricing.cloudwatch.storage_per_gb_usd : 0) + (local.logging_usage.estimated_log_volume_gb * local.log_destination_pricing.cloudwatch.vended_logs_per_gb_usd)
    "Logging.S3"          = (var.log_destination_type == "s3" ? local.logging_usage.estimated_log_volume_gb * (local.logging_usage.retention_days / 30) * local.log_destination_pricing.s3.storage_per_gb_usd : 0) + (var.log_destination_type == "s3" ? ceil(local.logging_usage.monthly_queries_millions * 1000000 / 1000) * local.log_destination_pricing.s3.put_requests_per_1k_usd : 0)
    "Logging.Firehose"    = (var.log_destination_type == "firehose" ? local.logging_usage.estimated_log_volume_gb * local.log_destination_pricing.firehose.data_transfer_per_gb_usd : 0)
    "Logging.Association" = 0.00
  }

  cost_by_service = {
    "Route53Resolver" = 0.00
    "CloudWatch"      = (var.log_destination_type == "cloudwatch" ? local.logging_usage.estimated_log_volume_gb * local.log_destination_pricing.cloudwatch.ingestion_per_gb_usd : 0) + (var.log_destination_type == "cloudwatch" ? local.logging_usage.estimated_log_volume_gb * (local.logging_usage.retention_days / 30) * local.log_destination_pricing.cloudwatch.storage_per_gb_usd : 0) + (local.logging_usage.estimated_log_volume_gb * local.log_destination_pricing.cloudwatch.vended_logs_per_gb_usd)
    "S3"              = (var.log_destination_type == "s3" ? local.logging_usage.estimated_log_volume_gb * (local.logging_usage.retention_days / 30) * local.log_destination_pricing.s3.storage_per_gb_usd : 0) + (var.log_destination_type == "s3" ? ceil(local.logging_usage.monthly_queries_millions * 1000000 / 1000) * local.log_destination_pricing.s3.put_requests_per_1k_usd : 0)
    "Firehose"        = (var.log_destination_type == "firehose" ? local.logging_usage.estimated_log_volume_gb * local.log_destination_pricing.firehose.data_transfer_per_gb_usd : 0)
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
      description          = "Текущая конфигурация (${var.log_destination_type}, ${local.logging_usage.estimated_log_volume_gb} GB/мес)"
      destination          = var.log_destination_type
      log_volume_gb        = local.logging_usage.estimated_log_volume_gb
      monthly_usd          = local.cost_monthly_total
    }
    "cloudwatch_low" = {
      description          = "CloudWatch, низкий объём (10 GB/мес)"
      destination          = "cloudwatch"
      log_volume_gb        = 10
      monthly_usd          = (10 * local.log_destination_pricing.cloudwatch.ingestion_per_gb_usd) + (10 * (var.cloudwatch_log_retention_days / 30) * local.log_destination_pricing.cloudwatch.storage_per_gb_usd) + (10 * local.log_destination_pricing.cloudwatch.vended_logs_per_gb_usd)
    }
    "s3_high" = {
      description          = "S3, высокий объём (200 GB/мес)"
      destination          = "s3"
      log_volume_gb        = 200
      monthly_usd          = (200 * (var.s3_log_retention_days / 30) * local.log_destination_pricing.s3.storage_per_gb_usd) + (ceil(200 * 1024 / 1000) * local.log_destination_pricing.s3.put_requests_per_1k_usd) + (200 * local.log_destination_pricing.cloudwatch.vended_logs_per_gb_usd)
    }
    "firehose_realtime" = {
      description          = "Kinesis Firehose для стриминга"
      destination          = "firehose"
      log_volume_gb        = local.logging_usage.estimated_log_volume_gb
      monthly_usd          = (local.logging_usage.estimated_log_volume_gb * local.log_destination_pricing.firehose.data_transfer_per_gb_usd) + (local.logging_usage.estimated_log_volume_gb * local.log_destination_pricing.cloudwatch.vended_logs_per_gb_usd)
    }
    "no_logging" = {
      description          = "Без логирования"
      destination          = "none"
      log_volume_gb        = 0
      monthly_usd          = 0.00
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 9: Алерты и пороги (имитация для AWS Budgets)
  # ------------------------------------------------------------------
  budget_thresholds = {
    monthly_warning      = 100.00
    monthly_critical     = 200.00
    yearly_max           = 2000.00
    notify_emails        = ["finops@example.com", "devops@example.com"]
    alert_on_breach      = true
    log_volume_warning   = 100
    log_volume_crit      = 200
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 10: Метаданные отчёта
  # ------------------------------------------------------------------
  cost_report_metadata = {
    generated_by       = "terraform"
    project            = var.project_name
    environment        = var.environment
    query_log_config   = var.query_log_config_name
    log_destination    = var.log_destination_type
    vpc_id             = var.create_vpc ? aws_vpc.main[0].id : null
    aws_region         = var.aws_region
    currency           = local.cost_currency
    pricing_source     = "https://aws.amazon.com/route53/pricing/"
    pricing_date       = "2025-01-01"
    report_version     = "1.0.0"
    disclaimer         = "Это имитация. Для точных цифр используйте Infracost / AWS Cost Explorer."
    billing_note       = "Route53 Resolver Query Logging бесплатно. Плата за CloudWatch/S3/Firehose [citation:2][citation:8]"
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 11: Проверка лимитов и квот (имитация)
  # ------------------------------------------------------------------
  quota_checks = {
    max_query_log_configs_per_region = 10
    max_associations_per_config      = 100
    current_configs                  = 1
    current_associations             = local.logging_usage.vpc_associations
    configs_ok                       = 1 <= 10
    associations_ok                  = local.logging_usage.vpc_associations <= 100
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 12: Детализация по целевым сервисам (для документации)
  # ------------------------------------------------------------------
  destination_details = {
    "cloudwatch" = {
      description     = "CloudWatch Logs log group"
      pros            = "Logs Insights, метрики, алерты"
      cons            = "Дороже для больших объёмов"
      retention       = "Настраивается (1 день - 10 лет)"
    }
    "s3" = {
      description     = "S3 bucket"
      pros            = "Экономичен для долгосрочного архивирования [citation:7]"
      cons            = "Выше latency, нет real-time анализа"
      retention       = "Lifecycle policies"
    }
    "firehose" = {
      description     = "Kinesis Data Firehose delivery stream"
      pros            = "Real-time стриминг в Elasticsearch, Redshift [citation:7]"
      cons            = "Дополнительная стоимость передачи"
      retention       = "Зависит от назначения"
    }
  }
}