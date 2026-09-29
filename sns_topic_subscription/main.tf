# =====================================================================
# SNS Topic Subscription (основной ресурс)
# ---------------------------------------------------------------------
# Связывает endpoint (SQS, Lambda, HTTP, Email, SMS) с SNS topic.
# Сам ресурс не тарифицируется — плата за публикацию и доставку.
# =====================================================================
resource "aws_sns_topic_subscription" "main" {
  count = length(var.subscriptions)

  topic_arn = local.topic_arn
  protocol  = var.subscriptions[count.index].protocol
  endpoint  = var.subscriptions[count.index].endpoint

  # raw_message_delivery поддерживается только для SQS, HTTP/S и Firehose
  raw_message_delivery = contains(["sqs", "http", "https", "firehose"], var.subscriptions[count.index].protocol) ? var.subscriptions[count.index].raw_message_delivery : null

  # Фильтрация сообщений
  filter_policy       = var.subscriptions[count.index].filter_policy
  filter_policy_scope = var.subscriptions[count.index].filter_policy != null ? var.subscriptions[count.index].filter_policy_scope : null

  # DLQ для недоставленных сообщений
  redrive_policy = var.subscriptions[count.index].redrive_policy

  # Роль для Firehose
  subscription_role_arn = var.subscriptions[count.index].subscription_role_arn

  # Политика доставки (retry strategy)
  delivery_policy = var.subscriptions[count.index].delivery_policy

  # Политика replay
  replay_policy = var.subscriptions[count.index].replay_policy
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
  # Источник: https://aws.amazon.com/sns/pricing/ 
  # ------------------------------------------------------------------
  sns_pricing = {
    # --- Публикация ---
    publish_standard_per_million_usd      = 0.50   # Standard topics 
    publish_fifo_per_million_usd          = 0.30   # FIFO topics 
    fifo_payload_per_gb_usd               = 0.017  # FIFO payload data 
    free_tier_publishes_millions          = 1      # первые 1M бесплатно для Standard 

    # --- Доставка (per million, кроме email) ---
    delivery_sqs_per_million_usd          = 0.00   # SQS delivery бесплатно 
    delivery_lambda_per_million_usd       = 0.00   # Lambda delivery бесплатно 
    delivery_http_per_million_usd         = 0.60   # HTTP/HTTPS 
    delivery_email_per_100k_usd           = 2.00   # Email/Email-JSON 
    delivery_mobile_push_per_million_usd  = 0.50   # Mobile Push 
    delivery_firehose_per_million_usd     = 0.85   # Kinesis Data Firehose 

    # --- SMS (per message) ---
    sms_us_per_message_usd                = 0.00645 # США 
    sms_uk_per_message_usd                = 0.04000 # Великобритания 
    sms_de_per_message_usd                = 0.07920 # Германия 
    sms_in_per_message_usd                = 0.02723 # Индия 
    sms_au_per_message_usd                = 0.04920 # Австралия 

    # --- Data Transfer ---
    data_transfer_out_per_gb_usd          = 0.09   # Internet Data Transfer 

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

    # Средний размер payload (KB)
    avg_payload_kb                  = 5

    # SMS-сообщения (отдельно, т.к. тарификация per message)
    monthly_sms_count               = 10000
    sms_destination                 = "us"

    # Data transfer out (GB/мес)
    data_transfer_out_gb            = 5
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 3: Разбор подписок по типам (для расчёта)
  # ------------------------------------------------------------------
  subscriptions_by_protocol = {
    sqs       = [for s in var.subscriptions : s if s.protocol == "sqs"]
    lambda    = [for s in var.subscriptions : s if s.protocol == "lambda"]
    http      = [for s in var.subscriptions : s if contains(["http", "https"], s.protocol)]
    email     = [for s in var.subscriptions : s if contains(["email", "email-json"], s.protocol)]
    sms       = [for s in var.subscriptions : s if s.protocol == "sms"]
    firehose  = [for s in var.subscriptions : s if s.protocol == "firehose"]
  }

  subscription_counts = {
    sqs      = length(local.subscriptions_by_protocol.sqs)
    lambda   = length(local.subscriptions_by_protocol.lambda)
    http     = length(local.subscriptions_by_protocol.http)
    email    = length(local.subscriptions_by_protocol.email)
    sms      = length(local.subscriptions_by_protocol.sms)
    firehose = length(local.subscriptions_by_protocol.firehose)
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 4: Детализированный расчёт затрат (построчный)
  # ------------------------------------------------------------------
  cost_breakdown = {
    # --- Публикация ---
    publish = {
      description = "SNS Publish (${local.sns_usage.monthly_publishes_millions}M запросов)"
      quantity    = max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions)
      unit_price  = local.sns_pricing.publish_standard_per_million_usd
      monthly_usd = max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd
      yearly_usd  = max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd * 12
      notes       = "Free tier: 1M requests/month "
    }

    # --- Доставка: SQS ---
    delivery_sqs = {
      description = "SNS Delivery: SQS (${local.subscription_counts.sqs} подписчиков)"
      quantity    = local.sns_usage.monthly_publishes_millions * local.subscription_counts.sqs
      unit_price  = local.sns_pricing.delivery_sqs_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.subscription_counts.sqs * local.sns_pricing.delivery_sqs_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.subscription_counts.sqs * local.sns_pricing.delivery_sqs_per_million_usd * 12
      notes       = "SQS delivery free; SQS billed separately "
    }

    # --- Доставка: Lambda ---
    delivery_lambda = {
      description = "SNS Delivery: Lambda (${local.subscription_counts.lambda} подписчиков)"
      quantity    = local.sns_usage.monthly_publishes_millions * local.subscription_counts.lambda
      unit_price  = local.sns_pricing.delivery_lambda_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.subscription_counts.lambda * local.sns_pricing.delivery_lambda_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.subscription_counts.lambda * local.sns_pricing.delivery_lambda_per_million_usd * 12
      notes       = "Lambda delivery free; Lambda billed separately "
    }

    # --- Доставка: HTTP/HTTPS ---
    delivery_http = {
      description = "SNS Delivery: HTTP/HTTPS (${local.subscription_counts.http} подписчиков)"
      quantity    = local.sns_usage.monthly_publishes_millions * local.subscription_counts.http
      unit_price  = local.sns_pricing.delivery_http_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.subscription_counts.http * local.sns_pricing.delivery_http_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.subscription_counts.http * local.sns_pricing.delivery_http_per_million_usd * 12
      notes       = "Failed retries тоже тарифицируются "
    }

    # --- Доставка: Email ---
    delivery_email = {
      description = "SNS Delivery: Email (${local.subscription_counts.email} подписчиков)"
      quantity    = local.sns_usage.monthly_publishes_millions * local.subscription_counts.email * 1000000 / 100000
      unit_price  = local.sns_pricing.delivery_email_per_100k_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.subscription_counts.email * 1000000 / 100000 * local.sns_pricing.delivery_email_per_100k_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.subscription_counts.email * 1000000 / 100000 * local.sns_pricing.delivery_email_per_100k_usd * 12
      notes       = "Email в 20 раз дороже mobile push "
    }

    # --- Доставка: SMS ---
    delivery_sms = {
      description = "SNS Delivery: SMS (${local.sns_usage.monthly_sms_count} сообщений, ${local.sns_usage.sms_destination})"
      quantity    = local.sns_usage.monthly_sms_count
      unit_price  = local.sns_usage.sms_destination == "us" ? local.sns_pricing.sms_us_per_message_usd : (local.sns_usage.sms_destination == "uk" ? local.sns_pricing.sms_uk_per_message_usd : (local.sns_usage.sms_destination == "de" ? local.sns_pricing.sms_de_per_message_usd : (local.sns_usage.sms_destination == "in" ? local.sns_pricing.sms_in_per_message_usd : local.sns_pricing.sms_au_per_message_usd)))
      monthly_usd = local.sns_usage.monthly_sms_count * (local.sns_usage.sms_destination == "us" ? local.sns_pricing.sms_us_per_message_usd : (local.sns_usage.sms_destination == "uk" ? local.sns_pricing.sms_uk_per_message_usd : (local.sns_usage.sms_destination == "de" ? local.sns_pricing.sms_de_per_message_usd : (local.sns_usage.sms_destination == "in" ? local.sns_pricing.sms_in_per_message_usd : local.sns_pricing.sms_au_per_message_usd))))
      yearly_usd  = local.sns_usage.monthly_sms_count * (local.sns_usage.sms_destination == "us" ? local.sns_pricing.sms_us_per_message_usd : (local.sns_usage.sms_destination == "uk" ? local.sns_pricing.sms_uk_per_message_usd : (local.sns_usage.sms_destination == "de" ? local.sns_pricing.sms_de_per_message_usd : (local.sns_usage.sms_destination == "in" ? local.sns_pricing.sms_in_per_message_usd : local.sns_pricing.sms_au_per_message_usd)))) * 12
      notes       = "SMS — самая волатильная статья расходов "
    }

    # --- Доставка: Firehose ---
    delivery_firehose = {
      description = "SNS Delivery: Kinesis Firehose (${local.subscription_counts.firehose} подписчиков)"
      quantity    = local.sns_usage.monthly_publishes_millions * local.subscription_counts.firehose
      unit_price  = local.sns_pricing.delivery_firehose_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.subscription_counts.firehose * local.sns_pricing.delivery_firehose_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.subscription_counts.firehose * local.sns_pricing.delivery_firehose_per_million_usd * 12
      notes       = "Firehose ingestion + delivery billed separately "
    }

    # --- Data Transfer Out ---
    data_transfer = {
      description = "Data Transfer Out (${local.sns_usage.data_transfer_out_gb} GB/мес)"
      quantity    = local.sns_usage.data_transfer_out_gb
      unit_price  = local.sns_pricing.data_transfer_out_per_gb_usd
      monthly_usd = local.sns_usage.data_transfer_out_gb * local.sns_pricing.data_transfer_out_per_gb_usd
      yearly_usd  = local.sns_usage.data_transfer_out_gb * local.sns_pricing.data_transfer_out_per_gb_usd * 12
      notes       = "SQS/Lambda delivery transfer billed at Internet rates "
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
      service     = "SNS"
      component   = "Publish"
      description = "SNS Publish (${local.sns_usage.monthly_publishes_millions}M запросов)"
      unit        = "per million"
      quantity    = max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions)
      unit_price  = local.sns_pricing.publish_standard_per_million_usd
      monthly_usd = max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd
      yearly_usd  = max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd * 12
      notes       = "First 1M free per month, account-wide "
    },
    {
      line_no     = 2
      service     = "SNS"
      component   = "Delivery.SQS"
      description = "SNS Delivery: SQS (${local.subscription_counts.sqs} подписчиков)"
      unit        = "per million"
      quantity    = local.sns_usage.monthly_publishes_millions * local.subscription_counts.sqs
      unit_price  = local.sns_pricing.delivery_sqs_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.subscription_counts.sqs * local.sns_pricing.delivery_sqs_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.subscription_counts.sqs * local.sns_pricing.delivery_sqs_per_million_usd * 12
      notes       = "SQS delivery free; SQS billed separately "
    },
    {
      line_no     = 3
      service     = "SNS"
      component   = "Delivery.Lambda"
      description = "SNS Delivery: Lambda (${local.subscription_counts.lambda} подписчиков)"
      unit        = "per million"
      quantity    = local.sns_usage.monthly_publishes_millions * local.subscription_counts.lambda
      unit_price  = local.sns_pricing.delivery_lambda_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.subscription_counts.lambda * local.sns_pricing.delivery_lambda_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.subscription_counts.lambda * local.sns_pricing.delivery_lambda_per_million_usd * 12
      notes       = "Lambda delivery free; Lambda billed separately "
    },
    {
      line_no     = 4
      service     = "SNS"
      component   = "Delivery.HTTP"
      description = "SNS Delivery: HTTP/HTTPS (${local.subscription_counts.http} подписчиков)"
      unit        = "per million"
      quantity    = local.sns_usage.monthly_publishes_millions * local.subscription_counts.http
      unit_price  = local.sns_pricing.delivery_http_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.subscription_counts.http * local.sns_pricing.delivery_http_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.subscription_counts.http * local.sns_pricing.delivery_http_per_million_usd * 12
      notes       = "Retries to failing endpoints are billable "
    },
    {
      line_no     = 5
      service     = "SNS"
      component   = "Delivery.Email"
      description = "SNS Delivery: Email (${local.subscription_counts.email} подписчиков)"
      unit        = "per 100k"
      quantity    = local.sns_usage.monthly_publishes_millions * local.subscription_counts.email * 1000000 / 100000
      unit_price  = local.sns_pricing.delivery_email_per_100k_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.subscription_counts.email * 1000000 / 100000 * local.sns_pricing.delivery_email_per_100k_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.subscription_counts.email * 1000000 / 100000 * local.sns_pricing.delivery_email_per_100k_usd * 12
      notes       = "Email is 20x more expensive than mobile push "
    },
    {
      line_no     = 6
      service     = "SNS"
      component   = "Delivery.SMS"
      description = "SNS Delivery: SMS (${local.sns_usage.monthly_sms_count} сообщений, ${local.sns_usage.sms_destination})"
      unit        = "per message"
      quantity    = local.sns_usage.monthly_sms_count
      unit_price  = local.sns_usage.sms_destination == "us" ? local.sns_pricing.sms_us_per_message_usd : (local.sns_usage.sms_destination == "uk" ? local.sns_pricing.sms_uk_per_message_usd : (local.sns_usage.sms_destination == "de" ? local.sns_pricing.sms_de_per_message_usd : (local.sns_usage.sms_destination == "in" ? local.sns_pricing.sms_in_per_message_usd : local.sns_pricing.sms_au_per_message_usd)))
      monthly_usd = local.sns_usage.monthly_sms_count * (local.sns_usage.sms_destination == "us" ? local.sns_pricing.sms_us_per_message_usd : (local.sns_usage.sms_destination == "uk" ? local.sns_pricing.sms_uk_per_message_usd : (local.sns_usage.sms_destination == "de" ? local.sns_pricing.sms_de_per_message_usd : (local.sns_usage.sms_destination == "in" ? local.sns_pricing.sms_in_per_message_usd : local.sns_pricing.sms_au_per_message_usd))))
      yearly_usd  = local.sns_usage.monthly_sms_count * (local.sns_usage.sms_destination == "us" ? local.sns_pricing.sms_us_per_message_usd : (local.sns_usage.sms_destination == "uk" ? local.sns_pricing.sms_uk_per_message_usd : (local.sns_usage.sms_destination == "de" ? local.sns_pricing.sms_de_per_message_usd : (local.sns_usage.sms_destination == "in" ? local.sns_pricing.sms_in_per_message_usd : local.sns_pricing.sms_au_per_message_usd)))) * 12
      notes       = "SMS is highest-variance line item "
    },
    {
      line_no     = 7
      service     = "SNS"
      component   = "Delivery.Firehose"
      description = "SNS Delivery: Kinesis Firehose (${local.subscription_counts.firehose} подписчиков)"
      unit        = "per million"
      quantity    = local.sns_usage.monthly_publishes_millions * local.subscription_counts.firehose
      unit_price  = local.sns_pricing.delivery_firehose_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.subscription_counts.firehose * local.sns_pricing.delivery_firehose_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.subscription_counts.firehose * local.sns_pricing.delivery_firehose_per_million_usd * 12
      notes       = "Firehose ingestion + delivery billed separately "
    },
    {
      line_no     = 8
      service     = "SNS"
      component   = "DataTransfer"
      description = "Data Transfer Out (${local.sns_usage.data_transfer_out_gb} GB/мес)"
      unit        = "per GB"
      quantity    = local.sns_usage.data_transfer_out_gb
      unit_price  = local.sns_pricing.data_transfer_out_per_gb_usd
      monthly_usd = local.sns_usage.data_transfer_out_gb * local.sns_pricing.data_transfer_out_per_gb_usd
      yearly_usd  = local.sns_usage.data_transfer_out_gb * local.sns_pricing.data_transfer_out_per_gb_usd * 12
      notes       = "SQS/Lambda delivery transfer billed at Internet rates "
    }
  ]

  # ------------------------------------------------------------------
  # СЕКЦИЯ 7: Расширенная разбивка по категориям (для дашбордов)
  # ------------------------------------------------------------------
  cost_by_category = {
    "SNS.Publish"       = max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd
    "SNS.Delivery.Free" = (local.sns_usage.monthly_publishes_millions * local.subscription_counts.sqs * local.sns_pricing.delivery_sqs_per_million_usd) + (local.sns_usage.monthly_publishes_millions * local.subscription_counts.lambda * local.sns_pricing.delivery_lambda_per_million_usd)
    "SNS.Delivery.Paid" = (local.sns_usage.monthly_publishes_millions * local.subscription_counts.http * local.sns_pricing.delivery_http_per_million_usd) + (local.sns_usage.monthly_publishes_millions * local.subscription_counts.email * 1000000 / 100000 * local.sns_pricing.delivery_email_per_100k_usd) + (local.sns_usage.monthly_publishes_millions * local.subscription_counts.firehose * local.sns_pricing.delivery_firehose_per_million_usd)
    "SNS.SMS"           = local.sns_usage.monthly_sms_count * (local.sns_usage.sms_destination == "us" ? local.sns_pricing.sms_us_per_message_usd : (local.sns_usage.sms_destination == "uk" ? local.sns_pricing.sms_uk_per_message_usd : (local.sns_usage.sms_destination == "de" ? local.sns_pricing.sms_de_per_message_usd : (local.sns_usage.sms_destination == "in" ? local.sns_pricing.sms_in_per_message_usd : local.sns_pricing.sms_au_per_message_usd))))
    "SNS.DataTransfer"  = local.sns_usage.data_transfer_out_gb * local.sns_pricing.data_transfer_out_per_gb_usd
  }

  cost_by_service = {
    "SNS" = local.cost_monthly_total
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
  # СЕКЦИЯ 9: Сравнение сценариев (What-If analysis)
  # ------------------------------------------------------------------
  scenario_comparison = {
    "current" = {
      description          = "Текущая конфигурация (${local.sns_usage.monthly_publishes_millions}M publishes, ${length(var.subscriptions)} подписок)"
      monthly_publishes    = local.sns_usage.monthly_publishes_millions
      subscriptions        = length(var.subscriptions)
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
      monthly_usd          = max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd
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
    "no_subscriptions" = {
      description          = "Только публикация без подписок"
      monthly_publishes    = local.sns_usage.monthly_publishes_millions
      monthly_usd          = max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 10: Алерты и пороги (имитация для AWS Budgets)
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
  # СЕКЦИЯ 11: Метаданные отчёта
  # ------------------------------------------------------------------
  cost_report_metadata = {
    generated_by       = "terraform"
    project            = var.project_name
    environment        = var.environment
    topic_name         = var.topic_name
    topic_arn          = local.topic_arn
    subscription_count = length(var.subscriptions)
    aws_region         = var.aws_region
    currency           = local.cost_currency
    pricing_source     = "https://aws.amazon.com/sns/pricing/ "
    pricing_date       = "2025-01-01"
    report_version     = "1.0.0"
    disclaimer         = "Это имитация. Для точных цифр используйте Infracost / AWS Cost Explorer."
    billing_note       = "SNS bills publish and delivery separately. SQS/Lambda delivery is free "
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 12: Проверка лимитов и квот (имитация)
  # ------------------------------------------------------------------
  quota_checks = {
    max_subscriptions_per_topic       = 12500000
    max_message_size_standard_kb      = 256
    current_subscriptions             = length(var.subscriptions)
    subscriptions_ok                  = length(var.subscriptions) <= 12500000
    fifo_compatible                   = !contains([for s in var.subscriptions : s.protocol], "email") && !contains([for s in var.subscriptions : s.protocol], "sms") && !contains([for s in var.subscriptions : s.protocol], "http") && !contains([for s in var.subscriptions : s.protocol], "https")
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 13: Детализация по типам подписчиков (для документации)
  # ------------------------------------------------------------------
  subscriber_type_details = {
    "sqs" = {
      description     = "Amazon SQS queue"
      delivery_cost   = "Free"
      notes           = "SQS billed separately "
      raw_message     = true
    }
    "lambda" = {
      description     = "AWS Lambda function"
      delivery_cost   = "Free"
      notes           = "Lambda billed separately; raw_message_delivery NOT supported "
      raw_message     = false
    }
    "http/https" = {
      description     = "HTTP/HTTPS endpoint"
      delivery_cost   = "$0.60/million"
      notes           = "Retries to failing endpoints are billable "
      raw_message     = true
    }
    "email/email-json" = {
      description     = "Email address"
      delivery_cost   = "$2.00/100K"
      notes           = "20x more expensive than mobile push "
      raw_message     = false
    }
    "sms" = {
      description     = "SMS message"
      delivery_cost   = "Varies by country"
      notes           = "Highest-variance line item "
      raw_message     = false
    }
    "firehose" = {
      description     = "Kinesis Data Firehose delivery stream"
      delivery_cost   = "$0.85/million"
      notes           = "Firehose ingestion + delivery billed separately; requires subscription_role_arn "
      raw_message     = true
    }
  }
}