# locals.tf
# Локальные значения, включая имитацию расчёта затрат

locals {
  # Генерация имени секрета, если не указано
  secret_name = var.secret_name != null ? var.secret_name : "${var.project_name}-${var.environment}-${random_id.suffix.hex}"

  # Общие теги для всех ресурсов
  common_tags = {
    Name        = local.secret_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }

  # ============================================================
  # ИМИТАЦИЯ РАСЧЁТА ЗАТРАТ (Cost Estimation Simulation)
  # ============================================================
  # aws_secretsmanager_secret_rotation сам по себе бесплатен.
  # Затраты возникают от:
  #   - Хранения секретов (Secret Storage): $0.40 за секрет в месяц [citation:9]
  #   - API-вызовов (API Calls): $0.05 за 10 000 вызовов [citation:9]
  #   - Lambda-функции ротации: тарифицируется по стандартным ценам Lambda [citation:5][citation:20]
  # ============================================================

  # Стоимость хранения секретов (Secret Storage Cost)
  # $0.40 за секрет в месяц [citation:9][citation:17]
  secret_storage_cost_per_secret = 0.40
  monthly_storage_cost           = var.monthly_secret_count * local.secret_storage_cost_per_secret

  # Стоимость API-вызовов (API Call Cost)
  # $0.05 за 10 000 вызовов [citation:9]
  api_call_cost_per_10k = 0.05
  monthly_api_cost      = (var.monthly_api_calls / 10000) * local.api_call_cost_per_10k

  # Стоимость Lambda-функции ротации (Rotation Lambda Cost)
  # Lambda тарифицируется за количество запросов и время выполнения
  # Приблизительно: $0.20 за 1 млн запросов + $0.0000166667 за GB-секунду
  # Для простоты: предположим, что 1 ротация = 1 запрос + 0.5 секунды выполнения
  lambda_request_cost_per_million = 0.20
  lambda_gb_second_cost           = 0.0000166667
  lambda_memory_gb                = var.lambda_memory_size / 1024.0
  lambda_duration_seconds         = var.lambda_execution_duration_ms / 1000.0

  monthly_lambda_request_cost = (var.monthly_rotation_invocations / 1000000) * local.lambda_request_cost_per_million
  monthly_lambda_compute_cost = var.monthly_rotation_invocations * local.lambda_memory_gb * local.lambda_duration_seconds * local.lambda_gb_second_cost
  monthly_lambda_cost         = local.monthly_lambda_request_cost + local.monthly_lambda_compute_cost

  # Итоговая имитация месячных затрат
  estimated_monthly_cost = (
    local.monthly_storage_cost +
    local.monthly_api_cost +
    local.monthly_lambda_cost
  )

  # ============================================================
  # СТРУКТУРА ЗАТРАТ (Cost Breakdown)
  # ============================================================
  cost_breakdown = {
    secret_storage = {
      description = "Secrets Manager Storage (${var.monthly_secret_count} secrets)"
      unit_price  = "$0.40/secret/month"
      monthly     = local.monthly_storage_cost
    }
    api_calls = {
      description = "Secrets Manager API Calls (${var.monthly_api_calls} calls)"
      unit_price  = "$0.05/10,000 calls"
      monthly     = local.monthly_api_cost
    }
    rotation_lambda = {
      description = "Rotation Lambda (${var.monthly_rotation_invocations} invocations)"
      unit_price  = "~$0.20/1M requests + compute"
      monthly     = local.monthly_lambda_cost
    }
    rotation_resource = {
      description = "aws_secretsmanager_secret_rotation Resource"
      unit_price  = "$0.00 (free)"
      monthly     = 0
    }
  }

  # ============================================================
  # РЕКОМЕНДАЦИИ ПО ОПТИМИЗАЦИИ (FinOps Recommendations)
  # ============================================================
  finops_recommendations = [
    "1. Кэшируйте секреты в памяти приложений — это сокращает API-вызовы на 90-99% [citation:4].",
    "2. Объединяйте связанные поля (host, port, username, password) в один JSON-секрет — экономия до 75% [citation:4].",
    "3. Удаляйте неиспользуемые секреты — каждый секрет стоит $0.40/месяц даже если не используется [citation:4].",
    "4. Для статических значений без ротации используйте SSM Parameter Store (Standard tier бесплатен) [citation:4].",
    "5. Новые версии секретов, создаваемые ротацией, бесплатны — тарифицируется только Lambda-функция [citation:5][citation:20]."
  ]
}