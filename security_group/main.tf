# =====================================================================
# Security Group: Application Tier (основной ресурс)
# =====================================================================
resource "aws_security_group" "app" {
  name        = var.sg_name
  description = var.sg_description
  vpc_id      = aws_vpc.main.id

  # SSH доступ (ограничен)
  ingress {
    description = "SSH from allowed networks"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  # HTTP доступ
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidrs
  }

  # HTTPS доступ
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidrs
  }

  # Порт приложения (только из ALB SG)
  ingress {
    description     = "App port from ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = var.create_alb_sg ? [aws_security_group.alb[0].id] : []
  }

  # Egress: разрешить весь исходящий трафик
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = var.sg_name
    Tier = "application"
  })

  # Предотвращение проблем при пересоздании SG с зависимыми ресурсами [citation:1]
  lifecycle {
    create_before_destroy = true
  }
}

# =====================================================================
# Security Group: ALB
# =====================================================================
resource "aws_security_group" "alb" {
  count = var.create_alb_sg ? 1 : 0

  name        = "${var.sg_name}-alb"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.sg_name}-alb"
    Tier = "alb"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# =====================================================================
# Security Group: Database
# =====================================================================
resource "aws_security_group" "db" {
  count = var.create_db_sg ? 1 : 0

  name        = "${var.sg_name}-db"
  description = "Security group for database tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from app SG"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.sg_name}-db"
    Tier = "database"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# =====================================================================
# ИМИТАЦИЯ ЗАТРАТ (Cost Simulation)
# ---------------------------------------------------------------------
# Security Groups НЕ тарифицируются. Плата за сетевые компоненты вокруг.
# =====================================================================

locals {
  # ------------------------------------------------------------------
  # СЕКЦИЯ 1: Справочник цен AWS Networking (us-east-1, 2024-2026)
  # Источник: AWS VPC Pricing, AWS Firewall Manager Pricing
  # ------------------------------------------------------------------
  network_pricing = {
    # --- Security Groups (БЕСПЛАТНО) ---
    security_group_hourly_usd    = 0.00   # No additional charge [citation:3][citation:6]
    security_group_rule_usd      = 0.00   # No charge for rules [citation:16]
    security_group_evaluation_usd = 0.00  # No charge for evaluations [citation:16]

    # --- VPC Flow Logs (опционально) ---
    flow_logs_per_gb_usd         = 0.50   # CloudWatch Logs ingestion
    flow_logs_storage_per_gb_usd = 0.03   # CloudWatch Logs storage

    # --- Public IPv4 (2024+) ---
    public_ipv4_hourly_usd       = 0.005  # $0.005/hour (approx) [citation:12]

    # --- NAT Gateway (если используется) ---
    nat_gateway_hourly_usd       = 0.045  # $0.045/hour
    nat_gateway_per_gb_usd       = 0.045  # $0.045/GB

    # --- Interface VPC Endpoints ---
    interface_endpoint_hourly_usd = 0.01  # $0.01/hour per AZ
    interface_endpoint_per_gb_usd = 0.01  # $0.01/GB

    # --- Data Transfer ---
    cross_az_per_gb_usd          = 0.01   # $0.01/GB each way
    internet_egress_per_gb_usd   = 0.09   # $0.09/GB

    # --- Firewall Manager (для централизованного управления SG) ---
    firewall_manager_policy_monthly_usd = 100.00  # $100/month per policy [citation:2][citation:5]

    # Часов в месяце (730 для точности)
    hours_per_month              = 730
    hours_per_year               = 8760
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 2: Прогнозируемое потребление (имитация)
  # ------------------------------------------------------------------
  network_usage = {
    # Количество Security Groups
    security_groups_count        = 1 + (var.create_alb_sg ? 1 : 0) + (var.create_db_sg ? 1 : 0)
    security_rules_count         = 4 + 2 + 1  # app + alb + db

    # Flow Logs
    flow_logs_enabled            = var.enable_flow_logs
    flow_logs_gb_per_month       = 10

    # Public IPv4 (для ALB и NAT)
    public_ipv4_count            = 2

    # NAT Gateway
    nat_enabled                  = true
    nat_data_gb                  = 100

    # Data Transfer
    cross_az_transfer_gb         = 200
    internet_egress_gb           = 50

    # Firewall Manager (опционально)
    firewall_manager_enabled     = false
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 3: Детализированный расчёт затрат (построчный)
  # ------------------------------------------------------------------
  cost_breakdown = {
    # --- Security Groups (БЕСПЛАТНО) ---
    security_groups = {
      description = "Security Groups (${local.network_usage.security_groups_count} шт.)"
      quantity    = local.network_usage.security_groups_count
      unit_price  = local.network_pricing.security_group_hourly_usd
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Security groups have no additional charge [citation:3][citation:6]"
    }

    # --- Security Group Rules (БЕСПЛАТНО) ---
    security_rules = {
      description = "Security Group Rules (${local.network_usage.security_rules_count} шт.)"
      quantity    = local.network_usage.security_rules_count
      unit_price  = local.network_pricing.security_group_rule_usd
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "No charge for rules or evaluations [citation:16]"
    }

    # --- Flow Logs (опционально) ---
    flow_logs = {
      description = "VPC Flow Logs (${local.network_usage.flow_logs_gb_per_month} GB/мес)"
      quantity    = local.network_usage.flow_logs_enabled ? local.network_usage.flow_logs_gb_per_month : 0
      unit_price  = local.network_pricing.flow_logs_per_gb_usd
      monthly_usd = local.network_usage.flow_logs_enabled ? local.network_usage.flow_logs_gb_per_month * local.network_pricing.flow_logs_per_gb_usd : 0
      yearly_usd  = local.network_usage.flow_logs_enabled ? local.network_usage.flow_logs_gb_per_month * local.network_pricing.flow_logs_per_gb_usd * 12 : 0
      notes       = "Optional. CloudWatch Logs charges apply"
    }

    # --- Public IPv4 ---
    public_ipv4 = {
      description = "Public IPv4 Addresses (${local.network_usage.public_ipv4_count} шт.)"
      quantity    = local.network_usage.public_ipv4_count
      unit_price  = local.network_pricing.public_ipv4_hourly_usd
      monthly_usd = local.network_usage.public_ipv4_count * local.network_pricing.public_ipv4_hourly_usd * local.network_pricing.hours_per_month
      yearly_usd  = local.network_usage.public_ipv4_count * local.network_pricing.public_ipv4_hourly_usd * local.network_pricing.hours_per_year
      notes       = "Public IPv4 now charged per hour [citation:12]"
    }

    # --- NAT Gateway ---
    nat_gateway = {
      description = "NAT Gateway (hourly + data)"
      quantity    = local.network_usage.nat_enabled ? 1 : 0
      unit_price  = local.network_pricing.nat_gateway_hourly_usd
      monthly_usd = local.network_usage.nat_enabled ? (1 * local.network_pricing.nat_gateway_hourly_usd * local.network_pricing.hours_per_month) + (local.network_usage.nat_data_gb * local.network_pricing.nat_gateway_per_gb_usd) : 0
      yearly_usd  = local.network_usage.nat_enabled ? ((1 * local.network_pricing.nat_gateway_hourly_usd * local.network_pricing.hours_per_month) + (local.network_usage.nat_data_gb * local.network_pricing.nat_gateway_per_gb_usd)) * 12 : 0
      notes       = "NAT Gateway is the most expensive component [citation:19]"
    }

    # --- Data Transfer ---
    data_transfer = {
      description = "Data Transfer (cross-AZ + internet)"
      quantity    = local.network_usage.cross_az_transfer_gb + local.network_usage.internet_egress_gb
      unit_price  = local.network_pricing.cross_az_per_gb_usd
      monthly_usd = (local.network_usage.cross_az_transfer_gb * local.network_pricing.cross_az_per_gb_usd) + (local.network_usage.internet_egress_gb * local.network_pricing.internet_egress_per_gb_usd)
      yearly_usd  = ((local.network_usage.cross_az_transfer_gb * local.network_pricing.cross_az_per_gb_usd) + (local.network_usage.internet_egress_gb * local.network_pricing.internet_egress_per_gb_usd)) * 12
      notes       = "Cross-AZ: $0.01/GB each way; Internet egress: $0.09/GB [citation:19]"
    }

    # --- Firewall Manager (опционально) ---
    firewall_manager = {
      description = "AWS Firewall Manager Policy"
      quantity    = local.network_usage.firewall_manager_enabled ? 1 : 0
      unit_price  = local.network_pricing.firewall_manager_policy_monthly_usd
      monthly_usd = local.network_usage.firewall_manager_enabled ? local.network_pricing.firewall_manager_policy_monthly_usd : 0
      yearly_usd  = local.network_usage.firewall_manager_enabled ? local.network_pricing.firewall_manager_policy_monthly_usd * 12 : 0
      notes       = "$100/month per policy for centralized SG management [citation:2][citation:5]"
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
      service     = "VPC"
      component   = "SecurityGroup"
      description = "Security Groups"
      unit        = "n/a"
      quantity    = local.network_usage.security_groups_count
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Security groups are free [citation:3][citation:6]"
    },
    {
      line_no     = 2
      service     = "VPC"
      component   = "SecurityGroupRule"
      description = "Security Group Rules"
      unit        = "n/a"
      quantity    = local.network_usage.security_rules_count
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "No charge for rules [citation:16]"
    },
    {
      line_no     = 3
      service     = "VPC"
      component   = "PublicIPv4"
      description = "Public IPv4 Addresses"
      unit        = "hour"
      quantity    = local.network_usage.public_ipv4_count
      unit_price  = local.network_pricing.public_ipv4_hourly_usd
      monthly_usd = local.network_usage.public_ipv4_count * local.network_pricing.public_ipv4_hourly_usd * local.network_pricing.hours_per_month
      yearly_usd  = local.network_usage.public_ipv4_count * local.network_pricing.public_ipv4_hourly_usd * local.network_pricing.hours_per_year
      notes       = "Public IPv4 charges since Feb 2024 [citation:12]"
    },
    {
      line_no     = 4
      service     = "VPC"
      component   = "NATGateway"
      description = "NAT Gateway (hourly + data)"
      unit        = "hour + GB"
      quantity    = local.network_usage.nat_enabled ? 1 : 0
      unit_price  = local.network_pricing.nat_gateway_hourly_usd
      monthly_usd = local.network_usage.nat_enabled ? (1 * local.network_pricing.nat_gateway_hourly_usd * local.network_pricing.hours_per_month) + (local.network_usage.nat_data_gb * local.network_pricing.nat_gateway_per_gb_usd) : 0
      yearly_usd  = local.network_usage.nat_enabled ? ((1 * local.network_pricing.nat_gateway_hourly_usd * local.network_pricing.hours_per_month) + (local.network_usage.nat_data_gb * local.network_pricing.nat_gateway_per_gb_usd)) * 12 : 0
      notes       = "Most expensive networking component [citation:19]"
    },
    {
      line_no     = 5
      service     = "DataTransfer"
      component   = "CrossAZ"
      description = "Cross-AZ Data Transfer"
      unit        = "per GB"
      quantity    = local.network_usage.cross_az_transfer_gb
      unit_price  = local.network_pricing.cross_az_per_gb_usd
      monthly_usd = local.network_usage.cross_az_transfer_gb * local.network_pricing.cross_az_per_gb_usd
      yearly_usd  = local.network_usage.cross_az_transfer_gb * local.network_pricing.cross_az_per_gb_usd * 12
      notes       = "$0.01/GB each way [citation:19]"
    },
    {
      line_no     = 6
      service     = "DataTransfer"
      component   = "InternetEgress"
      description = "Internet Egress"
      unit        = "per GB"
      quantity    = local.network_usage.internet_egress_gb
      unit_price  = local.network_pricing.internet_egress_per_gb_usd
      monthly_usd = local.network_usage.internet_egress_gb * local.network_pricing.internet_egress_per_gb_usd
      yearly_usd  = local.network_usage.internet_egress_gb * local.network_pricing.internet_egress_per_gb_usd * 12
      notes       = "$0.09/GB [citation:19]"
    },
  ]

  # ------------------------------------------------------------------
  # СЕКЦИЯ 6: Расширенная разбивка по категориям (для дашбордов)
  # ------------------------------------------------------------------
  cost_by_category = {
    "SecurityGroup"      = 0.00
    "SecurityGroupRules" = 0.00
    "FlowLogs"           = local.network_usage.flow_logs_enabled ? local.network_usage.flow_logs_gb_per_month * local.network_pricing.flow_logs_per_gb_usd : 0
    "PublicIPv4"         = local.network_usage.public_ipv4_count * local.network_pricing.public_ipv4_hourly_usd * local.network_pricing.hours_per_month
    "NATGateway"         = local.network_usage.nat_enabled ? (1 * local.network_pricing.nat_gateway_hourly_usd * local.network_pricing.hours_per_month) + (local.network_usage.nat_data_gb * local.network_pricing.nat_gateway_per_gb_usd) : 0
    "DataTransfer"       = (local.network_usage.cross_az_transfer_gb * local.network_pricing.cross_az_per_gb_usd) + (local.network_usage.internet_egress_gb * local.network_pricing.internet_egress_per_gb_usd)
    "FirewallManager"    = local.network_usage.firewall_manager_enabled ? local.network_pricing.firewall_manager_policy_monthly_usd : 0
  }

  cost_by_service = {
    "VPC"          = local.network_usage.public_ipv4_count * local.network_pricing.public_ipv4_hourly_usd * local.network_pricing.hours_per_month + (local.network_usage.nat_enabled ? (1 * local.network_pricing.nat_gateway_hourly_usd * local.network_pricing.hours_per_month) + (local.network_usage.nat_data_gb * local.network_pricing.nat_gateway_per_gb_usd) : 0)
    "DataTransfer" = (local.network_usage.cross_az_transfer_gb * local.network_pricing.cross_az_per_gb_usd) + (local.network_usage.internet_egress_gb * local.network_pricing.internet_egress_per_gb_usd)
    "CloudWatch"   = local.network_usage.flow_logs_enabled ? local.network_usage.flow_logs_gb_per_month * local.network_pricing.flow_logs_per_gb_usd : 0
    "FirewallManager" = local.network_usage.firewall_manager_enabled ? local.network_pricing.firewall_manager_policy_monthly_usd : 0
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
      description          = "Текущая конфигурация (${local.network_usage.security_groups_count} SG, ${local.network_usage.security_rules_count} rules)"
      security_groups      = local.network_usage.security_groups_count
      security_rules       = local.network_usage.security_rules_count
      monthly_usd          = local.cost_monthly_total
    }
    "sg_only" = {
      description          = "Только Security Groups (без NAT, Public IP)"
      security_groups      = local.network_usage.security_groups_count
      security_rules       = local.network_usage.security_rules_count
      monthly_usd          = 0.00
    }
    "with_flow_logs" = {
      description          = "С Flow Logs"
      security_groups      = local.network_usage.security_groups_count
      security_rules       = local.network_usage.security_rules_count
      monthly_usd          = local.cost_monthly_total + (10 * local.network_pricing.flow_logs_per_gb_usd)
    }
    "without_nat" = {
      description          = "Без NAT Gateway"
      security_groups      = local.network_usage.security_groups_count
      security_rules       = local.network_usage.security_rules_count
      monthly_usd          = local.cost_monthly_total - (local.network_usage.nat_enabled ? (1 * local.network_pricing.nat_gateway_hourly_usd * local.network_pricing.hours_per_month) + (local.network_usage.nat_data_gb * local.network_pricing.nat_gateway_per_gb_usd) : 0)
    }
    "with_firewall_manager" = {
      description          = "С Firewall Manager"
      security_groups      = local.network_usage.security_groups_count
      security_rules       = local.network_usage.security_rules_count
      monthly_usd          = local.cost_monthly_total + local.network_pricing.firewall_manager_policy_monthly_usd
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
    rule_count_warning   = 50
    rule_count_crit      = 100
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 10: Метаданные отчёта
  # ------------------------------------------------------------------
  cost_report_metadata = {
    generated_by       = "terraform"
    project            = var.project_name
    environment        = var.environment
    security_groups    = local.network_usage.security_groups_count
    security_rules     = local.network_usage.security_rules_count
    aws_region         = var.aws_region
    currency           = local.cost_currency
    pricing_source     = "https://aws.amazon.com/vpc/pricing/"
    pricing_date       = "2026-01-01"
    report_version     = "1.0.0"
    disclaimer         = "Это имитация. Для точных цифр используйте Infracost / AWS Cost Explorer."
    billing_note       = "Security Groups are free. Costs come from NAT Gateway, Public IPv4, and Data Transfer [citation:3][citation:12]"
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 11: Проверка лимитов и квот (имитация)
  # ------------------------------------------------------------------
  quota_checks = {
    max_sg_per_vpc                 = 500
    max_rules_per_sg               = 60
    max_sg_rules_per_eni           = 50
    current_sg_count               = local.network_usage.security_groups_count
    current_rule_count             = local.network_usage.security_rules_count
    sg_count_ok                    = local.network_usage.security_groups_count <= 500
    rule_count_ok                  = local.network_usage.security_rules_count <= 60
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 12: Детализация по типам Security Groups (для документации)
  # ------------------------------------------------------------------
  sg_type_details = {
    "Application" = {
      description     = "Application tier SG"
      ingress_rules   = 4
      egress_rules    = 1
      cost            = "Free"
      notes           = "SSH, HTTP, HTTPS, App port"
    }
    "ALB" = {
      description     = "Application Load Balancer SG"
      ingress_rules   = 2
      egress_rules    = 1
      cost            = "Free"
      notes           = "HTTP, HTTPS from internet"
    }
    "Database" = {
      description     = "Database tier SG"
      ingress_rules   = 1
      egress_rules    = 1
      cost            = "Free"
      notes           = "PostgreSQL from App SG"
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 13: Best Practices (для документации)
  # ------------------------------------------------------------------
  best_practices = {
    "Least Privilege" = {
      description     = "Ограничивайте правила минимально необходимыми"
      recommendation  = "Избегайте 0.0.0.0/0 для SSH/RDP [citation:11]"
    }
    "SG References" = {
      description     = "Используйте SG references вместо CIDR где возможно"
      recommendation  = "App SG → DB SG, ALB SG → App SG"
    }
    "No Inline + Standalone" = {
      description     = "Не смешивайте inline и standalone rules"
      recommendation  = "Terraform: либо inline, либо aws_security_group_rule [citation:1]"
    }
    "create_before_destroy" = {
      description     = "Предотвращает ошибки при пересоздании SG"
      recommendation  = "Добавьте lifecycle { create_before_destroy = true } [citation:1]"
    }
  }
}