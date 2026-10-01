# locals.tf
# Локальные значения, включая имитацию расчёта затрат

locals {
  # Общие теги для всех ресурсов
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
    Resource    = "default-security-group"
  }

  # ============================================================
  # ИМИТАЦИЯ РАСЧЁТА ЗАТРАТ (Cost Estimation Simulation)
  # ============================================================
  # aws_default_security_group сам по себе бесплатен.
  # AWS явно указывает: "There is no additional charge for
  # using security groups" [citation:6][citation:10][citation:19].
  #
  # Security groups являются бесплатным компонентом VPC [citation:11].
  # Даже default security group не тарифицируется [citation:1][citation:7].
  #
  # Однако, security groups обрабатывают трафик, который может
  # генерировать косвенные затраты:
  #   - Data Transfer: $0.01/GB за cross-AZ трафик [citation:15]
  #   - NAT Gateway: $0.045/hour + $0.045/GB processed [citation:15]
  #   - Interface Endpoints: $0.01/hour/AZ + $0.01/GB [citation:15]
  # ============================================================

  # Базовая стоимость ресурса (всегда $0.00)
  base_resource_cost = 0.00

  # Косвенная стоимость обработки данных через security group
  # (имитация, так как security group сам по себе бесплатен)
  data_processing_cost_per_gb = 0.00  # Security group processing is free
  data_processing_cost        = var.monthly_data_processed_gb * local.data_processing_cost_per_gb

  # Косвенная стоимость вычислений правил (имитация)
  rule_evaluation_cost_per_million = 0.00  # Security group rule evaluation is free
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
      description = "aws_default_security_group Resource"
      unit_price  = "$0.00 (free)"
      monthly     = local.base_resource_cost
    }
    data_processing = {
      description = "Data Processing (${var.monthly_data_processed_gb} GB)"
      unit_price  = "$0.00/GB (SG is free)"
      monthly     = local.data_processing_cost
    }
    rule_evaluation = {
      description = "Rule Evaluations (${var.monthly_rule_evaluations} evaluations)"
      unit_price  = "$0.00/1M evaluations (SG is free)"
      monthly     = local.rule_evaluation_cost
    }
  }

  # ============================================================
  # РЕКОМЕНДАЦИИ ПО ОПТИМИЗАЦИИ (FinOps Recommendations)
  # ============================================================
  finops_recommendations = [
    "1. Security groups полностью бесплатны — нет прямых затрат на их использование [citation:6][citation:10][citation:19].",
    "2. Косвенные затраты могут возникать от data transfer, NAT Gateway и Interface Endpoints [citation:15].",
    "3. Используйте VPC Gateway Endpoints для S3 и DynamoDB (бесплатно), чтобы сократить трафик через NAT [citation:15].",
    "4. Для AWS-сервисов используйте Interface Endpoints ($0.01/GB) вместо NAT ($0.045/GB) [citation:15].",
    "5. Оптимизируйте правила security group, чтобы избежать ненужного трафика между AZ ($0.01/GB) [citation:15].",
    "6. Рекомендуется создавать отдельные security groups для ресурсов вместо использования default [citation:8][citation:9]."
  ]
}