resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  enable_dns64                    = var.enable_dns64
  assign_ipv6_address_on_creation = var.assign_ipv6_address_on_creation

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    Tier = "public"
    AZ   = var.availability_zones[count.index]
  })
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  enable_dns64                    = var.enable_dns64
  assign_ipv6_address_on_creation = var.assign_ipv6_address_on_creation

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-subnet-${count.index + 1}"
    Tier = "private"
    AZ   = var.availability_zones[count.index]
  })
}

resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-database-subnet-${count.index + 1}"
    Tier = "database"
    AZ   = var.availability_zones[count.index]
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

locals {
  subnet_pricing = {
    subnet_hourly_usd             = 0.00
    public_ipv4_hourly_usd        = 0.005
    nat_gateway_hourly_usd        = 0.045
    nat_gateway_data_per_gb_usd   = 0.045
    hours_per_month               = 720
    hours_per_year                = 8760
    free_tier_subnets             = 200
  }

  subnet_usage = {
    public_subnets_count          = length(var.public_subnet_cidrs)
    private_subnets_count         = length(var.private_subnet_cidrs)
    database_subnets_count        = length(var.database_subnet_cidrs)
    total_subnets_count           = length(var.public_subnet_cidrs) + length(var.private_subnet_cidrs) + length(var.database_subnet_cidrs)
    public_ipv4_addresses         = var.map_public_ip_on_launch ? length(var.public_subnet_cidrs) : 0
    nat_gateways                  = var.create_nat_gateway ? var.nat_gateways_count : 0
    nat_data_gb_per_month         = 100
    monthly_queries_millions      = 0
  }

  cost_breakdown = {
    subnets = {
      description = "VPC Subnets (${local.subnet_usage.total_subnets_count} шт.)"
      quantity    = local.subnet_usage.total_subnets_count
      unit_price  = local.subnet_pricing.subnet_hourly_usd
      monthly_usd = local.subnet_usage.total_subnets_count * local.subnet_pricing.subnet_hourly_usd * local.subnet_pricing.hours_per_month
      yearly_usd  = local.subnet_usage.total_subnets_count * local.subnet_pricing.subnet_hourly_usd * local.subnet_pricing.hours_per_year
    }

    public_ipv4 = {
      description = "Public IPv4 addresses (${local.subnet_usage.public_ipv4_addresses} шт.)"
      quantity    = local.subnet_usage.public_ipv4_addresses
      unit_price  = local.subnet_pricing.public_ipv4_hourly_usd
      monthly_usd = local.subnet_usage.public_ipv4_addresses * local.subnet_pricing.public_ipv4_hourly_usd * local.subnet_pricing.hours_per_month
      yearly_usd  = local.subnet_usage.public_ipv4_addresses * local.subnet_pricing.public_ipv4_hourly_usd * local.subnet_pricing.hours_per_year
    }

    nat_gateway = {
      description = "NAT Gateways (${local.subnet_usage.nat_gateways} шт.)"
      quantity    = local.subnet_usage.nat_gateways
      unit_price  = local.subnet_pricing.nat_gateway_hourly_usd
      monthly_usd = local.subnet_usage.nat_gateways * local.subnet_pricing.nat_gateway_hourly_usd * local.subnet_pricing.hours_per_month
      yearly_usd  = local.subnet_usage.nat_gateways * local.subnet_pricing.nat_gateway_hourly_usd * local.subnet_pricing.hours_per_year
    }

    nat_data = {
      description = "NAT Gateway data processing"
      quantity    = local.subnet_usage.nat_data_gb_per_month
      unit_price  = local.subnet_pricing.nat_gateway_data_per_gb_usd
      monthly_usd = local.subnet_usage.nat_data_gb_per_month * local.subnet_pricing.nat_gateway_data_per_gb_usd
      yearly_usd  = local.subnet_usage.nat_data_gb_per_month * local.subnet_pricing.nat_gateway_data_per_gb_usd * 12
    }
  }

  cost_monthly_total = sum([for k, v in local.cost_breakdown : v.monthly_usd])
  cost_yearly_total  = sum([for k, v in local.cost_breakdown : v.yearly_usd])
  cost_currency      = "USD"

  cost_line_items = [
    {
      line_no     = 1
      service     = "VPC"
      component   = "Subnets"
      description = "VPC Subnets (${local.subnet_usage.total_subnets_count} шт.)"
      unit        = "subnet/hour"
      quantity    = local.subnet_usage.total_subnets_count
      unit_price  = local.subnet_pricing.subnet_hourly_usd
      monthly_usd = local.cost_breakdown.subnets.monthly_usd
      yearly_usd  = local.cost_breakdown.subnets.yearly_usd
      notes       = "Subnets themselves are free of charge"
    },
    {
      line_no     = 2
      service     = "VPC"
      component   = "PublicIPv4"
      description = "Public IPv4 addresses"
      unit        = "ip/hour"
      quantity    = local.subnet_usage.public_ipv4_addresses
      unit_price  = local.subnet_pricing.public_ipv4_hourly_usd
      monthly_usd = local.cost_breakdown.public_ipv4.monthly_usd
      yearly_usd  = local.cost_breakdown.public_ipv4.yearly_usd
      notes       = "All public IPv4 addresses are charged since Feb 2024"
    },
    {
      line_no     = 3
      service     = "VPC"
      component   = "NATGateway.Hourly"
      description = "NAT Gateway hourly charges"
      unit        = "gw/hour"
      quantity    = local.subnet_usage.nat_gateways
      unit_price  = local.subnet_pricing.nat_gateway_hourly_usd
      monthly_usd = local.cost_breakdown.nat_gateway.monthly_usd
      yearly_usd  = local.cost_breakdown.nat_gateway.yearly_usd
      notes       = "One NAT gateway per AZ recommended"
    },
    {
      line_no     = 4
      service     = "VPC"
      component   = "NATGateway.Data"
      description = "NAT Gateway data processing"
      unit        = "per GB"
      quantity    = local.subnet_usage.nat_data_gb_per_month
      unit_price  = local.subnet_pricing.nat_gateway_data_per_gb_usd
      monthly_usd = local.cost_breakdown.nat_data.monthly_usd
      yearly_usd  = local.cost_breakdown.nat_data.yearly_usd
      notes       = "Data processing charges dominate at scale"
    }
  ]

  cost_by_category = {
    "VPC.Subnets"       = local.cost_breakdown.subnets.monthly_usd
    "VPC.PublicIPv4"    = local.cost_breakdown.public_ipv4.monthly_usd
    "VPC.NAT.Hourly"    = local.cost_breakdown.nat_gateway.monthly_usd
    "VPC.NAT.Data"      = local.cost_breakdown.nat_data.monthly_usd
  }

  cost_by_service = {
    "VPC" = local.cost_monthly_total
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
      description       = "Current configuration (${local.subnet_usage.total_subnets_count} subnets, ${local.subnet_usage.nat_gateways} NAT GW)"
      subnets_count     = local.subnet_usage.total_subnets_count
      nat_gateways      = local.subnet_usage.nat_gateways
      monthly_usd       = local.cost_monthly_total
    }
    "single_nat" = {
      description       = "Single NAT Gateway"
      subnets_count     = local.subnet_usage.total_subnets_count
      nat_gateways      = 1
      monthly_usd       = local.cost_monthly_total - (local.subnet_usage.nat_gateways - 1) * local.subnet_pricing.nat_gateway_hourly_usd * local.subnet_pricing.hours_per_month
    }
    "no_nat" = {
      description       = "No NAT Gateway"
      subnets_count     = local.subnet_usage.total_subnets_count
      nat_gateways      = 0
      monthly_usd       = local.cost_monthly_total - local.cost_breakdown.nat_gateway.monthly_usd - local.cost_breakdown.nat_data.monthly_usd
    }
    "private_only" = {
      description       = "Private subnets only"
      subnets_count     = local.subnet_usage.private_subnets_count
      nat_gateways      = local.subnet_usage.nat_gateways
      monthly_usd       = local.cost_monthly_total - local.cost_breakdown.public_ipv4.monthly_usd
    }
    "high_traffic" = {
      description       = "High NAT data (1000 GB/mo)"
      subnets_count     = local.subnet_usage.total_subnets_count
      nat_gateways      = local.subnet_usage.nat_gateways
      monthly_usd       = local.cost_monthly_total + (1000 - local.subnet_usage.nat_data_gb_per_month) * local.subnet_pricing.nat_gateway_data_per_gb_usd
    }
  }

  budget_thresholds = {
    monthly_warning  = 100.00
    monthly_critical = 200.00
    yearly_max       = 2000.00
    notify_emails    = ["finops@example.com", "devops@example.com"]
    alert_on_breach  = true
  }

  cost_report_metadata = {
    generated_by   = "terraform"
    project        = var.project_name
    environment    = var.environment
    aws_region     = var.aws_region
    vpc_id         = aws_vpc.main.id
    currency       = local.cost_currency
    pricing_source = "https://aws.amazon.com/vpc/pricing/"
    pricing_date   = "2025-01-01"
    report_version = "1.0.0"
    disclaimer     = "Imitation only. Use Infracost / AWS Cost Explorer for accuracy."
    billing_note   = "Subnets are free; billed items are public IPv4, NAT GW hourly and NAT data"
  }

  quota_checks = {
    max_subnets_per_vpc       = 200
    max_subnets_per_az        = 20
    current_subnets           = local.subnet_usage.total_subnets_count
    current_public            = local.subnet_usage.public_subnets_count
    current_private           = local.subnet_usage.private_subnets_count
    current_database          = local.subnet_usage.database_subnets_count
    subnets_ok                = local.subnet_usage.total_subnets_count <= 200
  }

  subnet_type_details = {
    "public" = {
      description       = "Public subnet with route to IGW"
      maps_public_ip    = true
      route_table       = "public"
      use_cases         = "Load balancers, bastion hosts, NAT gateways"
    }
    "private" = {
      description       = "Private subnet with route to NAT"
      maps_public_ip    = false
      route_table       = "private"
      use_cases         = "Application servers, containers, workers"
    }
    "database" = {
      description       = "Isolated database subnet"
      maps_public_ip    = false
      route_table       = "database"
      use_cases         = "RDS, ElastiCache, Redshift"
    }
  }
}