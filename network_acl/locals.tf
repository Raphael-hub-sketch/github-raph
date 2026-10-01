# locals.tf
# Локальные значения, включая имитацию расчёта затрат

locals {
  # Генерация имени Network ACL, если не указано
  nacl_name = var.nacl_name != null ? var.nacl_name : "${var.project_name}-${var.environment}-nacl"

  # Общие теги для всех ресурсов
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
    Resource    = "network-acl"
  }

  # ============================================================
  # ИМИТАЦИЯ РАСЧЁТА ЗАТРАТ (Cost Estimation Simulation)
  # ============================================================
  # aws_network_acl сам по себе полностью бесплатен.
  # AWS явно указывает: "There is no additional charge for using
  # network ACLs" [citation:5].
  # Network ACLs входят в список бесплатных компонентов VPC [citation:15].
  #
  # Затраты могут возникать только от косвенных факторов:
  #   - NAT Gateway: $0.045/hour + $0.045/GB [citation:18]
  #   - Cross-AZ Data Transfer: $0.01/GB [citation:4]
  #   - Public IPv4: $0.005/hour
  # ============================================================

  # Базовая стоимость ресурса (всегда $0.00)
  base_resource_cost = 0.00

  # Косвенная стоимость обработки данных через NACL
  # (имитация, так как NACL сам по себе бесплатен)
  nacl_processing_cost = 0.00  # NACL processing is free [citation:5]

  # Стоимость cross-AZ трафика (косвенная, если трафик идёт между AZ)
  cross_az_cost_per_gb = 0.01  # $0.01/GB in each direction [citation:4]
  cross_az_cost        = var.cross_az_data_gb * local.cross_az_cost_per_gb

  # Стоимость NAT Gateway (опционально, для контекста)
  # NACL не требует NAT, но если трафик идёт через NAT, это создаёт затраты
  nat_hourly_cost     = 0.045  # $0.045/hour [citation:18]
  nat_gb_cost         = 0.045  # $0.045/GB [citation:18]
  nat_monthly_hours   = 730
  nat_base_cost       = local.nat_hourly_cost * local.nat_monthly_hours
  nat_data_cost       = var.monthly_data_processed_gb * local.nat_gb_cost
  nat_total_cost      = var.include_nat_cost ? (local.nat_base_cost + local.nat_data_cost) : 0

  # Итоговая имитация месячных затрат (только косвенные)
  estimated_monthly_cost = (
    local.base_resource_cost +
    local.nacl_processing_cost +
    local.cross_az_cost +
    local.nat_total_cost
  )

  # ============================================================
  # СТРУКТУРА ЗАТРАТ (Cost Breakdown)
  # ============================================================
  cost_breakdown = {
    base_resource = {
      description = "aws_network_acl Resource"
      unit_price  = "$0.00 (free)"
      monthly     = local.base_resource_cost
    }
    nacl_processing = {
      description = "NACL Traffic Processing (${var.monthly_data_processed_gb} GB)"
      unit_price  = "$0.00/GB (NACL is free)"
      monthly     = local.nacl_processing_cost
    }
    cross_az = {
      description = "Cross-AZ Data Transfer (${var.cross_az_data_gb} GB)"
      unit_price  = "$0.01/GB"
      monthly     = local.cross_az_cost
    }
    nat_gateway = {
      description = "NAT Gateway (optional, ${var.monthly_data_processed_gb} GB)"
      unit_price  = "$0.045/hour + $0.045/GB"
      monthly     = local.nat_total_cost
    }
  }

  # ============================================================
  # РЕКОМЕНДАЦИИ ПО ОПТИМИЗАЦИИ (FinOps Recommendations)
  # ============================================================
  finops_recommendations = [
    "1. Network ACLs полностью бесплатны — нет прямых затрат на их использование [citation:5].",
    "2. NACL — это stateless фильтр: ответы на разрешённый входящий трафик требуют отдельного исходящего правила [citation:1][citation:8].",
    "3. Косвенные затраты могут возникать от NAT Gateway ($0.045/GB) и cross-AZ трафика ($0.01/GB) [citation:18].",
    "4. Используйте Gateway VPC Endpoints для S3 и DynamoDB (бесплатно), чтобы сократить трафик через NAT [citation:14].",
    "5. Правила NACL оцениваются по номеру от меньшего к большему — оставляйте промежутки (10, 20, 30) для будущих правил [citation:1].",
    "6. Помните: NACL не фильтрует DNS (Route 53 Resolver), DHCP, IMDS и метаданные [citation:1][citation:12]."
  ]
}