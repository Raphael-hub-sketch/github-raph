# locals.tf
# Локальные значения, включая имитацию расчёта затрат

locals {
  # Общие теги для всех ресурсов
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
    Resource    = "default-network-acl"
  }

  # ============================================================
  # ИМИТАЦИЯ РАСЧЁТА ЗАТРАТ (Cost Estimation Simulation)
  # ============================================================
  # aws_default_network_acl сам по себе бесплатен.
  # AWS явно указывает: "There is no additional charge for using
  # network ACLs" [citation:3][citation:6][citation:12].
  # Network ACLs являются бесплатным компонентом VPC [citation:17].
  #
  # Однако, Network ACL обрабатывает трафик, который может
  # генерировать косвенные затраты:
  #   - Data Transfer: $0.01/GB за cross-AZ трафик [citation:4]
  #   - NAT Gateway: $0.045/hour + $0.045/GB processed [citation:4]
  #   - Public IPv4: $0.005/hour [citation:4]
  # ============================================================

  # Базовая стоимость ресурса (всегда $0.00)
  base_resource_cost = 0.00

  # Косвенная стоимость обработки данных через ACL
  # (имитация, так как ACL сам по себе бесплатен)
  data_processing_cost_per_gb = 0.00  # ACL processing is free
  data_processing_cost        = var.monthly_data_processed_gb * local.data_processing_cost_per_gb

  # Косвенная стоимость вычислений правил (имитация)
  rule_evaluation_cost_per_million = 0.00  # ACL rule evaluation is free
  rule_evaluation_cost             = (var.monthly_rule_evaluations / 1000000) * local.rule_evaluation_cost_per_million

  # Итоговая имитация месячных затрат
  estimated_monthly_cost = (
    local.base_resource_cost +
    local.data_processing_cost +
    local.rule_evaluation_cost
  )

  # ============================================================
  # СТРУКТУРА ЗАТРАТ (Cost Breakdown)
  # ============================================================
  cost_breakdown = {
    base_resource = {
      description = "aws_default_network_acl Resource"
      unit_price  = "$0.00 (free)"
      monthly     = local.base_resource_cost
    }
    data_processing = {
      description = "Data Processing (${var.monthly_data_processed_gb} GB)"
      unit_price  = "$0.00/GB (ACL is free)"
      monthly     = local.data_processing_cost
    }
    rule_evaluation = {
      description = "Rule Evaluations (${var.monthly_rule_evaluations} evaluations)"
      unit_price  = "$0.00/1M evaluations (ACL is free)"
      monthly     = local.rule_evaluation_cost
    }
  }

  # ============================================================
  # РЕКОМЕНДАЦИИ ПО ОПТИМИЗАЦИИ (FinOps Recommendations)
  # ============================================================
  finops_recommendations = [
    "1. Network ACLs полностью бесплатны — нет прямых затрат на их использование [citation:3][citation:6].",
    "2. Косвенные затраты могут возникать от data transfer, NAT Gateway и public IPv4 [citation:4].",
    "3. Используйте VPC Gateway Endpoints для S3 и DynamoDB, чтобы сократить трафик через NAT (экономия $0.045/GB) [citation:4][citation:13].",
    "4. Для AWS-сервисов используйте Interface Endpoints ($0.01/GB) вместо NAT ($0.045/GB) [citation:13].",
    "5. Оптимизируйте правила ACL, чтобы избежать ненужного трафика между AZ ($0.01/GB) [citation:4].",
    "6. Помните: AWS не взимает плату за использование network ACLs [citation:12]."
  ]
}