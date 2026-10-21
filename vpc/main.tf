resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = var.instance_tenancy
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  assign_generated_ipv6_cidr_block = var.assign_generated_ipv6_cidr_block

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

locals {
  vpc_pricing = {
    vpc_hourly_usd                = 0.00
    dedicated_tenancy_hourly_usd  = 2.00
    nat_gateway_hourly_usd        = 0.045
    nat_gateway_data_per_gb_usd   = 0.045
    public_ipv4_hourly_usd        = 0.005
    hours_per_month               = 730
    hours_per_year                = 8760
  }

  vpc_usage = {
    vpc_count                     = 1
    nat_gateways                  = var.create_nat_gateway ? var.nat_gateways_count : 0
    nat_data_gb_per_month         = var.create_nat_gateway ? var.nat_data_gb_per_month : 0
    public_ipv4_addresses         = var.public_ipv4_addresses_count
    dedicated_tenancy             = var.instance_tenancy == "dedicated"
  }

  cost_breakdown = {
    vpc_base = {
      description = "VPC base (${local.vpc_usage.vpc_count} шт.)"
      quantity    = local.vpc_usage.vpc_count
      unit_price  = local.vpc_pricing.vpc_hourly_usd
      monthly_usd = local.vpc_usage.vpc_count * local.vpc_pricing.vpc_hourly_usd * local.vpc_pricing.hours_per_month
      yearly_usd  = local.vpc_usage.vpc_count * local.vpc_pricing.vpc_hourly_usd * local.vpc_pricing.hours_per_year
    }

    dedicated_tenancy = {
      description = "Dedicated tenancy surcharge"
      quantity    = local.vpc_usage.dedicated_tenancy ? 1 : 0
      unit_price  = local.vpc_pricing.dedicated_tenancy_hourly_usd
      monthly_usd = local.vpc_usage.dedicated_tenancy ? local.vpc_pricing.dedicated_tenancy_hourly_usd * local.vpc_pricing.hours_per_month : 0
      yearly_usd  = local.vpc_usage.dedicated_tenancy ? local.vpc_pricing.dedicated_tenancy_hourly_usd * local.vpc_pricing.hours_per_year : 0
    }

    nat_gateway_hourly = {
      description = "NAT Gateways hourly (${local.vpc_usage.nat_gateways} шт.)"
      quantity    = local.vpc_usage.nat_gateways
      unit_price  = local.vpc_pricing.nat_gateway_hourly_usd
      monthly_usd = local.vpc_usage.nat_gateways * local.vpc_pricing.nat_gateway_hourly_usd * local.vpc_pricing.hours_per_month
      yearly_usd  = local.vpc_usage.nat_gateways * local.vpc_pricing.nat_gateway_hourly_usd * local.vpc_pricing.hours_per_year
    }

    nat_gateway_data = {
      description = "NAT Gateway data processing (${local.vpc_usage.nat_data_gb_per_month} GB/мес)"
      quantity    = local.vpc_usage.nat_data_gb_per_month
      unit_price  = local.vpc_pricing.nat_gateway_data_per_gb_usd
      monthly_usd = local.vpc_usage.nat_data_gb_per_month * local.vpc_pricing.nat_gateway_data_per_gb_usd
      yearly_usd  = local.vpc_usage.nat_data_gb_per_month * local.vpc_pricing.nat_gateway_data_per_gb_usd * 12
    }

    public_ipv4 = {
      description = "Public IPv4 addresses (${local.vpc_usage.public_ipv4_addresses} шт.)"
      quantity    = local.vpc_usage.public_ipv4_addresses
      unit_price  = local.vpc_pricing.public_ipv4_hourly_usd
      monthly_usd = local.vpc_usage.public_ipv4_addresses * local.vpc_pricing.public_ipv4_hourly_usd * local.vpc_pricing.hours_per_month
      yearly_usd  = local.vpc_usage.public_ipv4_addresses * local.vpc_pricing.public_ipv4_hourly_usd * local.vpc_pricing.hours_per_year
    }
  }

  cost_monthly_total = sum([for k, v in local.cost_breakdown : v.monthly_usd])
  cost_yearly_total  = sum([for k, v in local.cost_breakdown : v.yearly_usd])
  cost_currency      = "USD"

  cost_line_items = [
    {
      line_no     = 1
      service     = "VPC"
      component   = "VPC.Base"
      description = "VPC base resource"
      unit        = "vpc"
      quantity    = local.vpc_usage.vpc_count
      unit_price  = local.vpc_pricing.vpc_hourly_usd
      monthly_usd = local.cost_breakdown.vpc_base.monthly_usd
      yearly_usd  = local.cost_breakdown.vpc_base.yearly_usd
      notes       = "VPC itself is free of charge"
    },
    {
      line_no     = 2
      service     = "VPC"
      component   = "Tenancy.Dedicated"
      description = "Dedicated tenancy surcharge"
      unit        = "hour"
      quantity    = local.vpc_usage.dedicated_tenancy ? 1 : 0
      unit_price  = local.vpc_pricing.dedicated_tenancy_hourly_usd
      monthly_usd = local.cost_breakdown.dedicated_tenancy.monthly_usd
      yearly_usd  = local.cost_breakdown.dedicated_tenancy.yearly_usd
      notes       = "Dedicated tenancy costs $2/hour per region"
    },
    {
      line_no     = 3
      service     = "VPC"
      component   = "NATGateway.Hourly"
      description = "NAT Gateway hourly charges"
      unit        = "gw/hour"
      quantity    = local.vpc_usage.nat_gateways
      unit_price  = local.vpc_pricing.nat_gateway_hourly_usd
      monthly_usd = local.cost_breakdown.nat_gateway_hourly.monthly_usd
      yearly_usd  = local.cost_breakdown.nat_gateway_hourly.yearly_usd
      notes       = "One NAT gateway per AZ recommended for HA"
    },
    {
      line_no     = 4
      service     = "VPC"
      component   = "NATGateway.Data"
      description = "NAT Gateway data processing"
      unit        = "per GB"
      quantity    = local.vpc_usage.nat_data_gb_per_month
      unit_price  = local.vpc_pricing.nat_gateway_data_per_gb_usd
      monthly_usd = local.cost_breakdown.nat_gateway_data.monthly_usd
      yearly_usd  = local.cost_breakdown.nat_gateway_data.yearly_usd
      notes       = "Data processing charges dominate at scale"
    },
    {
      line_no     = 5
      service     = "VPC"
      component   = "PublicIPv4"
      description = "Public IPv4 addresses"
      unit        = "ip/hour"
      quantity    = local.vpc_usage.public_ipv4_addresses
      unit_price  = local.vpc_pricing.public_ipv4_hourly_usd
      monthly_usd = local.cost_breakdown.public_ipv4.monthly_usd
      yearly_usd  = local.cost_breakdown.public_ipv4.yearly_usd
      notes       = "All public IPv4 addresses are charged since Feb 2024"
    }
  ]

  cost_by_category = {
    "VPC.Base"             = local.cost_breakdown.vpc_base.monthly_usd
    "VPC.Tenancy"          = local.cost_breakdown.dedicated_tenancy.monthly_usd
    "VPC.NAT.Hourly"       = local.cost_breakdown.nat_gateway_hourly.monthly_usd
    "VPC.NAT.Data"         = local.cost_breakdown.nat_gateway_data.monthly_usd
    "VPC.PublicIPv4"       = local.cost_breakdown.public_ipv4.monthly_usd
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
      description       = "Current configuration (${local.vpc_usage.nat_gateways} NAT GW, ${local.vpc_usage.public_ipv4_addresses} public IPv4)"
      nat_gateways      = local.vpc_usage.nat_gateways
      public_ipv4       = local.vpc_usage.public_ipv4_addresses
      monthly_usd       = local.cost_monthly_total
    }
    "no_nat" = {
      description       = "No NAT Gateways (public subnets only)"
      nat_gateways      = 0
      public_ipv4       = local.vpc_usage.public_ipv4_addresses
      monthly_usd       = local.cost_monthly_total - local.cost_breakdown.nat_gateway_hourly.monthly_usd - local.cost_breakdown.nat_gateway_data.monthly_usd
    }
    "single_nat" = {
      description       = "Single NAT Gateway"
      nat_gateways      = 1
      public_ipv4       = local.vpc_usage.public_ipv4_addresses
      monthly_usd       = local.cost_monthly_total - (local.vpc_usage.nat_gateways - 1) * local.vpc_pricing.nat_gateway_hourly_usd * local.vpc_pricing.hours_per_month
    }
    "no_public_ip" = {
      description       = "No public IPv4 addresses"
      nat_gateways      = local.vpc_usage.nat_gateways
      public_ipv4       = 0
      monthly_usd       = local.cost_monthly_total - local.cost_breakdown.public_ipv4.monthly_usd
    }
    "high_traffic" = {
      description       = "High NAT data (1000 GB/mo)"
      nat_gateways      = local.vpc_usage.nat_gateways
      public_ipv4       = local.vpc_usage.public_ipv4_addresses
      monthly_usd       = local.cost_monthly_total + (1000 - local.vpc_usage.nat_data_gb_per_month) * local.vpc_pricing.nat_gateway_data_per_gb_usd
    }
    "dedicated" = {
      description       = "Dedicated tenancy"
      nat_gateways      = local.vpc_usage.nat_gateways
      public_ipv4       = local.vpc_usage.public_ipv4_addresses
      monthly_usd       = local.cost_monthly_total + local.vpc_pricing.dedicated_tenancy_hourly_usd * local.vpc_pricing.hours_per_month
    }
  }

  budget_thresholds = {
    monthly_warning  = 150.00
    monthly_critical = 300.00
    yearly_max       = 3000.00
    notify_emails    = ["finops@example.com", "devops@example.com"]
    alert_on_breach  = true
  }

  cost_report_metadata = {
    generated_by   = "terraform"
    project        = var.project_name
    environment    = var.environment
    aws_region     = var.aws_region
    vpc_id         = aws_vpc.main.id
    vpc_cidr       = aws_vpc.main.cidr_block
    currency       = local.cost_currency
    pricing_source = "https://aws.amazon.com/vpc/pricing/"
    pricing_date   = "2025-01-01"
    report_version = "1.0.0"
    disclaimer     = "Imitation only. Use Infracost / AWS Cost Explorer for accuracy."
    billing_note   = "VPC is free; costs come from NAT Gateways, public IPv4, and data transfer"
  }

  quota_checks = {
    max_vpcs_per_region           = 5
    max_subnets_per_vpc           = 200
    max_security_groups_per_vpc   = 500
    max_internet_gateways_per_vpc = 1
    current_vpcs                  = 1
    vpcs_ok                       = 1 <= 5
  }

  vpc_feature_details = {
    "DNS.Support" = {
      description = "DNS resolution in VPC"
      default     = true
      cost        = "Free"
    }
    "DNS.Hostnames" = {
      description = "DNS hostnames for instances"
      default     = false
      cost        = "Free"
    }
    "IPv6" = {
      description = "IPv6 CIDR block"
      default     = false
      cost        = "Free (AWS-provided block)"
    }
    "Tenancy.Dedicated" = {
      description = "Dedicated hardware tenancy"
      default     = false
      cost        = "$2/hour per region"
    }
  }
}