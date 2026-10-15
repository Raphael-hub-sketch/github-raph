# main.tf
resource "aws_sns_platform_application" "main" {
  name = var.platform_app_name

  platform            = var.platform
  platform_credential = var.platform_credential
  platform_principal  = var.platform_principal

  event_endpoint_created_topic_arn = var.create_event_topics ? aws_sns_topic.event_endpoint_created[0].arn : null
  event_endpoint_updated_topic_arn = var.create_event_topics ? aws_sns_topic.event_endpoint_updated[0].arn : null
  event_endpoint_deleted_topic_arn = var.create_event_topics ? aws_sns_topic.event_endpoint_deleted[0].arn : null
  event_delivery_failure_topic_arn = var.create_event_topics ? aws_sns_topic.event_delivery_failure[0].arn : null

  success_feedback_sample_rate = var.success_feedback_sample_rate

  tags = merge(local.common_tags, {
    Name = var.platform_app_name
  })
}

locals {
  push_pricing = {
    publish_per_million_usd       = 0.50
    free_tier_publishes_millions  = 1
    push_delivery_per_million_usd = 0.50
    free_tier_push_millions       = 1
    data_transfer_per_gb_usd      = 0.09
    free_tier_transfer_gb         = 100
    payload_chunk_kb              = 64
    hours_per_month               = 730
    hours_per_year                = 8760
  }

  push_usage = {
    devices_count               = 50000
    monthly_publishes_millions  = 2
    monthly_deliveries_millions = 2
    avg_payload_kb              = 4
    data_transfer_gb            = 5
    event_topics_count          = var.create_event_topics ? 4 : 0
  }

  cost_breakdown = {
    publish = {
      description = "SNS Publish (${local.push_usage.monthly_publishes_millions}M)"
      quantity    = max(0, local.push_usage.monthly_publishes_millions - local.push_pricing.free_tier_publishes_millions)
      unit_price  = local.push_pricing.publish_per_million_usd
      monthly_usd = max(0, local.push_usage.monthly_publishes_millions - local.push_pricing.free_tier_publishes_millions) * local.push_pricing.publish_per_million_usd
      yearly_usd  = max(0, local.push_usage.monthly_publishes_millions - local.push_pricing.free_tier_publishes_millions) * local.push_pricing.publish_per_million_usd * 12
      notes       = "Free tier: 1M/мес"
    }
    delivery = {
      description = "Mobile Push Delivery (${local.push_usage.monthly_deliveries_millions}M)"
      quantity    = max(0, local.push_usage.monthly_deliveries_millions - local.push_pricing.free_tier_push_millions)
      unit_price  = local.push_pricing.push_delivery_per_million_usd
      monthly_usd = max(0, local.push_usage.monthly_deliveries_millions - local.push_pricing.free_tier_push_millions) * local.push_pricing.push_delivery_per_million_usd
      yearly_usd  = max(0, local.push_usage.monthly_deliveries_millions - local.push_pricing.free_tier_push_millions) * local.push_pricing.push_delivery_per_million_usd * 12
      notes       = "Free tier: 1M/мес"
    }
    data_transfer = {
      description = "Data Transfer (${local.push_usage.data_transfer_gb} GB)"
      quantity    = max(0, local.push_usage.data_transfer_gb - local.push_pricing.free_tier_transfer_gb)
      unit_price  = local.push_pricing.data_transfer_per_gb_usd
      monthly_usd = max(0, local.push_usage.data_transfer_gb - local.push_pricing.free_tier_transfer_gb) * local.push_pricing.data_transfer_per_gb_usd
      yearly_usd  = max(0, local.push_usage.data_transfer_gb - local.push_pricing.free_tier_transfer_gb) * local.push_pricing.data_transfer_per_gb_usd * 12
      notes       = "Free tier: 100 GB"
    }
    platform_app = {
      description = "Platform Application (сам ресурс)"
      quantity    = 1
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Не тарифицируется"
    }
    event_topics = {
      description = "Event Topics (${local.push_usage.event_topics_count} шт.)"
      quantity    = local.push_usage.event_topics_count
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Сами топики бесплатны"
    }
  }

  cost_monthly_total = sum([for k, v in local.cost_breakdown : v.monthly_usd])
  cost_yearly_total  = sum([for k, v in local.cost_breakdown : v.yearly_usd])
  cost_currency      = "USD"

  cost_line_items = [
    {
      line_no     = 1
      service     = "SNS"
      component   = "Publish"
      description = "SNS Publish"
      unit        = "per million"
      quantity    = max(0, local.push_usage.monthly_publishes_millions - local.push_pricing.free_tier_publishes_millions)
      unit_price  = local.push_pricing.publish_per_million_usd
      monthly_usd = max(0, local.push_usage.monthly_publishes_millions - local.push_pricing.free_tier_publishes_millions) * local.push_pricing.publish_per_million_usd
      yearly_usd  = max(0, local.push_usage.monthly_publishes_millions - local.push_pricing.free_tier_publishes_millions) * local.push_pricing.publish_per_million_usd * 12
      notes       = "$0.50/млн, 1M free"
    },
    {
      line_no     = 2
      service     = "SNS"
      component   = "Delivery.MobilePush"
      description = "Mobile Push Delivery"
      unit        = "per million"
      quantity    = max(0, local.push_usage.monthly_deliveries_millions - local.push_pricing.free_tier_push_millions)
      unit_price  = local.push_pricing.push_delivery_per_million_usd
      monthly_usd = max(0, local.push_usage.monthly_deliveries_millions - local.push_pricing.free_tier_push_millions) * local.push_pricing.push_delivery_per_million_usd
      yearly_usd  = max(0, local.push_usage.monthly_deliveries_millions - local.push_pricing.free_tier_push_millions) * local.push_pricing.push_delivery_per_million_usd * 12
      notes       = "$0.50/млн, 1M free"
    },
    {
      line_no     = 3
      service     = "SNS"
      component   = "DataTransfer"
      description = "Data Transfer"
      unit        = "per GB"
      quantity    = max(0, local.push_usage.data_transfer_gb - local.push_pricing.free_tier_transfer_gb)
      unit_price  = local.push_pricing.data_transfer_per_gb_usd
      monthly_usd = max(0, local.push_usage.data_transfer_gb - local.push_pricing.free_tier_transfer_gb) * local.push_pricing.data_transfer_per_gb_usd
      yearly_usd  = max(0, local.push_usage.data_transfer_gb - local.push_pricing.free_tier_transfer_gb) * local.push_pricing.data_transfer_per_gb_usd * 12
      notes       = "$0.09/GB после 100 GB"
    },
    {
      line_no     = 4
      service     = "SNS"
      component   = "PlatformApplication"
      description = "Platform Application ресурс"
      unit        = "n/a"
      quantity    = 1
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Бесплатно"
    },
  ]

  cost_by_category = {
    "SNS.Publish"        = max(0, local.push_usage.monthly_publishes_millions - local.push_pricing.free_tier_publishes_millions) * local.push_pricing.publish_per_million_usd
    "SNS.Delivery"       = max(0, local.push_usage.monthly_deliveries_millions - local.push_pricing.free_tier_push_millions) * local.push_pricing.push_delivery_per_million_usd
    "SNS.DataTransfer"   = max(0, local.push_usage.data_transfer_gb - local.push_pricing.free_tier_transfer_gb) * local.push_pricing.data_transfer_per_gb_usd
    "SNS.PlatformApp"    = 0.00
    "SNS.EventTopics"    = 0.00
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
      description   = "Текущая конфигурация"
      publishes_mil = local.push_usage.monthly_publishes_millions
      deliveries_mil = local.push_usage.monthly_deliveries_millions
      monthly_usd   = local.cost_monthly_total
    }
    "free_tier_only" = {
      description   = "Только Free Tier"
      publishes_mil = 1
      deliveries_mil = 1
      monthly_usd   = 0.00
    }
    "low_traffic" = {
      description   = "Низкий трафик (0.5M)"
      publishes_mil = 0.5
      deliveries_mil = 0.5
      monthly_usd   = 0.00
    }
    "high_traffic" = {
      description   = "Высокий трафик (100M)"
      publishes_mil = 100
      deliveries_mil = 100
      monthly_usd   = (100 - 1) * local.push_pricing.publish_per_million_usd + (100 - 1) * local.push_pricing.push_delivery_per_million_usd
    }
    "ios_android" = {
      description   = "iOS + Android (2 приложения)"
      publishes_mil = 4
      deliveries_mil = 4
      monthly_usd   = (4 - 1) * local.push_pricing.publish_per_million_usd + (4 - 1) * local.push_pricing.push_delivery_per_million_usd
    }
  }

  budget_thresholds = {
    monthly_warning = 5.00
    monthly_critical = 10.00
    yearly_max      = 100.00
    notify_emails   = ["finops@example.com", "devops@example.com"]
    alert_on_breach = true
    delivery_warning_mil = 50
    delivery_crit_mil    = 100
  }

  cost_report_metadata = {
    generated_by   = "terraform"
    project        = var.project_name
    environment    = var.environment
    platform_app   = var.platform_app_name
    platform       = var.platform
    aws_region     = var.aws_region
    currency       = local.cost_currency
    pricing_source = "https://aws.amazon.com/sns/pricing/"
    pricing_date   = "2025-01-01"
    report_version = "1.0.0"
    disclaimer     = "Имитация. Для точных цифр используйте Infracost / AWS Cost Explorer."
    billing_note   = "Platform Application не тарифицируется. Плата за publish + delivery"
  }

  quota_checks = {
    max_platform_apps_per_account     = 100
    max_endpoints_per_platform_app    = 10000000
    max_event_topics                  = 4
    current_platform_apps             = 1
    current_endpoints                 = local.push_usage.devices_count
    current_event_topics              = local.push_usage.event_topics_count
    apps_ok                           = 1 <= 100
    endpoints_ok                      = local.push_usage.devices_count <= 10000000
  }

  platform_details = {
    "APNS" = {
      description = "Apple Push Notification Service (production)"
      credential  = "Certificate .p12 или Token .p8"
      principal   = "Не требуется"
    }
    "APNS_SANDBOX" = {
      description = "Apple Push Notification Service (sandbox)"
      credential  = "Certificate .p12 или Token .p8"
      principal   = "Не требуется"
    }
    "GCM" = {
      description = "Firebase Cloud Messaging (Android)"
      credential  = "API Key"
      principal   = "Не требуется"
    }
    "ADM" = {
      description = "Amazon Device Messaging"
      credential  = "Client Secret"
      principal   = "Client ID"
    }
    "BAIDU" = {
      description = "Baidu Cloud Push"
      credential  = "Secret Key"
      principal   = "API Key"
    }
    "MPNS" = {
      description = "Microsoft Push Notification Service"
      credential  = "Certificate"
      principal   = "Не требуется"
    }
    "WNS" = {
      description = "Windows Push Notification Service"
      credential  = "Package Security Identifier"
      principal   = "Secret Key"
    }
  }
}