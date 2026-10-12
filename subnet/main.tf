# =====================================================================
# Public Subnets
# =====================================================================
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-${count.index + 1}"
    Tier = "public"
    AZ   = var.availability_zones[count.index]
  })
}

# =====================================================================
# Private Subnets
# =====================================================================
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-${count.index + 1}"
    Tier = "private"
    AZ   = var.availability_zones[count.index]
  })
}

# =====================================================================
# Route Table Associations
# =====================================================================
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# =====================================================================
# ИМИТАЦИЯ ЗАТРАТ (Cost Simulation)
# ---------------------------------------------------------------------
# Subnet сам по себе БЕСПЛАТЕН. Плата за публичные IPv4, NAT, трафик.
# =====================================================================

locals {
  # ------------------------------------------------------------------
  # СЕКЦИЯ 1: Справочник цен AWS VPC (us-east-1, 2024-2026)
  # Источник: https://aws.amazon.com/vpc/pricing/ [citation:1][citation:5]
  # ------------------------------------------------------------------
  vpc_pricing = {
    # --- Subnet (БЕСПЛАТНО) ---
    subnet_hourly_usd            = 0.00   # Subnets are free [citation:5]

    # --- Public IPv4 ---
    public_ipv4_hourly_usd       = 0.005  # $0.005/hour = $3.60/month [citation:5][citation:13]

    # --- NAT Gateway ---
    nat_gateway_hourly_usd       = 0.045  # $0.045/hour [citation:17]
    nat_gateway_per_gb_usd       = 0.045  # $0.045/GB processed [citation:17]

    # --- Data Transfer ---
    cross_az_per_gb_usd          = 0.01   # $0.01/GB each way (same region, different AZ)
    internet_egress_per_gb_usd   = 0.09   # $0.09/GB

    # Часов в месяце (730 для точности)
    hours_per_month              = 730
    hours_per_year               = 8760

    # Резервируемые AWS адреса в каждой подсети
    aws_reserved_ips_per_subnet  = 5
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 2: Прогнозируемое потребление (имитация)
  # ------------------------------------------------------------------
  subnet_usage = {
    # Количество подсетей
    public_subnets_count         = length(var.public_subnet_cidrs)
    private_subnets_count        = length(var.private_subnet_cidrs)
    total_subnets_count          = length(var.public_subnet_cidrs) + length(var.private_subnet_cidrs)

    # Публичные IPv4-адреса (назначаются в публичных подсетях)
    public_ipv4_count            = var.public_ipv4_count

    # NAT Gateway
    nat_gateway_count            = var.create_nat_gateway ? 1 : 0
    nat_data_gb                  = var.monthly_data_processed_gb

    # Data Transfer
    cross_az_transfer_gb         = 200
    internet_egress_gb           = 50

    # Доступные IP в подсетях (для справки)
    public_ips_available         = [for cidr in var.public_subnet_cidrs : parseint(split("/", cidr)[1], 10) - local.vpc_pricing.aws_reserved_ips_per_subnet]
    private_ips_available        = [for cidr in var.private_subnet_cidrs : parseint(split("/", cidr)[1], 10) - local.vpc_pricing.aws_reserved_ips_per_subnet]
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 3: Детализированный расчёт затрат (построчный)
  # ------------------------------------------------------------------
  cost_breakdown = {
    # --- Subnet (БЕСПЛАТНО) ---
    subnet = {
      description = "Subnets (${local.subnet_usage.total_subnets_count} шт.)"
      quantity    = local.subnet_usage.total_subnets_count
      unit_price  = local.vpc_pricing.subnet_hourly_usd
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Subnets have no additional charge [citation:5]"
    }

    # --- Public IPv4 ---
    public_ipv4 = {
      description = "Public IPv4 Addresses (${local.subnet_usage.public_ipv4_count} шт.)"
      quantity    = local.subnet_usage.public_ipv4_count
      unit_price  = local.vpc_pricing.public_ipv4_hourly_usd
      monthly_usd = local.subnet_usage.public_ipv4_count * local.vpc_pricing.public_ipv4_hourly_usd * local.vpc_pricing.hours_per_month
      yearly_usd  = local.subnet_usage.public_ipv4_count * local.vpc_pricing.public_ipv4_hourly_usd * local.vpc_pricing.hours_per_year
      notes       = "$0.005/hour per IPv4, attached or unattached [citation:5][citation:13]"
    }

    # --- NAT Gateway ---
    nat_gateway = {
      description = "NAT Gateway (${local.subnet_usage.nat_gateway_count} шт., ${local.subnet_usage.nat_data_gb} GB/мес)"
      quantity    = local.subnet_usage.nat_gateway_count
      unit_price  = local.vpc_pricing.nat_gateway_hourly_usd
      monthly_usd = local.subnet_usage.nat_gateway_count * local.vpc_pricing.nat_gateway_hourly_usd * local.vpc_pricing.hours_per_month + (local.subnet_usage.nat_data_gb * local.vpc_pricing.nat_gateway_per_gb_usd)
      yearly_usd  = (local.subnet_usage.nat_gateway_count * local.vpc_pricing.nat_gateway_hourly_usd * local.vpc_pricing.hours_per_month + (local.subnet_usage.nat_data_gb * local.vpc_pricing.nat_gateway_per_gb_usd)) * 12
      notes       = "$0.045/hour + $0.045/GB [citation:17]"
    }

    # --- Data Transfer ---
    data_transfer = {
      description = "Data Transfer (cross-AZ + internet)"
      quantity    = local.subnet_usage.cross_az_transfer_gb + local.subnet_usage.internet_egress_gb
      unit_price  = local.vpc_pricing.cross_az_per_gb_usd
      monthly_usd = (local.subnet_usage.cross_az_transfer_gb * local.vpc_pricing.cross_az_per_gb_usd) + (local.subnet_usage.internet_egress_gb * local.vpc_pricing.internet_egress_per_gb_usd)
      yearly_usd  = ((local.subnet_usage.cross_az_transfer_gb * local.vpc_pricing.cross_az_per_gb_usd) + (local.subnet_usage.internet_egress_gb * local.vpc_pricing.internet_egress_per_gb_usd)) * 12
      notes       = "Cross-AZ: $0.01/GB each way; Internet: $0.09/GB"
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 4: Итоговые суммы (имитация)
  # ------------------------------------------------------------------
  cost_monthly_total = sum([for k, v in local.cost_breakdown : v.monthly_usd])
  cost_yearly_total  = sum([for k, v in local.cost_breakdown : v.yearly_usd])
  cost_currency      = "USD"

  # ------------------------------------------------------------------
  # СЕКЦИЯ 5: Построчная детализация по каждому элементу затрат
  # ------------------------------------------------------------------
  cost_line_items = [
    {
      line_no     = 1
      service     = "VPC"
      component   = "Subnet"
      description = "Subnets (${local.subnet_usage.total_subnets_count} шт.)"
      unit        = "n/a"
      quantity    = local.subnet_usage.total_subnets_count
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Subnets are free [citation:5]"
    },
    {
      line_no     = 2
      service     = "VPC"
      component   = "PublicIPv4"
      description = "Public IPv4 Addresses"
      unit        = "hour"
      quantity    = local.subnet_usage.public_ipv4_count
      unit_price  = local.vpc_pricing.public_ipv4_hourly_usd
      monthly_usd = local.subnet_usage.public_ipv4_count * local.vpc_pricing.public_ipv4_hourly_usd * local.vpc_pricing.hours_per_month
      yearly_usd  = local.subnet_usage.public_ipv4_count * local.vpc_pricing.public_ipv4_hourly_usd * local.vpc_pricing.hours_per_year
      notes       = "All public IPv4 addresses charged since Feb 2024 [citation:13]"
    },
    {
      line_no     = 3
      service     = "VPC"
      component   = "NATGateway"
      description = "NAT Gateway hourly + data"
      unit        = "hour + GB"
      quantity    = local.subnet_usage.nat_gateway_count
      unit_price  = local.vpc_pricing.nat_gateway_hourly_usd
      monthly_usd = local.subnet_usage.nat_gateway_count * local.vpc_pricing.nat_gateway_hourly_usd * local.vpc_pricing.hours_per_month + (local.subnet_usage.nat_data_gb * local.vpc_pricing.nat_gateway_per_gb_usd)
      yearly_usd  = (local.subnet_usage.nat_gateway_count * local.vpc_pricing.nat_gateway_hourly_usd * local.vpc_pricing.hours_per_month + (local.subnet_usage.nat_data_gb * local.vpc_pricing.nat_gateway_per_gb_usd)) * 12
      notes       = "$0.045/hour + $0.045/GB [citation:17]"
    },
    {
      line_no     = 4
      service     = "DataTransfer"
      component   = "CrossAZ"
      description = "Cross-AZ Data Transfer"
      unit        = "per GB"
      quantity    = local.subnet_usage.cross_az_transfer_gb
      unit_price  = local.vpc_pricing.cross_az_per_gb_usd
      monthly_usd = local.subnet_usage.cross_az_transfer_gb * local.vpc_pricing.cross_az_per_gb_usd
      yearly_usd  = local.subnet_usage.cross_az_transfer_gb * local.vpc_pricing.cross_az_per_gb_usd * 12
      notes       = "$0.01/GB each way"
    },
    {
      line_no     = 5
      service     = "DataTransfer"
      component   = "InternetEgress"
      description = "Internet Egress"
      unit        = "per GB"
      quantity    = local.subnet_usage.internet_egress_gb
      unit_price  = local.vpc_pricing.internet_egress_per_gb_usd
      monthly_usd = local.subnet_usage.internet_egress_gb * local.vpc_pricing.internet_egress_per_gb_usd
      yearly_usd  = local.subnet_usage.internet_egress_gb * local.vpc_pricing.internet_egress_per_gb_usd * 12
      notes       = "$0.09/GB"
    },
  ]

  # ------------------------------------------------------------------
  # СЕКЦИЯ 6: Расширенная разбивка по категориям (для дашбордов)
  # ------------------------------------------------------------------
  cost_by_category = {
    "Subnet"             = 0.00
    "PublicIPv4"         = local.subnet_usage.public_ipv4_count * local.vpc_pricing.public_ipv4_hourly_usd * local.vpc_pricing.hours_per_month
    "NATGateway"         = local.subnet_usage.nat_gateway_count * local.vpc_pricing.nat_gateway_hourly_usd * local.vpc_pricing.hours_per_month + (local.subnet_usage.nat_data_gb * local.vpc_pricing.nat_gateway_per_gb_usd)
    "DataTransfer"       = (local.subnet_usage.cross_az_transfer_gb * local.vpc_pricing.cross_az_per_gb_usd) + (local.subnet_usage.internet_egress_gb * local.vpc_pricing.internet_egress_per_gb_usd)
  }

  cost_by_service = {
    "VPC"          = local.subnet_usage.public_ipv4_count * local.vpc_pricing.public_ipv4_hourly_usd * local.vpc_pricing.hours_per_month + (local.subnet_usage.nat_gateway_count * local.vpc_pricing.nat_gateway_hourly_usd * local.vpc_pricing.hours_per_month + (local.subnet_usage.nat_data_gb * local.vpc_pricing.nat_gateway_per_gb_usd))
    "DataTransfer" = (local.subnet_usage.cross_az_transfer_gb * local.vpc_pricing.cross_az_per_gb_usd) + (local.subnet_usage.internet_egress_gb * local.vpc_pricing.internet_egress_per_gb_usd)
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
      description          = "Текущая конфигурация (${local.subnet_usage.total_subnets_count} подсетей, NAT: ${var.create_nat_gateway})"
      subnets_count        = local.subnet_usage.total_subnets_count
      nat_enabled          = var.create_nat_gateway
      monthly_usd          = local.cost_monthly_total
    }
    "subnets_only" = {
      description          = "Только подсети (без NAT, без публичных IP)"
      subnets_count        = local.subnet_usage.total_subnets_count
      monthly_usd          = 0.00
    }
    "no_nat" = {
      description          = "Без NAT Gateway"
      subnets_count        = local.subnet_usage.total_subnets_count
      monthly_usd          = local.cost_monthly_total - (local.subnet_usage.nat_gateway_count * local.vpc_pricing.nat_gateway_hourly_usd * local.vpc_pricing.hours_per_month + (local.subnet_usage.nat_data_gb * local.vpc_pricing.nat_gateway_per_gb_usd))
    }
    "high_ipv4" = {
      description          = "10 публичных IPv4"
      subnets_count        = local.subnet_usage.total_subnets_count
      monthly_usd          = local.cost_monthly_total + (8 * local.vpc_pricing.public_ipv4_hourly_usd * local.vpc_pricing.hours_per_month)
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
    ipv4_count_warning   = 5
    ipv4_count_crit      = 10
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 10: Метаданные отчёта
  # ------------------------------------------------------------------
  cost_report_metadata = {
    generated_by       = "terraform"
    project            = var.project_name
    environment        = var.environment
    vpc_id             = aws_vpc.main.id
    public_subnets     = local.subnet_usage.public_subnets_count
    private_subnets    = local.subnet_usage.private_subnets_count
    aws_region         = var.aws_region
    currency           = local.cost_currency
    pricing_source     = "https://aws.amazon.com/vpc/pricing/ [citation:1][citation:5]"
    pricing_date       = "2026-01-01"
    report_version     = "1.0.0"
    disclaimer         = "Это имитация. Для точных цифр используйте Infracost / AWS Cost Explorer."
    billing_note       = "Subnets are free. Costs come from Public IPv4, NAT Gateway, and Data Transfer [citation:5]"
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 11: Проверка лимитов и квот (имитация)
  # ------------------------------------------------------------------
  quota_checks = {
    max_subnets_per_vpc           = 200
    min_subnet_size               = "/28"
    max_subnet_size               = "/16"
    aws_reserved_ips_per_subnet   = 5
    current_subnets               = local.subnet_usage.total_subnets_count
    subnets_ok                    = local.subnet_usage.total_subnets_count <= 200
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 12: Детализация по типам подсетей (для документации)
  # ------------------------------------------------------------------
  subnet_type_details = {
    "Public" = {
      description     = "Публичная подсеть (маршрут в IGW)"
      route           = "0.0.0.0/0 → Internet Gateway"
      public_ip       = "Optional (map_public_ip_on_launch)"
      cost            = "Subnet free, Public IPv4 $3.60/month each"
      use_cases       = "Load balancers, bastion hosts, NAT Gateway"
    }
    "Private" = {
      description     = "Приватная подсеть (без прямого доступа в интернет)"
      route           = "0.0.0.0/0 → NAT Gateway (optional)"
      public_ip       = "None"
      cost            = "Subnet free, NAT costs if used"
      use_cases       = "Application servers, databases, internal services"
    }
  }
}