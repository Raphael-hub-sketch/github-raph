# =====================================================================
# Route53 Registered Domain
# =====================================================================
resource "aws_route53domains_registered_domain" "main" {
  domain_name = var.domain_name

  # Автоматическое продление
  auto_renew = var.auto_renew

  # Блокировка трансфера
  transfer_lock = var.transfer_lock

  # Защита приватности WHOIS
  admin_privacy = var.privacy_protection
  registrant_privacy = var.privacy_protection
  tech_privacy = var.privacy_protection

  # Контакты
  admin_contact {
    first_name = var.registrant_contact.first_name
    last_name  = var.registrant_contact.last_name
    email      = var.registrant_contact.email
    phone      = var.registrant_contact.phone
    address_line_1 = var.registrant_contact.address
    city       = var.registrant_contact.city
    state      = var.registrant_contact.state
    zip_code   = var.registrant_contact.zip_code
    country_code = var.registrant_contact.country
  }

  registrant_contact {
    first_name = var.registrant_contact.first_name
    last_name  = var.registrant_contact.last_name
    email      = var.registrant_contact.email
    phone      = var.registrant_contact.phone
    address_line_1 = var.registrant_contact.address
    city       = var.registrant_contact.city
    state      = var.registrant_contact.state
    zip_code   = var.registrant_contact.zip_code
    country_code = var.registrant_contact.country
  }

  tech_contact {
    first_name = var.registrant_contact.first_name
    last_name  = var.registrant_contact.last_name
    email      = var.registrant_contact.email
    phone      = var.registrant_contact.phone
    address_line_1 = var.registrant_contact.address
    city       = var.registrant_contact.city
    state      = var.registrant_contact.state
    zip_code   = var.registrant_contact.zip_code
    country_code = var.registrant_contact.country
  }

  tags = merge(local.common_tags, {
    Name        = var.domain_name
    MonthlyCost = format("%.2f %s", local.cost_monthly_total, local.cost_currency)
    YearlyCost  = format("%.2f %s", local.cost_yearly_total, local.cost_currency)
  })
}

# =====================================================================
# ИМИТАЦИЯ ЗАТРАТ (Cost Simulation)
# ---------------------------------------------------------------------
# Ниже — развёрнутый блок, документирующий предполагаемые расходы.
# =====================================================================

locals {
  # ------------------------------------------------------------------
  # СЕКЦИЯ 1: Построчная детализация по каждому элементу затрат
  # ------------------------------------------------------------------
  cost_line_items = [
    {
      line_no     = 1
      service     = "Route53Domains"
      component   = "DomainRegistration"
      description = "Регистрация домена ${var.domain_name} (TLD: .${local.domain_usage.tld})"
      unit        = "year"
      quantity    = local.domain_usage.registration_years
      unit_price  = lookup(local.domain_pricing, local.domain_usage.tld, 15.00)
      yearly_usd  = local.domain_usage.registration_years * lookup(local.domain_pricing, local.domain_usage.tld, 15.00)
      monthly_usd = (local.domain_usage.registration_years * lookup(local.domain_pricing, local.domain_usage.tld, 15.00)) / 12
      notes       = "Ежегодный платёж, не возвращается"
    },
    {
      line_no     = 2
      service     = "Route53"
      component   = "HostedZone"
      description = "Hosted zone для ${var.domain_name}"
      unit        = "month"
      quantity    = 1
      unit_price  = local.domain_addons.hosted_zone_monthly
      monthly_usd = local.domain_addons.hosted_zone_monthly
      yearly_usd  = local.domain_addons.hosted_zone_monthly * 12
      notes       = "Создаётся автоматически при регистрации"
    },
    {
      line_no     = 3
      service     = "Route53"
      component   = "Queries.Standard"
      description = "Стандартные DNS-запросы"
      unit        = "per million"
      quantity    = local.domain_usage.monthly_queries_mil
      unit_price  = local.domain_addons.query_standard_per_mil
      monthly_usd = local.domain_usage.monthly_queries_mil * local.domain_addons.query_standard_per_mil
      yearly_usd  = local.domain_usage.monthly_queries_mil * local.domain_addons.query_standard_per_mil * 12
      notes       = "Оценка на основе исторических данных"
    },
    {
      line_no     = 4
      service     = "Route53"
      component   = "Queries.Latency"
      description = "Latency-based routing queries"
      unit        = "per million"
      quantity    = local.domain_usage.latency_queries_mil
      unit_price  = local.domain_addons.query_latency_per_mil
      monthly_usd = local.domain_usage.latency_queries_mil * local.domain_addons.query_latency_per_mil
      yearly_usd  = local.domain_usage.latency_queries_mil * local.domain_addons.query_latency_per_mil * 12
      notes       = "Используется для multi-region failover"
    },
    {
      line_no     = 5
      service     = "Route53"
      component   = "Queries.Geo"
      description = "Geolocation routing queries"
      unit        = "per million"
      quantity    = local.domain_usage.geo_queries_mil
      unit_price  = local.domain_addons.query_geo_per_mil
      monthly_usd = local.domain_usage.geo_queries_mil * local.domain_addons.query_geo_per_mil
      yearly_usd  = local.domain_usage.geo_queries_mil * local.domain_addons.query_geo_per_mil * 12
      notes       = "Гео-маршрутизация для EU/US"
    },
    {
      line_no     = 6
      service     = "Route53"
      component   = "HealthCheck.Basic"
      description = "Базовые health check"
      unit        = "check/month"
      quantity    = local.domain_usage.health_checks_basic
      unit_price  = local.domain_addons.health_check_monthly
      monthly_usd = local.domain_usage.health_checks_basic * local.domain_addons.health_check_monthly
      yearly_usd  = local.domain_usage.health_checks_basic * local.domain_addons.health_check_monthly * 12
      notes       = "Для primary endpoints"
    },
    {
      line_no     = 7
      service     = "Route53"
      component   = "DNSSEC"
      description = "DNSSEC signing"
      unit        = "month"
      quantity    = local.domain_usage.dnssec_enabled ? 1 : 0
      unit_price  = local.domain_addons.dnssec_yearly / 12
      monthly_usd = local.domain_usage.dnssec_enabled ? local.domain_addons.dnssec_yearly / 12 : 0
      yearly_usd  = local.domain_usage.dnssec_enabled ? local.domain_addons.dnssec_yearly : 0
      notes       = local.domain_usage.dnssec_enabled ? "Включено" : "Отключено"
    },
    {
      line_no     = 8
      service     = "Route53Domains"
      component   = "PrivacyProtection"
      description = "WHOIS Privacy Protection"
      unit        = "year"
      quantity    = local.domain_usage.privacy_protection ? 1 : 0
      unit_price  = local.domain_addons.privacy_protection_yearly
      monthly_usd = 0
      yearly_usd  = local.domain_usage.privacy_protection ? local.domain_addons.privacy_protection_yearly : 0
      notes       = "Часто бесплатно для .com, .net, .org"
    },
    {
      line_no     = 9
      service     = "Route53Domains"
      component   = "TransferLock"
      description = "Transfer Lock"
      unit        = "year"
      quantity    = local.domain_usage.transfer_lock ? 1 : 0
      unit_price  = local.domain_addons.transfer_lock_yearly
      monthly_usd = 0
      yearly_usd  = local.domain_usage.transfer_lock ? local.domain_addons.transfer_lock_yearly : 0
      notes       = "Бесплатная защита от несанкционированного трансфера"
    },
    {
      line_no     = 10
      service     = "Route53Domains"
      component   = "AutoRenew"
      description = "Автоматическое продление"
      unit        = "year"
      quantity    = local.domain_usage.auto_renew ? 1 : 0
      unit_price  = 0.00
      monthly_usd = 0
      yearly_usd  = 0
      notes       = "Бесплатно, но гарантирует непрерывность владения"
    },
  ]

  # ------------------------------------------------------------------
  # СЕКЦИЯ 2: Расширенная разбивка по категориям (для дашбордов)
  # ------------------------------------------------------------------
  cost_by_category = {
    "Domain.Registration" = local.domain_usage.registration_years * lookup(local.domain_pricing, local.domain_usage.tld, 15.00)
    "Domain.Addons"       = (local.domain_usage.privacy_protection ? local.domain_addons.privacy_protection_yearly : 0) + (local.domain_usage.transfer_lock ? local.domain_addons.transfer_lock_yearly : 0)
    "DNS.Zones"           = local.domain_addons.hosted_zone_monthly * 12
    "DNS.Queries"         = (local.domain_usage.monthly_queries_mil * local.domain_addons.query_standard_per_mil * 12) + (local.domain_usage.latency_queries_mil * local.domain_addons.query_latency_per_mil * 12) + (local.domain_usage.geo_queries_mil * local.domain_addons.query_geo_per_mil * 12)
    "DNS.HealthCheck"     = local.domain_usage.health_checks_basic * local.domain_addons.health_check_monthly * 12
    "DNS.Security"        = local.domain_usage.dnssec_enabled ? local.domain_addons.dnssec_yearly : 0
  }

  cost_by_service = {
    "Route53Domains" = (local.domain_usage.registration_years * lookup(local.domain_pricing, local.domain_usage.tld, 15.00)) + (local.domain_usage.privacy_protection ? local.domain_addons.privacy_protection_yearly : 0) + (local.domain_usage.transfer_lock ? local.domain_addons.transfer_lock_yearly : 0)
    "Route53"        = (local.domain_addons.hosted_zone_monthly * 12) + (local.domain_usage.monthly_queries_mil * local.domain_addons.query_standard_per_mil * 12) + (local.domain_usage.latency_queries_mil * local.domain_addons.query_latency_per_mil * 12) + (local.domain_usage.geo_queries_mil * local.domain_addons.query_geo_per_mil * 12) + (local.domain_usage.health_checks_basic * local.domain_addons.health_check_monthly * 12) + (local.domain_usage.dnssec_enabled ? local.domain_addons.dnssec_yearly : 0)
  }

  cost_by_environment = {
    "${var.environment}" = local.cost_yearly_total
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
      description       = "Текущая конфигурация"
      dnssec            = local.domain_usage.dnssec_enabled
      privacy           = local.domain_usage.privacy_protection
      transfer_lock     = local.domain_usage.transfer_lock
      yearly_usd        = local.cost_yearly_total
    }
    "no_addons" = {
      description       = "Без privacy protection и transfer lock"
      dnssec            = local.domain_usage.dnssec_enabled
      privacy           = false
      transfer_lock     = false
      yearly_usd        = local.cost_yearly_total - (local.domain_usage.privacy_protection ? local.domain_addons.privacy_protection_yearly : 0) - (local.domain_usage.transfer_lock ? local.domain_addons.transfer_lock_yearly : 0)
    }
    "with_dnssec" = {
      description       = "С включённым DNSSEC"
      dnssec            = true
      privacy           = local.domain_usage.privacy_protection
      transfer_lock     = local.domain_usage.transfer_lock
      yearly_usd        = local.cost_yearly_total + (local.domain_usage.dnssec_enabled ? 0 : local.domain_addons.dnssec_yearly)
    }
    "minimal" = {
      description       = "Минимальная конфигурация"
      dnssec            = false
      privacy           = false
      transfer_lock     = false
      yearly_usd        = local.cost_yearly_total - (local.domain_usage.privacy_protection ? local.domain_addons.privacy_protection_yearly : 0) - (local.domain_usage.transfer_lock ? local.domain_addons.transfer_lock_yearly : 0) - (local.domain_usage.dnssec_enabled ? local.domain_addons.dnssec_yearly : 0)
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 5: Алерты и пороги (имитация для AWS Budgets)
  # ------------------------------------------------------------------
  budget_thresholds = {
    yearly_warning   = 500.00
    yearly_critical  = 800.00
    monthly_max      = 100.00
    notify_emails    = ["finops@example.com", "devops@example.com"]
    alert_on_breach  = true
    domain_renewal_days_before = 30
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 6: Метаданные отчёта
  # ------------------------------------------------------------------
  cost_report_metadata = {
    generated_by    = "terraform"
    project         = var.project_name
    environment     = var.environment
    domain          = var.domain_name
    tld             = local.domain_usage.tld
    aws_region      = var.aws_region
    currency        = local.cost_currency
    pricing_source  = "https://aws.amazon.com/route53/pricing/"
    pricing_date    = "2025-01-01"
    report_version  = "1.0.0"
    disclaimer      = "Это имитация. Для точных цифр используйте Infracost / AWS Cost Explorer."
  }
}