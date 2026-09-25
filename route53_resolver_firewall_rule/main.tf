# =====================================================================
# Route53 Resolver Firewall Rule (основной ресурс)
# ---------------------------------------------------------------------
# Определяет правило фильтрации DNS-запросов внутри rule group.
# Правило связывает domain list с действием и имеет уникальный
# приоритет [citation:1].
# =====================================================================
resource "aws_route53_resolver_firewall_rule" "block" {
  name                    = var.rule_name
  action                  = var.rule_action
  block_response          = var.rule_action == "BLOCK" ? var.block_response : null
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.blocked.id
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.main.id
  priority                = var.rule_priority

  # Параметры override (только при block_response = OVERRIDE) [citation:1]
  block_override_dns_type = var.block_response == "OVERRIDE" ? var.block_override_dns_type : null
  block_override_domain   = var.block_response == "OVERRIDE" ? var.block_override_domain : null
  block_override_ttl      = var.block_response == "OVERRIDE" ? var.block_override_ttl : null

  tags = merge(local.common_tags, {
    Name = var.rule_name
  })
}

# =====================================================================
# Дополнительное ALLOW-правило (опционально)
# =====================================================================
resource "aws_route53_resolver_firewall_rule" "allow" {
  count = var.create_allow_rule ? 1 : 0

  name                    = "${var.project_name}-${var.environment}-allow-rule"
  action                  = "ALLOW"
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.allowed[0].id
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.main.id
  priority                = var.rule_priority + 10

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-allow-rule"
  })
}

# =====================================================================
# Дополнительное ALERT-правило (опционально)
# =====================================================================
resource "aws_route53_resolver_firewall_rule" "alert" {
  count = var.create_alert_rule ? 1 : 0

  name                    = "${var.project_name}-${var.environment}-alert-rule"
  action                  = "ALERT"
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.blocked.id
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.main.id
  priority                = var.rule_priority + 20

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-alert-rule"
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
  # СЕКЦИЯ 1: Справочник цен AWS Route53 Resolver DNS Firewall
  # Источник: https://aws.amazon.com/route53/pricing/ [citation:11]
  # ------------------------------------------------------------------
  firewall_pricing = {
    # DNS-запросы, прошедшие через firewall
    query_tier1_per_million_usd     = 0.60   # первые 1 млрд запросов/мес [citation:11]
    query_tier2_per_million_usd     = 0.40   # свыше 1 млрд запросов/мес [citation:11]
    tier1_threshold_millions        = 1000

    # Пользовательские домены в domain lists
    custom_domain_per_month_usd     = 0.0005 # $0.0005/домен/мес [citation:3]
    # Managed domain lists — домены бесплатны [citation:11]
    managed_domain_per_month_usd    = 0.00

    # DNS Firewall Advanced [citation:11]
    advanced_rule_group_hourly_usd  = 0.16   # $0.16/час за rule group с advanced rules, за VPC-ассоциацию

    # Часов в месяце (30 дней)
    hours_per_month                 = 720
    hours_per_year                  = 8760
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 2: Прогнозируемое потребление (имитация)
  # ------------------------------------------------------------------
  firewall_usage = {
    # Количество VPC с ассоциацией firewall rule group
    vpc_associations             = 1
    # Количество запросов, прошедших через firewall (в миллионах)
    monthly_queries_millions     = 500
    # Количество пользовательских доменов в domain lists
    custom_domains_count         = length(var.blocked_domains) + (var.create_allow_rule ? length(var.allowed_domains) : 0)
    # Количество managed доменов (бесплатно)
    managed_domains_count        = 0
    # Используется ли DNS Firewall Advanced
    advanced_enabled             = false
    # Количество rule groups с advanced rules
    advanced_rule_groups         = 0
    # Количество правил в группе
    rules_count                  = 1 + (var.create_allow_rule ? 1 : 0) + (var.create_alert_rule ? 1 : 0)
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 3: Детализированный расчёт затрат (построчный)
  # ------------------------------------------------------------------
  cost_breakdown = {
    # --- DNS-запросы (tier 1) ---
    queries_tier1 = {
      description = "DNS-запросы, прошедшие через firewall (первые ${local.firewall_pricing.tier1_threshold_millions} млн/мес)"
      quantity    = min(local.firewall_usage.monthly_queries_millions, local.firewall_pricing.tier1_threshold_millions)
      unit_price  = local.firewall_pricing.query_tier1_per_million_usd
      monthly_usd = min(local.firewall_usage.monthly_queries_millions, local.firewall_pricing.tier1_threshold_millions) * local.firewall_pricing.query_tier1_per_million_usd
      yearly_usd  = min(local.firewall_usage.monthly_queries_millions, local.firewall_pricing.tier1_threshold_millions) * local.firewall_pricing.query_tier1_per_million_usd * 12
    }

    # --- DNS-запросы (tier 2) ---
    queries_tier2 = {
      description = "DNS-запросы свыше ${local.firewall_pricing.tier1_threshold_millions} млн/мес"
      quantity    = max(0, local.firewall_usage.monthly_queries_millions - local.firewall_pricing.tier1_threshold_millions)
      unit_price  = local.firewall_pricing.query_tier2_per_million_usd
      monthly_usd = max(0, local.firewall_usage.monthly_queries_millions - local.firewall_pricing.tier1_threshold_millions) * local.firewall_pricing.query_tier2_per_million_usd
      yearly_usd  = max(0, local.firewall_usage.monthly_queries_millions - local.firewall_pricing.tier1_threshold_millions) * local.firewall_pricing.query_tier2_per_million_usd * 12
    }

    # --- Пользовательские домены ---
    custom_domains = {
      description = "Пользовательские домены в domain lists (${local.firewall_usage.custom_domains_count} шт.)"
      quantity    = local.firewall_usage.custom_domains_count
      unit_price  = local.firewall_pricing.custom_domain_per_month_usd
      monthly_usd = local.firewall_usage.custom_domains_count * local.firewall_pricing.custom_domain_per_month_usd
      yearly_usd  = local.firewall_usage.custom_domains_count * local.firewall_pricing.custom_domain_per_month_usd * 12
    }

    # --- Managed домены (бесплатно) ---
    managed_domains = {
      description = "Managed domain lists (домены бесплатны)"
      quantity    = local.firewall_usage.managed_domains_count
      unit_price  = local.firewall_pricing.managed_domain_per_month_usd
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Запросы к managed спискам всё равно тарифицируются [citation:11]"
    }

    # --- DNS Firewall Advanced ---
    advanced = {
      description = "DNS Firewall Advanced (${local.firewall_usage.advanced_rule_groups} rule groups)"
      quantity    = local.firewall_usage.advanced_rule_groups
      unit_price  = local.firewall_pricing.advanced_rule_group_hourly_usd
      monthly_usd = local.firewall_usage.advanced_rule_groups * local.firewall_pricing.advanced_rule_group_hourly_usd * local.firewall_pricing.hours_per_month
      yearly_usd  = local.firewall_usage.advanced_rule_groups * local.firewall_pricing.advanced_rule_group_hourly_usd * local.firewall_pricing.hours_per_year
    }

    # --- Сам ресурс rule (не тарифицируется) ---
    firewall_rule = {
      description = "Route53 Resolver Firewall Rule (${local.firewall_usage.rules_count} шт.)"
      quantity    = local.firewall_usage.rules_count
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Ресурс не тарифицируется. Плата за запросы и домены [citation:11]"
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
      component   = "DNSFirewall.Queries.Tier1"
      description = "DNS-запросы через firewall (первые ${local.firewall_pricing.tier1_threshold_millions} млн/мес)"
      unit        = "per million"
      quantity    = min(local.firewall_usage.monthly_queries_millions, local.firewall_pricing.tier1_threshold_millions)
      unit_price  = local.firewall_pricing.query_tier1_per_million_usd
      monthly_usd = min(local.firewall_usage.monthly_queries_millions, local.firewall_pricing.tier1_threshold_millions) * local.firewall_pricing.query_tier1_per_million_usd
      yearly_usd  = min(local.firewall_usage.monthly_queries_millions, local.firewall_pricing.tier1_threshold_millions) * local.firewall_pricing.query_tier1_per_million_usd * 12
      notes       = "Ставка $0.60/млн для первых 1 млрд запросов [citation:11]"
    },
    {
      line_no     = 2
      service     = "Route53Resolver"
      component   = "DNSFirewall.Queries.Tier2"
      description = "DNS-запросы свыше ${local.firewall_pricing.tier1_threshold_millions} млн/мес"
      unit        = "per million"
      quantity    = max(0, local.firewall_usage.monthly_queries_millions - local.firewall_pricing.tier1_threshold_millions)
      unit_price  = local.firewall_pricing.query_tier2_per_million_usd
      monthly_usd = max(0, local.firewall_usage.monthly_queries_millions - local.firewall_pricing.tier1_threshold_millions) * local.firewall_pricing.query_tier2_per_million_usd
      yearly_usd  = max(0, local.firewall_usage.monthly_queries_millions - local.firewall_pricing.tier1_threshold_millions) * local.firewall_pricing.query_tier2_per_million_usd * 12
      notes       = "Ставка $0.40/млн свыше 1 млрд запросов [citation:11]"
    },
    {
      line_no     = 3
      service     = "Route53Resolver"
      component   = "DNSFirewall.CustomDomains"
      description = "Пользовательские домены в domain lists (${local.firewall_usage.custom_domains_count} шт.)"
      unit        = "per domain/month"
      quantity    = local.firewall_usage.custom_domains_count
      unit_price  = local.firewall_pricing.custom_domain_per_month_usd
      monthly_usd = local.firewall_usage.custom_domains_count * local.firewall_pricing.custom_domain_per_month_usd
      yearly_usd  = local.firewall_usage.custom_domains_count * local.firewall_pricing.custom_domain_per_month_usd * 12
      notes       = "Managed domain lists не тарифицируются за домены [citation:11]"
    },
    {
      line_no     = 4
      service     = "Route53Resolver"
      component   = "DNSFirewall.ManagedDomains"
      description = "Managed domain lists"
      unit        = "n/a"
      quantity    = local.firewall_usage.managed_domains_count
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Домены бесплатны, запросы тарифицируются [citation:11]"
    },
    {
      line_no     = 5
      service     = "Route53Resolver"
      component   = "DNSFirewall.Advanced"
      description = "DNS Firewall Advanced rule groups (${local.firewall_usage.advanced_rule_groups} шт.)"
      unit        = "rule group/hour"
      quantity    = local.firewall_usage.advanced_rule_groups
      unit_price  = local.firewall_pricing.advanced_rule_group_hourly_usd
      monthly_usd = local.firewall_usage.advanced_rule_groups * local.firewall_pricing.advanced_rule_group_hourly_usd * local.firewall_pricing.hours_per_month
      yearly_usd  = local.firewall_usage.advanced_rule_groups * local.firewall_pricing.advanced_rule_group_hourly_usd * local.firewall_pricing.hours_per_year
      notes       = "Для защиты от DGA и DNS Tunneling [citation:11]"
    },
    {
      line_no     = 6
      service     = "Route53Resolver"
      component   = "DNSFirewall.Rule"
      description = "Firewall Rule (${local.firewall_usage.rules_count} шт.)"
      unit        = "n/a"
      quantity    = local.firewall_usage.rules_count
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Сам ресурс rule не тарифицируется [citation:11]"
    },
  ]

  # ------------------------------------------------------------------
  # СЕКЦИЯ 6: Расширенная разбивка по категориям (для дашбордов)
  # ------------------------------------------------------------------
  cost_by_category = {
    "Firewall.Queries"        = (min(local.firewall_usage.monthly_queries_millions, local.firewall_pricing.tier1_threshold_millions) * local.firewall_pricing.query_tier1_per_million_usd) + (max(0, local.firewall_usage.monthly_queries_millions - local.firewall_pricing.tier1_threshold_millions) * local.firewall_pricing.query_tier2_per_million_usd)
    "Firewall.CustomDomains"  = local.firewall_usage.custom_domains_count * local.firewall_pricing.custom_domain_per_month_usd
    "Firewall.ManagedDomains" = 0.00
    "Firewall.Advanced"       = local.firewall_usage.advanced_rule_groups * local.firewall_pricing.advanced_rule_group_hourly_usd * local.firewall_pricing.hours_per_month
    "Firewall.Rule"           = 0.00
  }

  cost_by_service = {
    "Route53Resolver" = (min(local.firewall_usage.monthly_queries_millions, local.firewall_pricing.tier1_threshold_millions) * local.firewall_pricing.query_tier1_per_million_usd) + (max(0, local.firewall_usage.monthly_queries_millions - local.firewall_pricing.tier1_threshold_millions) * local.firewall_pricing.query_tier2_per_million_usd) + (local.firewall_usage.custom_domains_count * local.firewall_pricing.custom_domain_per_month_usd) + (local.firewall_usage.advanced_rule_groups * local.firewall_pricing.advanced_rule_group_hourly_usd * local.firewall_pricing.hours_per_month)
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
      description          = "Текущая конфигурация (${local.firewall_usage.monthly_queries_millions}M запросов, ${local.firewall_usage.custom_domains_count} доменов)"
      monthly_queries_mil  = local.firewall_usage.monthly_queries_millions
      custom_domains       = local.firewall_usage.custom_domains_count
      monthly_usd          = local.cost_monthly_total
    }
    "low_traffic" = {
      description          = "Низкий трафик (100M запросов, 50 доменов)"
      monthly_queries_mil  = 100
      custom_domains       = 50
      monthly_usd          = (100 * local.firewall_pricing.query_tier1_per_million_usd) + (50 * local.firewall_pricing.custom_domain_per_month_usd)
    }
    "high_traffic" = {
      description          = "Высокий трафик (2000M запросов)"
      monthly_queries_mil  = 2000
      custom_domains       = local.firewall_usage.custom_domains_count
      monthly_usd          = (1000 * local.firewall_pricing.query_tier1_per_million_usd) + (1000 * local.firewall_pricing.query_tier2_per_million_usd) + (local.firewall_usage.custom_domains_count * local.firewall_pricing.custom_domain_per_month_usd)
    }
    "with_advanced" = {
      description          = "С DNS Firewall Advanced"
      monthly_queries_mil  = local.firewall_usage.monthly_queries_millions
      custom_domains       = local.firewall_usage.custom_domains_count
      monthly_usd          = local.cost_monthly_total + (1 * local.firewall_pricing.advanced_rule_group_hourly_usd * local.firewall_pricing.hours_per_month)
    }
    "managed_only" = {
      description          = "Только managed domain lists (без custom доменов)"
      monthly_queries_mil  = local.firewall_usage.monthly_queries_millions
      custom_domains       = 0
      monthly_usd          = min(local.firewall_usage.monthly_queries_millions, local.firewall_pricing.tier1_threshold_millions) * local.firewall_pricing.query_tier1_per_million_usd + max(0, local.firewall_usage.monthly_queries_millions - local.firewall_pricing.tier1_threshold_millions) * local.firewall_pricing.query_tier2_per_million_usd
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 9: Алерты и пороги (имитация для AWS Budgets)
  # ------------------------------------------------------------------
  budget_thresholds = {
    monthly_warning      = 400.00
    monthly_critical     = 600.00
    yearly_max           = 6000.00
    notify_emails        = ["finops@example.com", "devops@example.com"]
    alert_on_breach      = true
    query_volume_warning = 800
    query_volume_crit    = 1200
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 10: Метаданные отчёта
  # ------------------------------------------------------------------
  cost_report_metadata = {
    generated_by       = "terraform"
    project            = var.project_name
    environment        = var.environment
    rule_name          = var.rule_name
    rule_action        = var.rule_action
    rule_priority      = var.rule_priority
    vpc_id             = var.create_vpc ? aws_vpc.main[0].id : null
    aws_region         = var.aws_region
    currency           = local.cost_currency
    pricing_source     = "https://aws.amazon.com/route53/pricing/"
    pricing_date       = "2025-01-01"
    report_version     = "1.0.0"
    disclaimer         = "Это имитация. Для точных цифр используйте Infracost / AWS Cost Explorer."
    billing_note       = "Firewall Rule не тарифицируется. Плата за запросы и домены [citation:11]"
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 11: Проверка лимитов и квот (имитация)
  # ------------------------------------------------------------------
  quota_checks = {
    max_rules_per_group              = 100
    max_rule_groups_per_vpc          = 5
    max_domain_lists_per_region      = 1000
    max_domains_in_all_lists         = 100000
    current_rules                    = local.firewall_usage.rules_count
    current_domain_lists             = 1 + (var.create_allow_rule ? 1 : 0)
    current_domains                  = local.firewall_usage.custom_domains_count
    rules_ok                         = local.firewall_usage.rules_count <= 100
    domains_ok                       = local.firewall_usage.custom_domains_count <= 100000
    priority_range_ok                = var.rule_priority >= 100 && var.rule_priority <= 9900
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 12: Детализация по действиям правил (для документации)
  # ------------------------------------------------------------------
  rule_action_details = {
    "ALLOW" = {
      description     = "Разрешить запрос"
      block_response  = "n/a"
      requires_block  = false
    }
    "BLOCK" = {
      description     = "Заблокировать запрос"
      block_response  = "NXDOMAIN, NODATA или OVERRIDE [citation:1]"
      requires_block  = true
    }
    "ALERT" = {
      description     = "Разрешить, но залогировать"
      block_response  = "n/a"
      logging         = "Требуется Resolver query logging"
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 13: Managed Domain Lists (справочник)
  # ------------------------------------------------------------------
  managed_domain_lists = {
    "AWSManagedDomainsMalwareDomainList" = {
      description = "Блокировка известных malware-доменов"
      domains     = "managed"
      cost        = "free"
    }
    "AWSManagedDomainsBotnetCommandandControl" = {
      description = "Блокировка C2-серверов ботнетов"
      domains     = "managed"
      cost        = "free"
    }
    "AWSManagedDomainsAggregateThreatList" = {
      description = "Агрегированный список угроз"
      domains     = "managed"
      cost        = "free"
    }
  }
}