# locals.tf
# Локальные значения, включая имитацию расчёта затрат

locals {
  # Генерация имени бакета, если не указано
  bucket_name = var.bucket_name != null ? var.bucket_name : "${var.project_name}-${var.environment}-${random_id.suffix.hex}"

  # Общие теги для всех ресурсов
  common_tags = {
    Name        = local.bucket_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }

  # ============================================================
  # ИМИТАЦИЯ РАСЧЁТА ЗАТРАТ (Cost Estimation Simulation)
  # ============================================================
  # aws_s3_bucket сам по себе бесплатен.
  # Затраты возникают от хранения, запросов и доп. функций.
  # ============================================================

  # Стоимость хранения (Storage Cost)
  storage_cost_per_gb  = 0.023  # Standard S3 price per GB
  monthly_storage_cost = var.storage_gb * local.storage_cost_per_gb

  # Стоимость запросов (Request Cost)
  request_cost_per_1000 = 0.005
  monthly_request_cost  = (var.monthly_requests / 1000) * local.request_cost_per_1000

  # Стоимость версионирования (Versioning Cost)
  effective_versioning_overhead = var.enable_versioning ? var.versioning_overhead_gb : 0
  monthly_versioning_cost       = local.effective_versioning_overhead * local.storage_cost_per_gb

  # Стоимость логирования (Logging Cost)
  effective_logging_gb  = var.enable_logging ? var.logging_gb : 0
  monthly_logging_cost  = local.effective_logging_gb * local.storage_cost_per_gb

  # Стоимость перехода в Glacier (Lifecycle Transition Cost)
  effective_transition_objects = var.enable_lifecycle ? var.transition_objects : 0
  transition_cost              = (local.effective_transition_objects / 1000) * 0.01

  # Итоговая имитация месячных затрат
  estimated_monthly_cost = (
    local.monthly_storage_cost +
    local.monthly_request_cost +
    local.monthly_versioning_cost +
    local.monthly_logging_cost +
    local.transition_cost
  )

  # ============================================================
  # СТРУКТУРА ЗАТРАТ (Cost Breakdown)
  # ============================================================
  cost_breakdown = {
    storage = {
      description = "S3 Standard Storage (${var.storage_gb} GB)"
      unit_price  = "$0.023/GB"
      monthly     = local.monthly_storage_cost
    }
    requests = {
      description = "S3 API Requests (${var.monthly_requests} requests)"
      unit_price  = "$0.005/1000 requests"
      monthly     = local.monthly_request_cost
    }
    versioning = {
      description = "Versioning Overhead (${local.effective_versioning_overhead} GB)"
      unit_price  = "$0.023/GB"
      monthly     = local.monthly_versioning_cost
    }
    logging = {
      description = "Access Logging (${local.effective_logging_gb} GB)"
      unit_price  = "$0.023/GB"
      monthly     = local.monthly_logging_cost
    }
    lifecycle = {
      description = "Glacier Transition (${local.effective_transition_objects} objects)"
      unit_price  = "$0.01/1000 objects"
      monthly     = local.transition_cost
    }
  }
}