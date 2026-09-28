# locals.tf
# Локальные значения, включая имитацию расчёта затрат

locals {
  # Генерация имени platform application, если не указано
  platform_application_name = var.platform_application_name != null ? var.platform_application_name : "${var.project_name}-${var.environment}-${var.platform}"

  # Общие теги для всех ресурсов
  common_tags = {
    Name        = local.platform_application_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
    Platform    = var.platform
  }

  # ============================================================
  # ИМИТАЦИЯ РАСЧЁТА ЗАТРАТ (Cost Estimation Simulation)
  # ============================================================
  # aws_sns_platform_application сам по себе бесплатен.
  # Затраты возникают от:
  #   - Публикации (Publish): $0.50 за 1 миллион запросов
  #   - Доставки (Delivery): $0.50 за 1 миллион мобильных push
  #   - API-запросов на создание/удаление endpoints
  #   - Опциональных функций (feedback roles, event topics)
  # ============================================================

  # Стоимость публикации (Publish Cost)
  # $0.50 за 1 миллион запросов
  publish_cost_per_million = 0.50
  monthly_publish_cost     = (var.monthly_api_requests / 1000000) * local.publish_cost_per_million

  # Стоимость доставки (Delivery Cost)
  # $0.50 за 1 миллион мобильных push-уведомлений
  delivery_cost_per_million = 0.50
  monthly_delivery_cost     = (var.monthly_push_notifications / 1000000) * local.delivery_cost_per_million

  # Стоимость операций с endpoints
  # Создание/удаление/обновление endpoints — $0.50 за 1 миллион запросов
  endpoint_cost_per_million = 0.50
  monthly_endpoint_cost     = (var.monthly_endpoint_operations / 1000000) * local.endpoint_cost_per_million

  # Итоговая имитация месячных затрат
  estimated_monthly_cost = (
    local.monthly_publish_cost +
    local.monthly_delivery_cost +
    local.monthly_endpoint_cost
  )

  # ============================================================
  # СТРУКТУРА ЗАТРАТ (Cost Breakdown)
  # ============================================================
  cost_breakdown = {
    publish = {
      description = "SNS Publish API Requests (${var.monthly_api_requests} requests)"
      unit_price  = "$0.50/1M requests"
      monthly     = local.monthly_publish_cost
    }
    delivery = {
      description = "Mobile Push Notifications (${var.monthly_push_notifications} notifications)"
      unit_price  = "$0.50/1M notifications"
      monthly     = local.monthly_delivery_cost
    }
    endpoints = {
      description = "Platform Endpoint Operations (${var.monthly_endpoint_operations} operations)"
      unit_price  = "$0.50/1M operations"
      monthly     = local.monthly_endpoint_cost
    }
    platform_application = {
      description = "SNS Platform Application Resource"
      unit_price  = "$0.00 (free)"
      monthly     = 0
    }
  }
}