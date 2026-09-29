# =====================================================================
# SNS Topic (основной ресурс)
# =====================================================================
resource "aws_sns_topic" "main" {
  name         = var.topic_name
  display_name = var.display_name

  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.fifo_topic ? var.content_based_deduplication : null

  kms_master_key_id = var.kms_master_key_id

  tags = merge(local.common_tags, {
    Name = var.topic_name
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
  # СЕКЦИЯ 1: Справочник цен AWS SNS (us-east-1, 2024-2025)
  # Источник: https://aws.amazon.com/sns/pricing/ [citation:1][citation:6]
  # ------------------------------------------------------------------
  sns_pricing = {
    # --- Публикация ---
    publish_standard_per_million_usd      = 0.50   # Standard topics [citation:11]
    publish_fifo_per_million_usd          = 0.30   # FIFO topics [citation:11]
    fifo_payload_per_gb_usd               = 0.017  # FIFO payload data [citation:11]
    free_tier_publishes_millions          = 1      # первые 1M бесплатно для Standard [citation:17]

    # --- Доставка (per million, кроме email) ---
    delivery_http_per_million_usd         = 0.60   # HTTP/HTTPS [citation:11]
    delivery_email_per_100k_usd           = 2.00   # Email/Email-JSON [citation:11]
    delivery_mobile_push_per_million_usd  = 0.50   # Mobile Push [citation:11]
    delivery_sqs_per_million_usd          = 0.00   # SQS delivery бесплатно [citation:11]
    delivery_lambda_per_million_usd       = 0.00   # Lambda delivery бесплатно [citation:11]
    delivery_firehose_per_million_usd     = 0.85   # Kinesis Data Firehose [citation:11]

    # --- SMS (per message) ---
    sms_us_per_message_usd                = 0.00645 # США [citation:11]
    sms_international_low_per_message_usd = 0.04    # дешёвые страны [citation:11]
    sms_international_high_per_message_usd = 0.50   # редкие страны [citation:11]

    # --- Дополнительно ---
    cross_region_transfer_per_gb_usd      = 0.02   # Cross-region delivery transfer [citation:11]

    # Часов в месяце (30 дней)
    hours_per_month                       = 720
    hours_per_year                        = 8760
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 2: Прогнозируемое потребление (имитация)
  # ------------------------------------------------------------------
  sns_usage = {
    # Количество публикаций в месяц (в миллионах)
    monthly_publishes_millions      = 10

    # Количество подписчиков каждого типа
    subscribers_sqs                 = 3
    subscribers_lambda              = 2
    subscribers_http                = 1
    subscribers_email               = 1
    subscribers_mobile_push         = 1
    subscribers_firehose            = 0

    # SMS-сообщения (отдельно, т.к. тарификация per message)
    monthly_sms_count               = 10000
    sms_destination                 = "us"  # us, international_low, international_high

    # Средний размер payload (KB)
    avg_payload_kb                  = 5

    # Cross-region delivery (GB/мес)
    cross_region_transfer_gb        = 0
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 3: Детализированный расчёт затрат (построчный)
  # ------------------------------------------------------------------
  cost_breakdown = {
    # --- Публикация: Standard ---
    publish_standard = {
      description = "SNS Publish: Standard topics (первые 1M бесплатно)"
      quantity    = max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions)
      unit_price  = local.sns_pricing.publish_standard_per_million_usd
      monthly_usd = var.fifo_topic ? 0 : max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd
      yearly_usd  = var.fifo_topic ? 0 : max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd * 12
      notes       = "Free tier: 1M requests/month [citation:17]"
    }

    # --- Публикация: FIFO ---
    publish_fifo = {
      description = "SNS Publish: FIFO topics (нет free tier)"
      quantity    = var.fifo_topic ? local.sns_usage.monthly_publishes_millions : 0
      unit_price  = local.sns_pricing.publish_fifo_per_million_usd
      monthly_usd = var.fifo_topic ? local.sns_usage.monthly_publishes_millions * local.sns_pricing.publish_fifo_per_million_usd : 0
      yearly_usd  = var.fifo_topic ? local.sns_usage.monthly_publishes_millions * local.sns_pricing.publish_fifo_per_million_usd * 12 : 0
      notes       = "FIFO publish + payload data charges [citation:11]"
    }

    # --- FIFO Payload Data ---
    fifo_payload = {
      description = "FIFO Payload Data (GB)"
      quantity    = var.fifo_topic ? local.sns_usage.monthly_publishes_millions * 1000000 * local.sns_usage.avg_payload_kb / 1024 / 1024 : 0
      unit_price  = local.sns_pricing.fifo_payload_per_gb_usd
      monthly_usd = var.fifo_topic ? local.sns_usage.monthly_publishes_millions * 1000000 * local.sns_usage.avg_payload_kb / 1024 / 1024 * local.sns_pricing.fifo_payload_per_gb_usd : 0
      yearly_usd  = var.fifo_topic ? local.sns_usage.monthly_publishes_millions * 1000000 * local.sns_usage.avg_payload_kb / 1024 / 1024 * local.sns_pricing.fifo_payload_per_gb_usd * 12 : 0
      notes       = "Каждое сообщение до 256KB тарифицируется как 1 message, минимум 1KB [citation:1]"
    }

    # --- Доставка: SQS ---
    delivery_sqs = {
      description = "SNS Delivery: SQS (${local.sns_usage.subscribers_sqs} подписчиков)"
      quantity    = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_sqs
      unit_price  = local.sns_pricing.delivery_sqs_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_sqs * local.sns_pricing.delivery_sqs_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_sqs * local.sns_pricing.delivery_sqs_per_million_usd * 12
      notes       = "SQS delivery бесплатно; SQS тарифицируется отдельно [citation:11]"
    }

    # --- Доставка: Lambda ---
    delivery_lambda = {
      description = "SNS Delivery: Lambda (${local.sns_usage.subscribers_lambda} подписчиков)"
      quantity    = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_lambda
      unit_price  = local.sns_pricing.delivery_lambda_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_lambda * local.sns_pricing.delivery_lambda_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_lambda * local.sns_pricing.delivery_lambda_per_million_usd * 12
      notes       = "Lambda delivery бесплатно; Lambda тарифицируется отдельно [citation:11]"
    }

    # --- Доставка: HTTP/HTTPS ---
    delivery_http = {
      description = "SNS Delivery: HTTP/HTTPS (${local.sns_usage.subscribers_http} подписчиков)"
      quantity    = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_http
      unit_price  = local.sns_pricing.delivery_http_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_http * local.sns_pricing.delivery_http_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_http * local.sns_pricing.delivery_http_per_million_usd * 12
      notes       = "Failed retries тоже тарифицируются [citation:11]"
    }

    # --- Доставка: Email ---
    delivery_email = {
      description = "SNS Delivery: Email (${local.sns_usage.subscribers_email} подписчиков)"
      quantity    = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_email * 1000000 / 100000
      unit_price  = local.sns_pricing.delivery_email_per_100k_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_email * 1000000 / 100000 * local.sns_pricing.delivery_email_per_100k_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_email * 1000000 / 100000 * local.sns_pricing.delivery_email_per_100k_usd * 12
      notes       = "Email в 20 раз дороже mobile push [citation:11]"
    }

    # --- Доставка: Mobile Push ---
    delivery_mobile_push = {
      description = "SNS Delivery: Mobile Push (${local.sns_usage.subscribers_mobile_push} подписчиков)"
      quantity    = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_mobile_push
      unit_price  = local.sns_pricing.delivery_mobile_push_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_mobile_push * local.sns_pricing.delivery_mobile_push_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_mobile_push * local.sns_pricing.delivery_mobile_push_per_million_usd * 12
      notes       = "Самый дешёвый user-facing канал [citation:11]"
    }

    # --- Доставка: Firehose ---
    delivery_firehose = {
      description = "SNS Delivery: Kinesis Firehose (${local.sns_usage.subscribers_firehose} подписчиков)"
      quantity    = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_firehose
      unit_price  = local.sns_pricing.delivery_firehose_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_firehose * local.sns_pricing.delivery_firehose_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_firehose * local.sns_pricing.delivery_firehose_per_million_usd * 12
      notes       = "Firehose ingestion + delivery тарифицируются отдельно [citation:11]"
    }

    # --- SMS ---
    sms_delivery = {
      description = "SNS Delivery: SMS (${local.sns_usage.monthly_sms_count} сообщений, ${local.sns_usage.sms_destination})"
      quantity    = local.sns_usage.monthly_sms_count
      unit_price  = local.sns_usage.sms_destination == "us" ? local.sns_pricing.sms_us_per_message_usd : (local.sns_usage.sms_destination == "international_low" ? local.sns_pricing.sms_international_low_per_message_usd : local.sns_pricing.sms_international_high_per_message_usd)
      monthly_usd = local.sns_usage.monthly_sms_count * (local.sns_usage.sms_destination == "us" ? local.sns_pricing.sms_us_per_message_usd : (local.sns_usage.sms_destination == "international_low" ? local.sns_pricing.sms_international_low_per_message_usd : local.sns_pricing.sms_international_high_per_message_usd))
      yearly_usd  = local.sns_usage.monthly_sms_count * (local.sns_usage.sms_destination == "us" ? local.sns_pricing.sms_us_per_message_usd : (local.sns_usage.sms_destination == "international_low" ? local.sns_pricing.sms_international_low_per_message_usd : local.sns_pricing.sms_international_high_per_message_usd)) * 12
      notes       = "SMS — самая волатильная статья расходов [citation:11]"
    }

    # --- Cross-region transfer ---
    cross_region = {
      description = "Cross-region delivery transfer"
      quantity    = local.sns_usage.cross_region_transfer_gb
      unit_price  = local.sns_pricing.cross_region_transfer_per_gb_usd
      monthly_usd = local.sns_usage.cross_region_transfer_gb * local.sns_pricing.cross_region_transfer_per_gb_usd
      yearly_usd  = local.sns_usage.cross_region_transfer_gb * local.sns_pricing.cross_region_transfer_per_gb_usd * 12
      notes       = "Дополнительно к publish + delivery [citation:11]"
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
      service     = "SNS"
      component   = "Publish.Standard"
      description = "SNS Publish: Standard topics"
      unit        = "per million"
      quantity    = max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions)
      unit_price  = local.sns_pricing.publish_standard_per_million_usd
      monthly_usd = var.fifo_topic ? 0 : max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd
      yearly_usd  = var.fifo_topic ? 0 : max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd * 12
      notes       = "First 1M free per month, account-wide [citation:17]"
    },
    {
      line_no     = 2
      service     = "SNS"
      component   = "Publish.FIFO"
      description = "SNS Publish: FIFO topics"
      unit        = "per million"
      quantity    = var.fifo_topic ? local.sns_usage.monthly_publishes_millions : 0
      unit_price  = local.sns_pricing.publish_fifo_per_million_usd
      monthly_usd = var.fifo_topic ? local.sns_usage.monthly_publishes_millions * local.sns_pricing.publish_fifo_per_million_usd : 0
      yearly_usd  = var.fifo_topic ? local.sns_usage.monthly_publishes_millions * local.sns_pricing.publish_fifo_per_million_usd * 12 : 0
      notes       = "FIFO has no free tier [citation:17]"
    },
    {
      line_no     = 3
      service     = "SNS"
      component   = "Publish.FIFO.Payload"
      description = "FIFO Payload Data"
      unit        = "per GB"
      quantity    = var.fifo_topic ? local.sns_usage.monthly_publishes_millions * 1000000 * local.sns_usage.avg_payload_kb / 1024 / 1024 : 0
      unit_price  = local.sns_pricing.fifo_payload_per_gb_usd
      monthly_usd = var.fifo_topic ? local.sns_usage.monthly_publishes_millions * 1000000 * local.sns_usage.avg_payload_kb / 1024 / 1024 * local.sns_pricing.fifo_payload_per_gb_usd : 0
      yearly_usd  = var.fifo_topic ? local.sns_usage.monthly_publishes_millions * 1000000 * local.sns_usage.avg_payload_kb / 1024 / 1024 * local.sns_pricing.fifo_payload_per_gb_usd * 12 : 0
      notes       = "Each message up to 256KB billed as 1 message, min 1KB [citation:1]"
    },
    {
      line_no     = 4
      service     = "SNS"
      component   = "Delivery.SQS"
      description = "SNS Delivery: SQS"
      unit        = "per million"
      quantity    = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_sqs
      unit_price  = local.sns_pricing.delivery_sqs_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_sqs * local.sns_pricing.delivery_sqs_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_sqs * local.sns_pricing.delivery_sqs_per_million_usd * 12
      notes       = "SQS delivery free; SQS billed separately [citation:11]"
    },
    {
      line_no     = 5
      service     = "SNS"
      component   = "Delivery.Lambda"
      description = "SNS Delivery: Lambda"
      unit        = "per million"
      quantity    = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_lambda
      unit_price  = local.sns_pricing.delivery_lambda_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_lambda * local.sns_pricing.delivery_lambda_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_lambda * local.sns_pricing.delivery_lambda_per_million_usd * 12
      notes       = "Lambda delivery free; Lambda billed separately [citation:11]"
    },
    {
      line_no     = 6
      service     = "SNS"
      component   = "Delivery.HTTP"
      description = "SNS Delivery: HTTP/HTTPS"
      unit        = "per million"
      quantity    = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_http
      unit_price  = local.sns_pricing.delivery_http_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_http * local.sns_pricing.delivery_http_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_http * local.sns_pricing.delivery_http_per_million_usd * 12
      notes       = "Retries to failing endpoints are billable [citation:11]"
    },
    {
      line_no     = 7
      service     = "SNS"
      component   = "Delivery.Email"
      description = "SNS Delivery: Email"
      unit        = "per 100k"
      quantity    = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_email * 1000000 / 100000
      unit_price  = local.sns_pricing.delivery_email_per_100k_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_email * 1000000 / 100000 * local.sns_pricing.delivery_email_per_100k_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_email * 1000000 / 100000 * local.sns_pricing.delivery_email_per_100k_usd * 12
      notes       = "Email is 20x more expensive than mobile push [citation:11]"
    },
    {
      line_no     = 8
      service     = "SNS"
      component   = "Delivery.MobilePush"
      description = "SNS Delivery: Mobile Push"
      unit        = "per million"
      quantity    = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_mobile_push
      unit_price  = local.sns_pricing.delivery_mobile_push_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_mobile_push * local.sns_pricing.delivery_mobile_push_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_mobile_push * local.sns_pricing.delivery_mobile_push_per_million_usd * 12
      notes       = "Cheapest user-facing delivery channel [citation:11]"
    },
    {
      line_no     = 9
      service     = "SNS"
      component   = "Delivery.SMS"
      description = "SNS Delivery: SMS"
      unit        = "per message"
      quantity    = local.sns_usage.monthly_sms_count
      unit_price  = local.sns_usage.sms_destination == "us" ? local.sns_pricing.sms_us_per_message_usd : (local.sns_usage.sms_destination == "international_low" ? local.sns_pricing.sms_international_low_per_message_usd : local.sns_pricing.sms_international_high_per_message_usd)
      monthly_usd = local.sns_usage.monthly_sms_count * (local.sns_usage.sms_destination == "us" ? local.sns_pricing.sms_us_per_message_usd : (local.sns_usage.sms_destination == "international_low" ? local.sns_pricing.sms_international_low_per_message_usd : local.sns_pricing.sms_international_high_per_message_usd))
      yearly_usd  = local.sns_usage.monthly_sms_count * (local.sns_usage.sms_destination == "us" ? local.sns_pricing.sms_us_per_message_usd : (local.sns_usage.sms_destination == "international_low" ? local.sns_pricing.sms_international_low_per_message_usd : local.sns_pricing.sms_international_high_per_message_usd)) * 12
      notes       = "SMS is highest-variance line item [citation:11]"
    },
  ]

  # ------------------------------------------------------------------
  # СЕКЦИЯ 6: Расширенная разбивка по категориям (для дашбордов)
  # ------------------------------------------------------------------
  cost_by_category = {
    "SNS.Publish"         = (var.fifo_topic ? local.sns_usage.monthly_publishes_millions * local.sns_pricing.publish_fifo_per_million_usd : max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd) + (var.fifo_topic ? local.sns_usage.monthly_publishes_millions * 1000000 * local.sns_usage.avg_payload_kb / 1024 / 1024 * local.sns_pricing.fifo_payload_per_gb_usd : 0)
    "SNS.Delivery"        = (local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_sqs * local.sns_pricing.delivery_sqs_per_million_usd) + (local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_lambda * local.sns_pricing.delivery_lambda_per_million_usd) + (local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_http * local.sns_pricing.delivery_http_per_million_usd) + (local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_email * 1000000 / 100000 * local.sns_pricing.delivery_email_per_100k_usd) + (local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_mobile_push * local.sns_pricing.delivery_mobile_push_per_million_usd) + (local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_firehose * local.sns_pricing.delivery_firehose_per_million_usd)
    "SNS.SMS"             = local.sns_usage.monthly_sms_count * (local.sns_usage.sms_destination == "us" ? local.sns_pricing.sms_us_per_message_usd : (local.sns_usage.sms_destination == "international_low" ? local.sns_pricing.sms_international_low_per_message_usd : local.sns_pricing.sms_international_high_per_message_usd))
    "SNS.CrossRegion"     = local.sns_usage.cross_region_transfer_gb * local.sns_pricing.cross_region_transfer_per_gb_usd
  }

  cost_by_service = {
    "SNS" = local.cost_monthly_total
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
      description          = "Текущая конфигурация (${local.sns_usage.monthly_publishes_millions}M publishes, ${local.sns_usage.subscribers_sqs + local.sns_usage.subscribers_lambda + local.sns_usage.subscribers_http + local.sns_usage.subscribers_email + local.sns_usage.subscribers_mobile_push} подписчиков)"
      monthly_publishes    = local.sns_usage.monthly_publishes_millions
      monthly_usd          = local.cost_monthly_total
    }
    "free_tier_only" = {
      description          = "Только Free Tier (1M publishes, SQS/Lambda delivery)"
      monthly_publishes    = 1
      monthly_usd          = 0.00
    }
    "sqs_lambda_only" = {
      description          = "Только SQS + Lambda (бесплатная доставка)"
      monthly_publishes    = local.sns_usage.monthly_publishes_millions
      monthly_usd          = (var.fifo_topic ? local.sns_usage.monthly_publishes_millions * local.sns_pricing.publish_fifo_per_million_usd : max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd)
    }
    "email_heavy" = {
      description          = "Email-heavy (5 email подписчиков, 100M publishes)"
      monthly_publishes    = 100
      monthly_usd          = max(0, 100 - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd + (100 * 5 * 1000000 / 100000 * local.sns_pricing.delivery_email_per_100k_usd)
    }
    "sms_heavy" = {
      description          = "SMS-heavy (100K SMS в США)"
      monthly_publishes    = local.sns_usage.monthly_publishes_millions
      monthly_usd          = local.cost_monthly_total + (100000 * local.sns_pricing.sms_us_per_message_usd)
    }
    "fifo" = {
      description          = "FIFO вместо Standard"
      monthly_publishes    = local.sns_usage.monthly_publishes_millions
      monthly_usd          = local.cost_monthly_total - (var.fifo_topic ? 0 : max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd) + (local.sns_usage.monthly_publishes_millions * local.sns_pricing.publish_fifo_per_million_usd) + (local.sns_usage.monthly_publishes_millions * 1000000 * local.sns_usage.avg_payload_kb / 1024 / 1024 * local.sns_pricing.fifo_payload_per_gb_usd)
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 9: Алерты и пороги (имитация для AWS Budgets)
  # ------------------------------------------------------------------
  budget_thresholds = {
    monthly_warning      = 50.00
    monthly_critical     = 100.00
    yearly_max           = 1000.00
    notify_emails        = ["finops@example.com", "devops@example.com"]
    alert_on_breach      = true
    sms_volume_warning   = 50000
    sms_volume_crit      = 100000
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 10: Метаданные отчёта
  # ------------------------------------------------------------------
  cost_report_metadata = {
    generated_by       = "terraform"
    project            = var.project_name
    environment        = var.environment
    topic_name         = var.topic_name
    topic_type         = var.fifo_topic ? "FIFO" : "Standard"
    aws_region         = var.aws_region
    currency           = local.cost_currency
    pricing_source     = "https://aws.amazon.com/sns/pricing/ [citation:1][citation:6]"
    pricing_date       = "2025-01-01"
    report_version     = "1.0.0"
    disclaimer         = "Это имитация. Для точных цифр используйте Infracost / AWS Cost Explorer."
    billing_note       = "SNS bills publish and delivery separately. SQS/Lambda delivery is free [citation:11]"
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 11: Проверка лимитов и квот (имитация)
  # ------------------------------------------------------------------
  quota_checks = {
    max_topics_per_account            = 100000
    max_subscriptions_per_topic       = 12500000
    max_message_size_standard_kb      = 256
    max_message_size_fifo_kb          = 256
    current_topics                    = 1
    current_subscriptions             = local.sns_usage.subscribers_sqs + local.sns_usage.subscribers_lambda + local.sns_usage.subscribers_http + local.sns_usage.subscribers_email + local.sns_usage.subscribers_mobile_push + local.sns_usage.subscribers_firehose
    topics_ok                         = 1 <= 100000
    subscriptions_ok                  = (local.sns_usage.subscribers_sqs + local.sns_usage.subscribers_lambda + local.sns_usage.subscribers_http + local.sns_usage.subscribers_email + local.sns_usage.subscribers_mobile_push + local.sns_usage.subscribers_firehose) <= 12500000
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 12: Детализация по типам подписчиков (для документации)
  # ------------------------------------------------------------------
  subscriber_type_details = {
    "SQS" = {
      description     = "Amazon SQS queue"
      delivery_cost   = "Free"
      notes           = "SQS billed separately [citation:11]"
    }
    "Lambda" = {
      description     = "AWS Lambda function"
      delivery_cost   = "Free"
      notes           = "Lambda billed separately [citation:11]"
    }
    "HTTP/HTTPS" = {
      description     = "HTTP/HTTPS endpoint"
      delivery_cost   = "$0.60/million"
      notes           = "Retries to failing endpoints are billable [citation:11]"
    }
    "Email" = {
      description     = "Email address"
      delivery_cost   = "$2.00/100K"
      notes           = "20x more expensive than mobile push [citation:11]"
    }
    "Mobile Push" = {
      description     = "Mobile push notification"
      delivery_cost   = "$0.50/million"
      notes           = "Cheapest user-facing channel [citation:11]"
    }
    "SMS" = {
      description     = "SMS message"
      delivery_cost   = "Varies by country ($0.00645 - $0.50+)"
      notes           = "Highest-variance line item [citation:11]"
    }
    "Kinesis Firehose" = {
      description     = "Kinesis Data Firehose delivery stream"
      delivery_cost   = "$0.85/million"
      notes           = "Firehose ingestion + delivery billed separately [citation:11]"
    }
  }
}