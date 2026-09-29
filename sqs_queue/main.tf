# =====================================================================
# SQS Queue (основной ресурс)
# =====================================================================
resource "aws_sqs_queue" "main" {
  name = var.queue_name

  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.fifo_queue ? var.content_based_deduplication : null

  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  max_message_size           = var.max_message_size
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  delay_seconds              = var.delay_seconds

  sqs_managed_sse_enabled = var.sqs_managed_sse_enabled

  # Redrive policy для DLQ
  redrive_policy = var.create_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : null

  tags = merge(local.common_tags, {
    Name = var.queue_name
  })
}

# =====================================================================
# Dead Letter Queue (DLQ)
# =====================================================================
resource "aws_sqs_queue" "dlq" {
  count = var.create_dlq ? 1 : 0

  name = var.fifo_queue ? "${replace(var.queue_name, ".fifo", "")}-dlq.fifo" : "${var.queue_name}-dlq"

  fifo_queue = var.fifo_queue

  message_retention_seconds = 1209600  # 14 дней для DLQ
  sqs_managed_sse_enabled   = var.sqs_managed_sse_enabled

  tags = merge(local.common_tags, {
    Name = var.fifo_queue ? "${replace(var.queue_name, ".fifo", "")}-dlq.fifo" : "${var.queue_name}-dlq"
    Role = "dead-letter-queue"
  })
}

# =====================================================================
# Redrive Allow Policy (разрешение на redrive из DLQ)
# =====================================================================
resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  count = var.create_dlq ? 1 : 0

  queue_url = aws_sqs_queue.dlq[0].id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.main.arn]
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
  # СЕКЦИЯ 1: Справочник цен AWS SQS (us-east-1, 2024-2025)
  # Источник: https://aws.amazon.com/sqs/pricing/ [citation:1][citation:4]
  # ------------------------------------------------------------------
  sqs_pricing = {
    # --- Standard Queue ---
    standard_per_million_usd      = 0.40   # $0.40 за миллион запросов [citation:5][citation:8]
    
    # --- FIFO Queue ---
    fifo_per_million_usd          = 0.50   # $0.50 за миллион запросов (25% премия) [citation:5][citation:8]
    
    # --- Fair Queue ---
    fair_queue_per_million_usd    = 0.83   # дополнительно к Standard/FIFO [citation:2]
    
    # --- Free Tier ---
    free_tier_requests_millions   = 1      # 1 млн запросов бесплатно [citation:1][citation:4]
    
    # --- Payload Chunking ---
    payload_chunk_kb              = 64     # каждый 64KB = 1 запрос [citation:1][citation:4]
    
    # Часов в месяце (30 дней)
    hours_per_month               = 720
    hours_per_year                = 8760
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 2: Прогнозируемое потребление (имитация)
  # ------------------------------------------------------------------
  sqs_usage = {
    # Количество API-запросов в месяц (в миллионах)
    monthly_requests_millions     = 10
    
    # Средний размер сообщения (KB)
    avg_message_size_kb           = 5
    
    # Распределение запросов по типам (в процентах)
    send_percent                  = 30
    receive_percent               = 50
    delete_percent                = 20
    
    # Используется ли batching (снижает количество запросов)
    batching_enabled              = true
    batch_size                    = 10
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 3: Детализированный расчёт затрат (построчный)
  # ------------------------------------------------------------------
  cost_breakdown = {
    # --- API-запросы (Standard или FIFO) ---
    api_requests = {
      description = "SQS API-запросы (${var.fifo_queue ? "FIFO" : "Standard"})"
      quantity    = max(0, local.sqs_usage.monthly_requests_millions - local.sqs_pricing.free_tier_requests_millions)
      unit_price  = var.fifo_queue ? local.sqs_pricing.fifo_per_million_usd : local.sqs_pricing.standard_per_million_usd
      monthly_usd = max(0, local.sqs_usage.monthly_requests_millions - local.sqs_pricing.free_tier_requests_millions) * (var.fifo_queue ? local.sqs_pricing.fifo_per_million_usd : local.sqs_pricing.standard_per_million_usd)
      yearly_usd  = max(0, local.sqs_usage.monthly_requests_millions - local.sqs_pricing.free_tier_requests_millions) * (var.fifo_queue ? local.sqs_pricing.fifo_per_million_usd : local.sqs_pricing.standard_per_million_usd) * 12
      notes       = var.fifo_queue ? "FIFO дороже Standard на 25% [citation:5]" : "Standard дешевле FIFO [citation:5]"
    }

    # --- Payload Chunking (дополнительные запросы) ---
    payload_chunks = {
      description = "Payload chunking (64KB на запрос)"
      quantity    = local.sqs_usage.avg_message_size_kb > local.sqs_pricing.payload_chunk_kb ? ceil(local.sqs_usage.avg_message_size_kb / local.sqs_pricing.payload_chunk_kb) - 1 : 0
      unit_price  = var.fifo_queue ? local.sqs_pricing.fifo_per_million_usd : local.sqs_pricing.standard_per_million_usd
      monthly_usd = local.sqs_usage.avg_message_size_kb > local.sqs_pricing.payload_chunk_kb ? (ceil(local.sqs_usage.avg_message_size_kb / local.sqs_pricing.payload_chunk_kb) - 1) * local.sqs_usage.monthly_requests_millions * (var.fifo_queue ? local.sqs_pricing.fifo_per_million_usd : local.sqs_pricing.standard_per_million_usd) : 0
      yearly_usd  = local.sqs_usage.avg_message_size_kb > local.sqs_pricing.payload_chunk_kb ? (ceil(local.sqs_usage.avg_message_size_kb / local.sqs_pricing.payload_chunk_kb) - 1) * local.sqs_usage.monthly_requests_millions * (var.fifo_queue ? local.sqs_pricing.fifo_per_million_usd : local.sqs_pricing.standard_per_million_usd) * 12 : 0
      notes       = "Каждый 64KB payload = 1 запрос [citation:1][citation:4]"
    }

    # --- Fair Queue (если используется) ---
    fair_queue = {
      description = "Fair Queue дополнительная плата"
      quantity    = 0  # имитация: не используется
      unit_price  = local.sqs_pricing.fair_queue_per_million_usd
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Только для multi-tenant очередей с message group ID [citation:2]"
    }

    # --- KMS (если используется SSE-KMS) ---
    kms = {
      description = "KMS API calls (для SSE-KMS)"
      quantity    = 0  # имитация: используется SSE-SQS, не SSE-KMS
      unit_price  = 0.03  # $0.03 за 10K запросов
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "SSE-SQS бесплатно, SSE-KMS тарифицируется отдельно [citation:1]"
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
      service     = "SQS"
      component   = "APIRequests.${var.fifo_queue ? "FIFO" : "Standard"}"
      description = "SQS API-запросы (${local.sqs_usage.monthly_requests_millions}M запросов)"
      unit        = "per million"
      quantity    = max(0, local.sqs_usage.monthly_requests_millions - local.sqs_pricing.free_tier_requests_millions)
      unit_price  = var.fifo_queue ? local.sqs_pricing.fifo_per_million_usd : local.sqs_pricing.standard_per_million_usd
      monthly_usd = max(0, local.sqs_usage.monthly_requests_millions - local.sqs_pricing.free_tier_requests_millions) * (var.fifo_queue ? local.sqs_pricing.fifo_per_million_usd : local.sqs_pricing.standard_per_million_usd)
      yearly_usd  = max(0, local.sqs_usage.monthly_requests_millions - local.sqs_pricing.free_tier_requests_millions) * (var.fifo_queue ? local.sqs_pricing.fifo_per_million_usd : local.sqs_pricing.standard_per_million_usd) * 12
      notes       = "Free tier: 1M requests/month [citation:1]"
    },
    {
      line_no     = 2
      service     = "SQS"
      component   = "PayloadChunks"
      description = "Payload chunking (64KB на запрос)"
      unit        = "per million"
      quantity    = local.sqs_usage.avg_message_size_kb > 64 ? ceil(local.sqs_usage.avg_message_size_kb / 64) - 1 : 0
      unit_price  = var.fifo_queue ? local.sqs_pricing.fifo_per_million_usd : local.sqs_pricing.standard_per_million_usd
      monthly_usd = local.sqs_usage.avg_message_size_kb > 64 ? (ceil(local.sqs_usage.avg_message_size_kb / 64) - 1) * local.sqs_usage.monthly_requests_millions * (var.fifo_queue ? local.sqs_pricing.fifo_per_million_usd : local.sqs_pricing.standard_per_million_usd) : 0
      yearly_usd  = local.sqs_usage.avg_message_size_kb > 64 ? (ceil(local.sqs_usage.avg_message_size_kb / 64) - 1) * local.sqs_usage.monthly_requests_millions * (var.fifo_queue ? local.sqs_pricing.fifo_per_million_usd : local.sqs_pricing.standard_per_million_usd) * 12 : 0
      notes       = "Each 64KB chunk = 1 request [citation:1][citation:4]"
    },
    {
      line_no     = 3
      service     = "SQS"
      component   = "DataTransfer"
      description = "Data Transfer (same-region = free)"
      unit        = "n/a"
      quantity    = 0
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Free within same region [citation:1]"
    },
    {
      line_no     = 4
      service     = "SQS"
      component   = "Encryption"
      description = "SSE-SQS (бесплатно)"
      unit        = "n/a"
      quantity    = 1
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "SSE-SQS бесплатно; SSE-KMS тарифицируется отдельно [citation:1]"
    },
  ]

  # ------------------------------------------------------------------
  # СЕКЦИЯ 6: Расширенная разбивка по категориям (для дашбордов)
  # ------------------------------------------------------------------
  cost_by_category = {
    "SQS.APIRequests"  = max(0, local.sqs_usage.monthly_requests_millions - local.sqs_pricing.free_tier_requests_millions) * (var.fifo_queue ? local.sqs_pricing.fifo_per_million_usd : local.sqs_pricing.standard_per_million_usd)
    "SQS.PayloadChunks" = local.sqs_usage.avg_message_size_kb > 64 ? (ceil(local.sqs_usage.avg_message_size_kb / 64) - 1) * local.sqs_usage.monthly_requests_millions * (var.fifo_queue ? local.sqs_pricing.fifo_per_million_usd : local.sqs_pricing.standard_per_million_usd) : 0
    "SQS.FairQueue"    = 0.00
    "SQS.DataTransfer" = 0.00
    "SQS.Encryption"   = 0.00
  }

  cost_by_service = {
    "SQS" = local.cost_monthly_total
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
      description          = "Текущая конфигурация (${var.fifo_queue ? "FIFO" : "Standard"}, ${local.sqs_usage.monthly_requests_millions}M запросов)"
      queue_type           = var.fifo_queue ? "FIFO" : "Standard"
      monthly_requests     = local.sqs_usage.monthly_requests_millions
      monthly_usd          = local.cost_monthly_total
    }
    "free_tier_only" = {
      description          = "Только Free Tier (1M запросов)"
      monthly_requests     = 1
      monthly_usd          = 0.00
    }
    "standard_high" = {
      description          = "Standard, высокий трафик (100M запросов)"
      monthly_requests     = 100
      monthly_usd          = max(0, 100 - local.sqs_pricing.free_tier_requests_millions) * local.sqs_pricing.standard_per_million_usd
    }
    "fifo_high" = {
      description          = "FIFO, высокий трафик (100M запросов)"
      monthly_requests     = 100
      monthly_usd          = max(0, 100 - local.sqs_pricing.free_tier_requests_millions) * local.sqs_pricing.fifo_per_million_usd
    }
    "large_payload" = {
      description          = "Large payload (1MB, 10M запросов)"
      monthly_requests     = 10
      monthly_usd          = max(0, 10 - local.sqs_pricing.free_tier_requests_millions) * local.sqs_pricing.standard_per_million_usd * 16  # 1MB = 16 chunks
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 9: Алерты и пороги (имитация для AWS Budgets)
  # ------------------------------------------------------------------
  budget_thresholds = {
    monthly_warning      = 20.00
    monthly_critical     = 50.00
    yearly_max           = 500.00
    notify_emails        = ["finops@example.com", "devops@example.com"]
    alert_on_breach      = true
    request_volume_warning = 50
    request_volume_crit    = 100
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 10: Метаданные отчёта
  # ------------------------------------------------------------------
  cost_report_metadata = {
    generated_by       = "terraform"
    project            = var.project_name
    environment        = var.environment
    queue_name         = var.queue_name
    queue_type         = var.fifo_queue ? "FIFO" : "Standard"
    aws_region         = var.aws_region
    currency           = local.cost_currency
    pricing_source     = "https://aws.amazon.com/sqs/pricing/ [citation:1][citation:4]"
    pricing_date       = "2025-01-01"
    report_version     = "1.0.0"
    disclaimer         = "Это имитация. Для точных цифр используйте Infracost / AWS Cost Explorer."
    billing_note       = "SQS bills per API request. Each 64KB payload chunk = 1 request [citation:1]"
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 11: Проверка лимитов и квот (имитация)
  # ------------------------------------------------------------------
  quota_checks = {
    max_message_size_kb            = 256
    max_retention_seconds          = 1209600  # 14 дней
    max_visibility_timeout_seconds = 43200    # 12 часов
    current_message_size_kb        = local.sqs_usage.avg_message_size_kb
    current_retention_seconds      = var.message_retention_seconds
    message_size_ok                = local.sqs_usage.avg_message_size_kb <= 256
    retention_ok                   = var.message_retention_seconds <= 1209600
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 12: Детализация по типам очередей (для документации)
  # ------------------------------------------------------------------
  queue_type_details = {
    "Standard" = {
      description     = "Standard Queue"
      price_per_million = "$0.40"
      throughput      = "Nearly unlimited"
      ordering        = "Best-effort"
      delivery        = "At-least-once"
      use_cases       = "High-throughput, idempotent consumers [citation:5]"
    }
    "FIFO" = {
      description     = "FIFO Queue"
      price_per_million = "$0.50 (25% premium)"
      throughput      = "300 msg/s per group (3000 batched)"
      ordering        = "Strict (within message group)"
      delivery        = "Exactly-once"
      use_cases       = "Financial transactions, ordered state transitions [citation:5]"
    }
  }
}