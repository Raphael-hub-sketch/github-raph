# outputs.tf
# Выходные значения, включая имитацию отчёта о затратах

# ============================================================
# ИНФОРМАЦИЯ О БАКЕТЕ
# ============================================================

output "bucket_id" {
  description = "The ID of the S3 bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "The domain name of the S3 bucket"
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_region" {
  description = "The region of the S3 bucket"
  value       = aws_s3_bucket.this.region
}

output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.this.bucket
}

# ============================================================
# ИМИТАЦИЯ ВЫВОДА ЗАТРАТ (Cost Estimation Output)
# ============================================================

output "cost_estimation" {
  description = "Estimated monthly costs for the S3 bucket"
  value = {
    base_resource_cost = {
      description = "aws_s3_bucket base resource"
      cost        = "$0.00"
    }
    storage = {
      description = "S3 Standard Storage (${var.storage_gb} GB)"
      cost        = "$${local.monthly_storage_cost}"
    }
    requests = {
      description = "S3 API Requests (${var.monthly_requests} requests)"
      cost        = "$${local.monthly_request_cost}"
    }
    versioning = {
      description = "Versioning Overhead (${local.effective_versioning_overhead} GB)"
      cost        = "$${local.monthly_versioning_cost}"
    }
    logging = {
      description = "Access Logging (${local.effective_logging_gb} GB)"
      cost        = "$${local.monthly_logging_cost}"
    }
    lifecycle = {
      description = "Glacier Transition (${local.effective_transition_objects} objects)"
      cost        = "$${local.transition_cost}"
    }
    total = {
      description = "Estimated Monthly Total"
      cost        = "$${local.estimated_monthly_cost}"
    }
  }
}

output "cost_breakdown_table" {
  description = "Detailed cost breakdown table"
  value       = local.cost_breakdown
}

# ============================================================
# ИМИТАЦИЯ РЕКОМЕНДАЦИЙ ПО ОПТИМИЗАЦИИ (FinOps Recommendations)
# ============================================================

output "finops_recommendations" {
  description = "Cost optimization recommendations"
  value = [
    "1. Переход в Glacier после ${var.lifecycle_glacier_days} дней может снизить затраты на хранение до 84%.",
    "2. Удаление старых объектов после ${var.lifecycle_expiration_days} дней предотвращает накопление неиспользуемых данных.",
    "3. Использование S3 Intelligent-Tiering может автоматически оптимизировать классы хранения.",
    "4. Включение версионирования увеличивает затраты на ~${local.effective_versioning_overhead} GB, но обеспечивает защиту данных.",
    "5. Регулярный аудит неиспользуемых объектов помогает избежать лишних расходов."
  ]
}

# ============================================================
# ИНФОРМАЦИЯ ОБ АККАУНТЕ
# ============================================================

output "account_info" {
  description = "AWS account information"
  value = {
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
    user_arn   = data.aws_caller_identity.current.arn
  }
}