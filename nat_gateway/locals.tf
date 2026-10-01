# locals.tf
# Локальные значения, включая имитацию расчёта затрат

locals {
  # Генерация имени NAT Gateway, если не указано
  nat_gateway_name = var.nat_gateway_name != null ? var.nat_gateway_name : "${var.project_name}-${var.environment}-nat"

  # Общие теги для всех ресурсов
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }

  # ============================================================
  # ИМИТАЦИЯ РАСЧЁТА ЗАТРАТ (Cost Estimation Simulation)
  # ============================================================
  # aws_nat_gateway имеет два компонента оплаты:
  #   1. Почасовая плата: $0.045/час (независимо от трафика)
  #   2. Обработка данных: $0.045/GB
  #   3. Дополнительно: Public IPv4: $0.005/час
  #
  # NAT Gateway тарифицируется с момента создания до удаления,
  # даже если не обрабатывает трафик [citation:13].
  # ============================================================

  # Почасовая плата (Hourly Charge)
  # $0.045 за NAT Gateway в час [citation:3][citation:9]
  hourly_rate_per_nat = 0.045
  monthly_hourly_cost = var.nat_gateway_count * local.hourly_rate_per_nat * var.monthly_hours

  # Стоимость обработки данных (Data Processing Cost)
  # $0.045 за GB [citation:3][citation:9]
  data_processing_rate = 0.045
  monthly_data_cost    = var.monthly_data_processed_gb * local.data_processing_rate

  # Стоимость Public IPv4 (если включено)
  # $0.005 за час для каждого публичного IPv4 адреса
  public_ipv4_rate = 0.005
  monthly_ipv4_cost = var.include_public_ipv4_cost && var.connectivity_type == "public" ? var.nat_gateway_count * local.public_ipv4_rate * var.monthly_hours : 0

  # Итоговая имитация месячных затрат
  estimated_monthly_cost = (
    local.monthly_hourly_cost +
    local.monthly_data_cost +
    local.monthly_ipv4_cost
  )

  # ============================================================
  # СТРУКТУРА ЗАТРАТ (Cost Breakdown)
  # ============================================================
  cost_breakdown = {
    hourly_charge = {
      description = "NAT Gateway Hourly (${var.nat_gateway_count} gateways × ${var.monthly_hours} hours)"
      unit_price  = "$0.045/hour per NAT"
      monthly     = local.monthly_hourly_cost
    }
    data_processing = {
      description = "Data Processing (${var.monthly_data_processed_gb} GB)"
      unit_price  = "$0.045/GB"
      monthly     = local.monthly_data_cost
    }
    public_ipv4 = {
      description = "Public IPv4 Addresses (${var.nat_gateway_count} addresses)"
      unit_price  = "$0.005/hour per address"
      monthly     = local.monthly_ipv4_cost
    }
  }

  # ============================================================
  # СЦЕНАРИИ ЗАТРАТ (Cost Scenarios)
  # ============================================================
  cost_scenarios = {
    single_nat = {
      description = "Single NAT Gateway (dev/staging)"
      gateway_count = 1
      hourly_cost   = 1 * local.hourly_rate_per_nat * var.monthly_hours
      data_cost     = var.monthly_data_processed_gb * local.data_processing_rate
      total         = (1 * local.hourly_rate_per_nat * var.monthly_hours) + (var.monthly_data_processed_gb * local.data_processing_rate)
    }
    multi_az = {
      description = "One NAT per AZ (production, 3 AZs)"
      gateway_count = 3
      hourly_cost   = 3 * local.hourly_rate_per_nat * var.monthly_hours
      data_cost     = var.monthly_data_processed_gb * local.data_processing_rate
      total         = (3 * local.hourly_rate_per_nat * var.monthly_hours) + (var.monthly_data_processed_gb * local.data_processing_rate)
    }
  }

  # ============================================================
  # РЕКОМЕНДАЦИИ ПО ОПТИМИЗАЦИИ (FinOps Recommendations)
  # ============================================================
  finops_recommendations = [
    "1. Почасовая плата $0.045/час (~$32.85/месяц) взимается даже при нулевом трафике [citation:13].",
    "2. Используйте один NAT Gateway для dev/staging вместо по одному на AZ [citation:2][citation:13].",
    "3. Gateway VPC Endpoints для S3 и DynamoDB бесплатны и полностью исключают трафик через NAT [citation:13].",
    "4. Interface Endpoints ($0.01/GB) дешевле NAT ($0.045/GB) для трафика к AWS-сервисам [citation:2].",
    "5. Для низкого трафика рассмотрите NAT Instance (t4g.nano ~$3/месяц) [citation:3][citation:13].",
    "6. Мониторите BytesOutToDestination в CloudWatch — если 0 за 7 дней, NAT Gateway простаивает [citation:13]."
  ]
}