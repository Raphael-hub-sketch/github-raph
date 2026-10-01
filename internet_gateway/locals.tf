# locals.tf
# Локальные значения, включая имитацию расчёта затрат

locals {
  # Генерация имени Internet Gateway, если не указано
  igw_name = var.igw_name != null ? var.igw_name : "${var.project_name}-${var.environment}-igw"

  # Общие теги для всех ресурсов
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }

  # ============================================================
  # ИМИТАЦИЯ РАСЧЁТА ЗАТРАТ (Cost Estimation Simulation)
  # ============================================================
  # aws_internet_gateway сам по себе бесплатен.
  # AWS явно указывает: "There is no charge for an internet gateway,
  # but there are data transfer charges for EC2 instances that use
  # internet gateways" [citation:6][citation:14].
  #
  # Internet Gateway не имеет почасовой платы и не взимает плату
  # за обработку данных [citation:13][citation:16].
  #
  # Затраты возникают только от Data Transfer:
  #   - Egress to Internet: $0.09/GB (первые 10 TB/месяц) [citation:13]
  #   - Ingress from Internet: $0.00/GB (бесплатно) [citation:3]
  #   - AWS Free Tier: 100 GB бесплатного egress в месяц [citation:3]
  # ============================================================

  # Базовая стоимость ресурса (всегда $0.00)
  base_resource_cost = 0.00

  # Стоимость исходящего трафика (Egress Cost)
  # $0.09/GB для первых 10 TB/месяц [citation:13]
  egress_cost_per_gb = 0.09

  # Применение Free Tier (100 GB бесплатно) [citation:3]
  free_tier_gb = var.include_free_tier ? 100 : 0
  billable_egress_gb = max(0, var.monthly_egress_gb - local.free_tier_gb)

  monthly_egress_cost = local.billable_egress_gb * local.egress_cost_per_gb

  # Стоимость входящего трафика (Ingress Cost)
  # Входящий трафик из интернета бесплатен [citation:3]
  ingress_cost_per_gb = 0.00
  monthly_ingress_cost = var.monthly_ingress_gb * local.ingress_cost_per_gb

  # Итоговая имитация месячных затрат
  estimated_monthly_cost = (
    local.base_resource_cost +
    local.monthly_egress_cost +
    local.monthly_ingress_cost
  )

  # ============================================================
  # СТРУКТУРА ЗАТРАТ (Cost Breakdown)
  # ============================================================
  cost_breakdown = {
    base_resource = {
      description = "aws_internet_gateway Resource"
      unit_price  = "$0.00 (free)"
      monthly     = local.base_resource_cost
    }
    egress = {
      description = "Data Egress to Internet (${var.monthly_egress_gb} GB, ${local.free_tier_gb} GB free)"
      unit_price  = "$0.09/GB (first 10 TB)"
      monthly     = local.monthly_egress_cost
    }
    ingress = {
      description = "Data Ingress from Internet (${var.monthly_ingress_gb} GB)"
      unit_price  = "$0.00/GB (free)"
      monthly     = local.monthly_ingress_cost
    }
  }

  # ============================================================
  # РЕКОМЕНДАЦИИ ПО ОПТИМИЗАЦИИ (FinOps Recommendations)
  # ============================================================
  finops_recommendations = [
    "1. Internet Gateway полностью бесплатен — нет почасовой платы и платы за обработку [citation:13].",
    "2. Плата взимается только за исходящий трафик в интернет ($0.09/GB) [citation:13].",
    "3. AWS Free Tier предоставляет 100 GB бесплатного исходящего трафика в месяц [citation:3].",
    "4. Входящий трафик из интернета бесплатен [citation:3].",
    "5. Используйте Gateway VPC Endpoints для S3 и DynamoDB (бесплатно), чтобы избежать оплаты egress [citation:16].",
    "6. Для трафика к AWS-сервисам используйте Interface Endpoints вместо выхода в интернет [citation:16]."
  ]
}