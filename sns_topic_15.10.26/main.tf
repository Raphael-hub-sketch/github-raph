# main.tf
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

locals {
  sns_pricing = {
    publish_standard_per_million_usd     = 0.50
    publish_fifo_per_million_usd         = 0.30
    fifo_payload_per_gb_usd              = 0.017
    free_tier_publishes_millions         = 1
    delivery_http_per_million_usd        = 0.60
    delivery_email_per_100k_usd          = 2.00
    delivery_mobile_push_per_million_usd = 0.50
    delivery_sqs_per_million_usd         = 0.00
    delivery_lambda_per_million_usd      = 0.00
    delivery_firehose_per_million_usd    = 0.85
    sms_us_per_message_usd               = 0.00645
    sms_uk_per_message_usd               = 0.04000
    sms_de_per_message_usd               = 0.07920
    sms_in_per_message_usd               = 0.02723
    sms_au_per_message_usd               = 0.04920
    data_transfer_out_per_gb_usd         = 0.09
    hours_per_month                      = 730
    hours_per_year                       = 8760
  }

  sns_usage = {
    monthly_publishes_millions = 10
    subscribers_sqs            = 3
    subscribers_lambda         = 2
    subscribers_http           = 1
    subscribers_email          = 1
    subscribers_mobile_push    = 1
    subscribers_firehose       = 0
    monthly_sms_count          = 10000
    sms_destination            = "us"
    avg_payload_kb             = 5
    data_transfer_out_gb       = 5
  }

  cost_breakdown = {
    publish_standard = {
      description = "SNS Publish: Standard"
      quantity    = max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions)
      unit_price  = local.sns_pricing.publish_standard_per_million_usd
      monthly_usd = var.fifo_topic ? 0 : max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd
      yearly_usd  = var.fifo_topic ? 0 : max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd * 12
      notes       = "Free tier: 1M/мес"
    }
    publish_fifo = {
      description = "SNS Publish: FIFO"
      quantity    = var.fifo_topic ? local.sns_usage.monthly_publishes_millions : 0
      unit_price  = local.sns_pricing.publish_fifo_per_million_usd
      monthly_usd = var.fifo_topic ? local.sns_usage.monthly_publishes_millions * local.sns_pricing.publish_fifo_per_million_usd : 0
      yearly_usd  = var.fifo_topic ? local.sns_usage.monthly_publishes_millions * local.sns_pricing.publish_fifo_per_million_usd * 12 : 0
      notes       = "Нет free tier"
    }
    fifo_payload = {
      description = "FIFO Payload Data"
      quantity    = var.fifo_topic ? local.sns_usage.monthly_publishes_millions * 1000000 * local.sns_usage.avg_payload_kb / 1024 / 1024 : 0
      unit_price  = local.sns_pricing.fifo_payload_per_gb_usd
      monthly_usd = var.fifo_topic ? local.sns_usage.monthly_publishes_millions * 1000000 * local.sns_usage.avg_payload_kb / 1024 / 1024 * local.sns_pricing.fifo_payload_per_gb_usd : 0
      yearly_usd  = var.fifo_topic ? local.sns_usage.monthly_publishes_millions * 1000000 * local.sns_usage.avg_payload_kb / 1024 / 1024 * local.sns_pricing.fifo_payload_per_gb_usd * 12 : 0
      notes       = "Каждое сообщение до 256KB = 1 message, min 1KB"
    }
    delivery_sqs = {
      description = "SNS Delivery: SQS"
      quantity    = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_sqs
      unit_price  = local.sns_pricing.delivery_sqs_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_sqs * local.sns_pricing.delivery_sqs_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_sqs * local.sns_pricing.delivery_sqs_per_million_usd * 12
      notes       = "Бесплатно"
    }
    delivery_lambda = {
      description = "SNS Delivery: Lambda"
      quantity    = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_lambda
      unit_price  = local.sns_pricing.delivery_lambda_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_lambda * local.sns_pricing.delivery_lambda_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_lambda * local.sns_pricing.delivery_lambda_per_million_usd * 12
      notes       = "Бесплатно"
    }
    delivery_http = {
      description = "SNS Delivery: HTTP"
      quantity    = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_http
      unit_price  = local.sns_pricing.delivery_http_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_http * local.sns_pricing.delivery_http_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_http * local.sns_pricing.delivery_http_per_million_usd * 12
      notes       = "Failed retries тоже тарифицируются"
    }
    delivery_email = {
      description = "SNS Delivery: Email"
      quantity    = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_email * 1000000 / 100000
      unit_price  = local.sns_pricing.delivery_email_per_100k_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_email * 1000000 / 100000 * local.sns_pricing.delivery_email_per_100k_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_email * 1000000 / 100000 * local.sns_pricing.delivery_email_per_100k_usd * 12
      notes       = "В 20 раз дороже mobile push"
    }
    delivery_mobile_push = {
      description = "SNS Delivery: Mobile Push"
      quantity    = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_mobile_push
      unit_price  = local.sns_pricing.delivery_mobile_push_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_mobile_push * local.sns_pricing.delivery_mobile_push_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_mobile_push * local.sns_pricing.delivery_mobile_push_per_million_usd * 12
      notes       = "Самый дешёвый user-facing канал"
    }
    delivery_firehose = {
      description = "SNS Delivery: Firehose"
      quantity    = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_firehose
      unit_price  = local.sns_pricing.delivery_firehose_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_firehose * local.sns_pricing.delivery_firehose_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_firehose * local.sns_pricing.delivery_firehose_per_million_usd * 12
      notes       = "Firehose ingestion + delivery отдельно"
    }
    delivery_sms = {
      description = "SNS Delivery: SMS"
      quantity    = local.sns_usage.monthly_sms_count
      unit_price  = local.sns_usage.sms_destination == "us" ? local.sns_pricing.sms_us_per_message_usd : (local.sns_usage.sms_destination == "uk" ? local.sns_pricing.sms_uk_per_message_usd : (local.sns_usage.sms_destination == "de" ? local.sns_pricing.sms_de_per_message_usd : (local.sns_usage.sms_destination == "in" ? local.sns_pricing.sms_in_per_message_usd : local.sns_pricing.sms_au_per_message_usd)))
      monthly_usd = local.sns_usage.monthly_sms_count * (local.sns_usage.sms_destination == "us" ? local.sns_pricing.sms_us_per_message_usd : (local.sns_usage.sms_destination == "uk" ? local.sns_pricing.sms_uk_per_message_usd : (local.sns_usage.sms_destination == "de" ? local.sns_pricing.sms_de_per_message_usd : (local.sns_usage.sms_destination == "in" ? local.sns_pricing.sms_in_per_message_usd : local.sns_pricing.sms_au_per_message_usd))))
      yearly_usd  = local.sns_usage.monthly_sms_count * (local.sns_usage.sms_destination == "us" ? local.sns_pricing.sms_us_per_message_usd : (local.sns_usage.sms_destination == "uk" ? local.sns_pricing.sms_uk_per_message_usd : (local.sns_usage.sms_destination == "de" ? local.sns_pricing.sms_de_per_message_usd : (local.sns_usage.sms_destination == "in" ? local.sns_pricing.sms_in_per_message_usd : local.sns_pricing.sms_au_per_message_usd)))) * 12
      notes       = "Самая волатильная статья"
    }
    data_transfer = {
      description = "Data Transfer Out"
      quantity    = local.sns_usage.data_transfer_out_gb
      unit_price  = local.sns_pricing.data_transfer_out_per_gb_usd
      monthly_usd = local.sns_usage.data_transfer_out_gb * local.sns_pricing.data_transfer_out_per_gb_usd
      yearly_usd  = local.sns_usage.data_transfer_out_gb * local.sns_pricing.data_transfer_out_per_gb_usd * 12
      notes       = "$0.09/GB"
    }
  }

  cost_monthly_total = sum([for k, v in local.cost_breakdown : v.monthly_usd])
  cost_yearly_total  = sum([for k, v in local.cost_breakdown : v.yearly_usd])
  cost_currency      = "USD"

  cost_line_items = [
    {
      line_no     = 1
      service     = "SNS"
      component   = "Publish.Standard"
      description = "SNS Publish: Standard"
      unit        = "per million"
      quantity    = max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions)
      unit_price  = local.sns_pricing.publish_standard_per_million_usd
      monthly_usd = var.fifo_topic ? 0 : max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd
      yearly_usd  = var.fifo_topic ? 0 : max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd * 12
      notes       = "$0.50/млн"
    },
    {
      line_no     = 2
      service     = "SNS"
      component   = "Publish.FIFO"
      description = "SNS Publish: FIFO"
      unit        = "per million"
      quantity    = var.fifo_topic ? local.sns_usage.monthly_publishes_millions : 0
      unit_price  = local.sns_pricing.publish_fifo_per_million_usd
      monthly_usd = var.fifo_topic ? local.sns_usage.monthly_publishes_millions * local.sns_pricing.publish_fifo_per_million_usd : 0
      yearly_usd  = var.fifo_topic ? local.sns_usage.monthly_publishes_millions * local.sns_pricing.publish_fifo_per_million_usd * 12 : 0
      notes       = "$0.30/млн"
    },
    {
      line_no     = 3
      service     = "SNS"
      component   = "Delivery.SQS"
      description = "SNS Delivery: SQS"
      unit        = "per million"
      quantity    = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_sqs
      unit_price  = local.sns_pricing.delivery_sqs_per_million_usd
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Бесплатно"
    },
    {
      line_no     = 4
      service     = "SNS"
      component   = "Delivery.Lambda"
      description = "SNS Delivery: Lambda"
      unit        = "per million"
      quantity    = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_lambda
      unit_price  = local.sns_pricing.delivery_lambda_per_million_usd
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Бесплатно"
    },
    {
      line_no     = 5
      service     = "SNS"
      component   = "Delivery.HTTP"
      description = "SNS Delivery: HTTP"
      unit        = "per million"
      quantity    = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_http
      unit_price  = local.sns_pricing.delivery_http_per_million_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_http * local.sns_pricing.delivery_http_per_million_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_http * local.sns_pricing.delivery_http_per_million_usd * 12
      notes       = "$0.60/млн"
    },
    {
      line_no     = 6
      service     = "SNS"
      component   = "Delivery.Email"
      description = "SNS Delivery: Email"
      unit        = "per 100k"
      quantity    = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_email * 1000000 / 100000
      unit_price  = local.sns_pricing.delivery_email_per_100k_usd
      monthly_usd = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_email * 1000000 / 100000 * local.sns_pricing.delivery_email_per_100k_usd
      yearly_usd  = local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_email * 1000000 / 100000 * local.sns_pricing.delivery_email_per_100k_usd * 12
      notes       = "$2.00/100K"
    },
    {
      line_no     = 7
      service     = "SNS"
      component   = "Delivery.SMS"
      description = "SNS Delivery: SMS"
      unit        = "per message"
      quantity    = local.sns_usage.monthly_sms_count
      unit_price  = local.sns_usage.sms_destination == "us" ? local.sns_pricing.sms_us_per_message_usd : local.sns_pricing.sms_uk_per_message_usd
      monthly_usd = local.sns_usage.monthly_sms_count * (local.sns_usage.sms_destination == "us" ? local.sns_pricing.sms_us_per_message_usd : local.sns_pricing.sms_uk_per_message_usd)
      yearly_usd  = local.sns_usage.monthly_sms_count * (local.sns_usage.sms_destination == "us" ? local.sns_pricing.sms_us_per_message_usd : local.sns_pricing.sms_uk_per_message_usd) * 12
      notes       = "От $0.00645"
    },
  ]

  cost_by_category = {
    "SNS.Publish"      = (var.fifo_topic ? local.sns_usage.monthly_publishes_millions * local.sns_pricing.publish_fifo_per_million_usd : max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd) + (var.fifo_topic ? local.sns_usage.monthly_publishes_millions * 1000000 * local.sns_usage.avg_payload_kb / 1024 / 1024 * local.sns_pricing.fifo_payload_per_gb_usd : 0)
    "SNS.Delivery"     = (local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_http * local.sns_pricing.delivery_http_per_million_usd) + (local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_email * 1000000 / 100000 * local.sns_pricing.delivery_email_per_100k_usd) + (local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_mobile_push * local.sns_pricing.delivery_mobile_push_per_million_usd) + (local.sns_usage.monthly_publishes_millions * local.sns_usage.subscribers_firehose * local.sns_pricing.delivery_firehose_per_million_usd)
    "SNS.SMS"          = local.sns_usage.monthly_sms_count * (local.sns_usage.sms_destination == "us" ? local.sns_pricing.sms_us_per_message_usd : local.sns_pricing.sms_uk_per_message_usd)
    "SNS.DataTransfer" = local.sns_usage.data_transfer_out_gb * local.sns_pricing.data_transfer_out_per_gb_usd
  }

  cost_by_service = {
    "SNS" = local.cost_monthly_total
  }

  cost_by_environment = {
    "${var.environment}" = local.cost_monthly_total
  }

  monthly_forecast = [
    for m in range(1, 13) : {
      month         = m
      month_name    = element([
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
      ], m - 1)
      base_usd      = local.cost_monthly_total
      growth_rate   = 0.02
      projected_usd = local.cost_monthly_total * pow(1.02, m - 1)
    }
  ]

  yearly_projection = {
    total_usd       = sum([for m in local.monthly_forecast : m.projected_usd])
    average_monthly = sum([for m in local.monthly_forecast : m.projected_usd]) / 12
    peak_month      = max([for m in local.monthly_forecast : m.projected_usd]...)
    lowest_month    = min([for m in local.monthly_forecast : m.projected_usd]...)
  }

  scenario_comparison = {
    "current" = {
      description       = "Текущая конфигурация"
      monthly_publishes = local.sns_usage.monthly_publishes_millions
      monthly_usd       = local.cost_monthly_total
    }
    "free_tier_only" = {
      description       = "Только Free Tier"
      monthly_publishes = 1
      monthly_usd       = 0.00
    }
    "sqs_lambda_only" = {
      description       = "Только SQS + Lambda"
      monthly_publishes = local.sns_usage.monthly_publishes_millions
      monthly_usd       = max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd
    }
    "email_heavy" = {
      description       = "Email-heavy (5 email, 100M)"
      monthly_publishes = 100
      monthly_usd       = max(0, 100 - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd + (100 * 5 * 1000000 / 100000 * local.sns_pricing.delivery_email_per_100k_usd)
    }
    "sms_heavy" = {
      description       = "SMS-heavy (100K SMS)"
      monthly_publishes = local.sns_usage.monthly_publishes_millions
      monthly_usd       = local.cost_monthly_total + (100000 * local.sns_pricing.sms_us_per_message_usd)
    }
    "fifo" = {
      description       = "FIFO вместо Standard"
      monthly_publishes = local.sns_usage.monthly_publishes_millions
      monthly_usd       = local.cost_monthly_total - (var.fifo_topic ? 0 : max(0, local.sns_usage.monthly_publishes_millions - local.sns_pricing.free_tier_publishes_millions) * local.sns_pricing.publish_standard_per_million_usd) + (local.sns_usage.monthly_publishes_millions * local.sns_pricing.publish_fifo_per_million_usd) + (local.sns_usage.monthly_publishes_millions * 1000000 * local.sns_usage.avg_payload_kb / 1024 / 1024 * local.sns_pricing.fifo_payload_per_gb_usd)
    }
  }

  budget_thresholds = {
    monthly_warning    = 50.00
    monthly_critical   = 100.00
    yearly_max         = 1000.00
    notify_emails      = ["finops@example.com", "devops@example.com"]
    alert_on_breach    = true
    sms_volume_warning = 50000
    sms_volume_crit    = 100000
  }

  cost_report_metadata = {
    generated_by   = "terraform"
    project        = var.project_name
    environment    = var.environment
    topic_name     = var.topic_name
    topic_type     = var.fifo_topic ? "FIFO" : "Standard"
    aws_region     = var.aws_region
    currency       = local.cost_currency
    pricing_source = "https://aws.amazon.com/sns/pricing/"
    pricing_date   = "2025-01-01"
    report_version = "1.0.0"
    disclaimer     = "Имитация. Для точных цифр используйте Infracost / AWS Cost Explorer."
    billing_note   = "SNS bills publish and delivery separately. SQS/Lambda delivery free"
  }

  quota_checks = {
    max_topics_per_account       = 100000
    max_subscriptions_per_topic  = 12500000
    max_message_size_standard_kb = 256
    max_message_size_fifo_kb     = 256
    current_topics               = 1
    current_subscriptions        = local.sns_usage.subscribers_sqs + local.sns_usage.subscribers_lambda + local.sns_usage.subscribers_http + local.sns_usage.subscribers_email + local.sns_usage.subscribers_mobile_push + local.sns_usage.subscribers_firehose
    topics_ok                    = 1 <= 100000
    subscriptions_ok             = (local.sns_usage.subscribers_sqs + local.sns_usage.subscribers_lambda + local.sns_usage.subscribers_http + local.sns_usage.subscribers_email + local.sns_usage.subscribers_mobile_push + local.sns_usage.subscribers_firehose) <= 12500000
  }

  subscriber_type_details = {
    "SQS" = {
      description   = "Amazon SQS queue"
      delivery_cost = "Free"
      notes         = "SQS billed separately"
    }
    "Lambda" = {
      description   = "AWS Lambda function"
      delivery_cost = "Free"
      notes         = "Lambda billed separately"
    }
    "HTTP/HTTPS" = {
      description   = "HTTP/HTTPS endpoint"
      delivery_cost = "$0.60/million"
      notes         = "Retries billable"
    }
    "Email" = {
      description   = "Email address"
      delivery_cost = "$2.00/100K"
      notes         = "20x more expensive"
    }
    "Mobile Push" = {
      description   = "Mobile push notification"
      delivery_cost = "$0.50/million"
      notes         = "Cheapest user-facing"
    }
    "SMS" = {
      description   = "SMS message"
      delivery_cost = "Varies by country"
      notes         = "Highest-variance"
    }
    "Kinesis Firehose" = {
      description   = "Kinesis Data Firehose"
      delivery_cost = "$0.85/million"
      notes         = "Firehose billed separately"
    }
  }
}