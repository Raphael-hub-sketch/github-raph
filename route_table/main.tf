# =====================================================================
# Route Table: Публичная (для подсетей с доступом в интернет)
# =====================================================================
resource "aws_route_table" "public" {
  count = var.create_public_route_table ? 1 : 0

  vpc_id = aws_vpc.main.id

  # Маршрут по умолчанию через Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  # Локальный маршрут (adopting existing local route) [citation:1]
  route {
    cidr_block = var.vpc_cidr
    gateway_id = "local"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
    Tier = "public"
  })
}

# =====================================================================
# Route Table: Приватная (для подсетей без прямого доступа в интернет)
# =====================================================================
resource "aws_route_table" "private" {
  count = var.create_private_route_table ? 1 : 0

  vpc_id = aws_vpc.main.id

  # Маршрут через NAT Gateway (если создан)
  dynamic "route" {
    for_each = var.create_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  # Локальный маршрут
  route {
    cidr_block = var.vpc_cidr
    gateway_id = "local"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-rt"
    Tier = "private"
  })
}

# =====================================================================
# Route Table Associations
# =====================================================================
resource "aws_route_table_association" "public" {
  count = var.create_public_route_table ? length(aws_subnet.public) : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "private" {
  count = var.create_private_route_table ? length(aws_subnet.private) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
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
  # СЕКЦИЯ 1: Справочник цен AWS VPC (us-east-1, 2024-2026)
  # Источник: https://aws.amazon.com/vpc/pricing/ [citation:16]
  # ------------------------------------------------------------------
  vpc_pricing = {
    # --- Route Table (бесплатно) ---
    route_table_hourly_usd       = 0.00   # Route tables are free [citation:2][citation:12]

    # --- NAT Gateway ---
    nat_gateway_hourly_usd       = 0.045  # $0.045/hour [citation:16]
    nat_gateway_per_gb_usd       = 0.045  # $0.045/GB processed [citation:16]

    # --- Interface VPC Endpoint ---
    interface_endpoint_hourly_usd = 0.01  # $0.01/hour per AZ [citation:16]
    interface_endpoint_per_gb_usd = 0.01  # $0.01/GB processed [citation:16]

    # --- Gateway VPC Endpoint (S3, DynamoDB) ---
    gateway_endpoint_hourly_usd  = 0.00   # Free [citation:7]

    # --- Transit Gateway ---
    transit_gateway_attachment_hourly_usd = 0.05  # $0.05/hour per VPC attachment [citation:16]
    transit_gateway_per_gb_usd            = 0.02  # $0.02/GB processed [citation:16]

    # --- Data Transfer ---
    cross_az_per_gb_usd          = 0.01   # $0.01/GB each way [citation:16]
    internet_egress_per_gb_usd   = 0.09   # $0.09/GB [citation:16]

    # --- Public IPv4 ---
    public_ipv4_hourly_usd       = 0.005  # $0.005/hour (approx) [citation:10]

    # Часов в месяце (730 для точности)
    hours_per_month              = 730
    hours_per_year               = 8760
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 2: Прогнозируемое потребление (имитация)
  # ------------------------------------------------------------------
  vpc_usage = {
    # Количество route tables
    route_tables_count           = (var.create_public_route_table ? 1 : 0) + (var.create_private_route_table ? 1 : 0)

    # NAT Gateway
    nat_gateways_count           = var.create_nat_gateway ? 1 : 0
    monthly_data_processed_gb    = var.monthly_data_processed_gb

    # VPC Endpoints
    interface_endpoints_count    = var.create_vpc_endpoints ? 2 : 0  # например, для SSM и EC2 Messages
    interface_endpoints_azs      = 2  # количество AZ

    # Transit Gateway
    transit_gateway_attachments  = var.enable_transit_gateway ? var.transit_gateway_attachments : 0
    transit_gateway_data_gb      = var.enable_transit_gateway ? 500 : 0

    # Data Transfer
    cross_az_transfer_gb         = 200
    internet_egress_gb           = 50
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 3: Детализированный расчёт затрат (построчный)
  # ------------------------------------------------------------------
  cost_breakdown = {
    # --- Route Table (бесплатно) ---
    route_table = {
      description = "Route Table (${local.vpc_usage.route_tables_count} шт.)"
      quantity    = local.vpc_usage.route_tables_count
      unit_price  = local.vpc_pricing.route_table_hourly_usd
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Route tables are free [citation:2][citation:12]"
    }

    # --- NAT Gateway: Hourly ---
    nat_hourly = {
      description = "NAT Gateway: почасовая ставка (${local.vpc_usage.nat_gateways_count} шт.)"
      quantity    = local.vpc_usage.nat_gateways_count
      unit_price  = local.vpc_pricing.nat_gateway_hourly_usd
      monthly_usd = local.vpc_usage.nat_gateways_count * local.vpc_pricing.nat_gateway_hourly_usd * local.vpc_pricing.hours_per_month
      yearly_usd  = local.vpc_usage.nat_gateways_count * local.vpc_pricing.nat_gateway_hourly_usd * local.vpc_pricing.hours_per_year
      notes       = "$0.045/hour [citation:16]"
    }

    # --- NAT Gateway: Data Processing ---
    nat_data = {
      description = "NAT Gateway: обработка данных (${local.vpc_usage.monthly_data_processed_gb} GB/мес)"
      quantity    = local.vpc_usage.monthly_data_processed_gb
      unit_price  = local.vpc_pricing.nat_gateway_per_gb_usd
      monthly_usd = local.vpc_usage.monthly_data_processed_gb * local.vpc_pricing.nat_gateway_per_gb_usd
      yearly_usd  = local.vpc_usage.monthly_data_processed_gb * local.vpc_pricing.nat_gateway_per_gb_usd * 12
      notes       = "$0.045/GB processed [citation:16]"
    }

    # --- Interface VPC Endpoints ---
    interface_endpoints = {
      description = "Interface VPC Endpoints (${local.vpc_usage.interface_endpoints_count} endpoints × ${local.vpc_usage.interface_endpoints_azs} AZ)"
      quantity    = local.vpc_usage.interface_endpoints_count * local.vpc_usage.interface_endpoints_azs
      unit_price  = local.vpc_pricing.interface_endpoint_hourly_usd
      monthly_usd = local.vpc_usage.interface_endpoints_count * local.vpc_usage.interface_endpoints_azs * local.vpc_pricing.interface_endpoint_hourly_usd * local.vpc_pricing.hours_per_month
      yearly_usd  = local.vpc_usage.interface_endpoints_count * local.vpc_usage.interface_endpoints_azs * local.vpc_pricing.interface_endpoint_hourly_usd * local.vpc_pricing.hours_per_year
      notes       = "$0.01/hour per AZ [citation:16]"
    }

    # --- Transit Gateway ---
    transit_gateway = {
      description = "Transit Gateway Attachments (${local.vpc_usage.transit_gateway_attachments} шт.)"
      quantity    = local.vpc_usage.transit_gateway_attachments
      unit_price  = local.vpc_pricing.transit_gateway_attachment_hourly_usd
      monthly_usd = local.vpc_usage.transit_gateway_attachments * local.vpc_pricing.transit_gateway_attachment_hourly_usd * local.vpc_pricing.hours_per_month
      yearly_usd  = local.vpc_usage.transit_gateway_attachments * local.vpc_pricing.transit_gateway_attachment_hourly_usd * local.vpc_pricing.hours_per_year
      notes       = "$0.05/hour per attachment [citation:16]"
    }

    # --- Cross-AZ Data Transfer ---
    cross_az_transfer = {
      description = "Cross-AZ Data Transfer (${local.vpc_usage.cross_az_transfer_gb} GB/мес)"
      quantity    = local.vpc_usage.cross_az_transfer_gb
      unit_price  = local.vpc_pricing.cross_az_per_gb_usd
      monthly_usd = local.vpc_usage.cross_az_transfer_gb * local.vpc_pricing.cross_az_per_gb_usd
      yearly_usd  = local.vpc_usage.cross_az_transfer_gb * local.vpc_pricing.cross_az_per_gb_usd * 12
      notes       = "$0.01/GB each way [citation:16]"
    }

    # --- Internet Egress ---
    internet_egress = {
      description = "Internet Egress (${local.vpc_usage.internet_egress_gb} GB/мес)"
      quantity    = local.vpc_usage.internet_egress_gb
      unit_price  = local.vpc_pricing.internet_egress_per_gb_usd
      monthly_usd = local.vpc_usage.internet_egress_gb * local.vpc_pricing.internet_egress_per_gb_usd
      yearly_usd  = local.vpc_usage.internet_egress_gb * local.vpc_pricing.internet_egress_per_gb_usd * 12
      notes       = "$0.09/GB [citation:16]"
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
      component   = "RouteTable"
      description = "Route Table (${local.vpc_usage.route_tables_count} шт.)"
      unit        = "hour"
      quantity    = local.vpc_usage.route_tables_count
      unit_price  = 0.00
      monthly_usd = 0.00
      yearly_usd  = 0.00
      notes       = "Route tables are free [citation:2][citation:12]"
    },
    {
      line_no     = 2
      service     = "VPC"
      component   = "NATGateway.Hourly"
      description = "NAT Gateway hourly"
      unit        = "hour"
      quantity    = local.vpc_usage.nat_gateways_count
      unit_price  = local.vpc_pricing.nat_gateway_hourly_usd
      monthly_usd = local.vpc_usage.nat_gateways_count * local.vpc_pricing.nat_gateway_hourly_usd * local.vpc_pricing.hours_per_month
      yearly_usd  = local.vpc_usage.nat_gateways_count * local.vpc_pricing.nat_gateway_hourly_usd * local.vpc_pricing.hours_per_year
      notes       = "$0.045/hour [citation:16]"
    },
    {
      line_no     = 3
      service     = "VPC"
      component   = "NATGateway.Data"
      description = "NAT Gateway data processing"
      unit        = "per GB"
      quantity    = local.vpc_usage.monthly_data_processed_gb
      unit_price  = local.vpc_pricing.nat_gateway_per_gb_usd
      monthly_usd = local.vpc_usage.monthly_data_processed_gb * local.vpc_pricing.nat_gateway_per_gb_usd
      yearly_usd  = local.vpc_usage.monthly_data_processed_gb * local.vpc_pricing.nat_gateway_per_gb_usd * 12
      notes       = "$0.045/GB [citation:16]"
    },
    {
      line_no     = 4
      service     = "VPC"
      component   = "InterfaceEndpoints"
      description = "Interface VPC Endpoints"
      unit        = "hour/AZ"
      quantity    = local.vpc_usage.interface_endpoints_count * local.vpc_usage.interface_endpoints_azs
      unit_price  = local.vpc_pricing.interface_endpoint_hourly_usd
      monthly_usd = local.vpc_usage.interface_endpoints_count * local.vpc_usage.interface_endpoints_azs * local.vpc_pricing.interface_endpoint_hourly_usd * local.vpc_pricing.hours_per_month
      yearly_usd  = local.vpc_usage.interface_endpoints_count * local.vpc_usage.interface_endpoints_azs * local.vpc_pricing.interface_endpoint_hourly_usd * local.vpc_pricing.hours_per_year
      notes       = "$0.01/hour per AZ [citation:16]"
    },
    {
      line_no     = 5
      service     = "VPC"
      component   = "TransitGateway"
      description = "Transit Gateway Attachments"
      unit        = "hour"
      quantity    = local.vpc_usage.transit_gateway_attachments
      unit_price  = local.vpc_pricing.transit_gateway_attachment_hourly_usd
      monthly_usd = local.vpc_usage.transit_gateway_attachments * local.vpc_pricing.transit_gateway_attachment_hourly_usd * local.vpc_pricing.hours_per_month
      yearly_usd  = local.vpc_usage.transit_gateway_attachments * local.vpc_pricing.transit_gateway_attachment_hourly_usd * local.vpc_pricing.hours_per_year
      notes       = "$0.05/hour per attachment [citation:16]"
    },
  ]

  # ------------------------------------------------------------------
  # СЕКЦИЯ 6: Расширенная разбивка по категориям (для дашбордов)
  # ------------------------------------------------------------------
  cost_by_category = {
    "VPC.RouteTable"        = 0.00
    "VPC.NATGateway"        = (local.vpc_usage.nat_gateways_count * local.vpc_pricing.nat_gateway_hourly_usd * local.vpc_pricing.hours_per_month) + (local.vpc_usage.monthly_data_processed_gb * local.vpc_pricing.nat_gateway_per_gb_usd)
    "VPC.Endpoints"         = local.vpc_usage.interface_endpoints_count * local.vpc_usage.interface_endpoints_azs * local.vpc_pricing.interface_endpoint_hourly_usd * local.vpc_pricing.hours_per_month
    "VPC.TransitGateway"    = local.vpc_usage.transit_gateway_attachments * local.vpc_pricing.transit_gateway_attachment_hourly_usd * local.vpc_pricing.hours_per_month
    "DataTransfer"          = (local.vpc_usage.cross_az_transfer_gb * local.vpc_pricing.cross_az_per_gb_usd) + (local.vpc_usage.internet_egress_gb * local.vpc_pricing.internet_egress_per_gb_usd)
  }

  cost_by_service = {
    "VPC"          = (local.vpc_usage.nat_gateways_count * local.vpc_pricing.nat_gateway_hourly_usd * local.vpc_pricing.hours_per_month) + (local.vpc_usage.monthly_data_processed_gb * local.vpc_pricing.nat_gateway_per_gb_usd) + (local.vpc_usage.interface_endpoints_count * local.vpc_usage.interface_endpoints_azs * local.vpc_pricing.interface_endpoint_hourly_usd * local.vpc_pricing.hours_per_month) + (local.vpc_usage.transit_gateway_attachments * local.vpc_pricing.transit_gateway_attachment_hourly_usd * local.vpc_pricing.hours_per_month)
    "DataTransfer" = (local.vpc_usage.cross_az_transfer_gb * local.vpc_pricing.cross_az_per_gb_usd) + (local.vpc_usage.internet_egress_gb * local.vpc_pricing.internet_egress_per_gb_usd)
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
      description          = "Текущая конфигурация (NAT: ${var.create_nat_gateway}, Endpoints: ${var.create_vpc_endpoints})"
      nat_enabled          = var.create_nat_gateway
      endpoints_enabled    = var.create_vpc_endpoints
      monthly_usd          = local.cost_monthly_total
    }
    "no_nat" = {
      description          = "Без NAT Gateway (экономия)"
      nat_enabled          = false
      endpoints_enabled    = var.create_vpc_endpoints
      monthly_usd          = local.cost_monthly_total - (local.vpc_usage.nat_gateways_count * local.vpc_pricing.nat_gateway_hourly_usd * local.vpc_pricing.hours_per_month) - (local.vpc_usage.monthly_data_processed_gb * local.vpc_pricing.nat_gateway_per_gb_usd)
    }
    "with_endpoints" = {
      description          = "С VPC Endpoints (экономия на NAT)"
      nat_enabled          = var.create_nat_gateway
      endpoints_enabled    = true
      monthly_usd          = local.cost_monthly_total + (2 * 2 * local.vpc_pricing.interface_endpoint_hourly_usd * local.vpc_pricing.hours_per_month)
    }
    "with_tgw" = {
      description          = "С Transit Gateway"
      nat_enabled          = var.create_nat_gateway
      endpoints_enabled    = var.create_vpc_endpoints
      monthly_usd          = local.cost_monthly_total + (1 * local.vpc_pricing.transit_gateway_attachment_hourly_usd * local.vpc_pricing.hours_per_month)
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
    nat_data_warning     = 500
    nat_data_crit        = 1000
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 10: Метаданные отчёта
  # ------------------------------------------------------------------
  cost_report_metadata = {
    generated_by       = "terraform"
    project            = var.project_name
    environment        = var.environment
    vpc_id             = aws_vpc.main.id
    route_tables_count = local.vpc_usage.route_tables_count
    nat_enabled        = var.create_nat_gateway
    aws_region         = var.aws_region
    currency           = local.cost_currency
    pricing_source     = "https://aws.amazon.com/vpc/pricing/ [citation:16]"
    pricing_date       = "2026-01-01"
    report_version     = "1.0.0"
    disclaimer         = "Это имитация. Для точных цифр используйте Infracost / AWS Cost Explorer."
    billing_note       = "Route Tables are free. Costs come from NAT Gateway, Endpoints, and Data Transfer [citation:16]"
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 11: Проверка лимитов и квот (имитация)
  # ------------------------------------------------------------------
  quota_checks = {
    max_route_tables_per_vpc      = 200
    max_routes_per_route_table    = 50
    max_vpc_peering_connections   = 125
    current_route_tables          = local.vpc_usage.route_tables_count
    current_routes                = 2 + (var.create_nat_gateway ? 1 : 0)
    route_tables_ok               = local.vpc_usage.route_tables_count <= 200
    routes_ok                     = (2 + (var.create_nat_gateway ? 1 : 0)) <= 50
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 12: Детализация по типам маршрутов (для документации)
  # ------------------------------------------------------------------
  route_type_details = {
    "Internet Gateway" = {
      description     = "Публичный доступ в интернет"
      cost            = "Free (IGW itself)"
      notes           = "Internet egress billed at $0.09/GB [citation:16]"
    }
    "NAT Gateway" = {
      description     = "Приватный доступ в интернет"
      cost            = "$0.045/hour + $0.045/GB [citation:16]"
      notes           = "Most expensive component"
    }
    "Transit Gateway" = {
      description     = "Hub-and-spoke connectivity"
      cost            = "$0.05/hour per attachment + $0.02/GB [citation:16]"
      notes           = "For multi-VPC architectures"
    }
    "VPC Peering" = {
      description     = "Direct VPC-to-VPC connectivity"
      cost            = "Free connection + data transfer [citation:7]"
      notes           = "Cross-AZ: $0.01/GB each way [citation:16]"
    }
    "Gateway Endpoint" = {
      description     = "S3/DynamoDB private access"
      cost            = "Free [citation:7]"
      notes           = "Saves NAT processing costs"
    }
    "Interface Endpoint" = {
      description     = "PrivateLink for AWS services"
      cost            = "$0.01/hour per AZ + $0.01/GB [citation:16]"
      notes           = "Cheaper than NAT for high-volume"
    }
  }
}