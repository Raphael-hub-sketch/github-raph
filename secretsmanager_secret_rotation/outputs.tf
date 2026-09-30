# outputs.tf
# Выходные значения, включая имитацию отчёта о затратах

# ============================================================
# ИНФОРМАЦИЯ О СЕКРЕТЕ
# ============================================================

output "secret_id" {
  description = "The ID of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.this.id
}

output "secret_arn" {
  description = "The ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.this.arn
}

output "secret_name" {
  description = "The name of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.this.name
}

output "secret_version_id" {
  description = "The version ID of the secret"
  value       = aws_secretsmanager_secret_version.this.version_id
}

# ============================================================
# ИНФОРМАЦИЯ О РОТАЦИИ
# ============================================================

output "rotation_enabled" {
  description = "Whether automatic rotation is enabled"
  value       = var.enable_rotation
}

output "rotation_id" {
  description = "The ARN of the secret rotation"
  value       = var.enable_rotation ? aws_secretsmanager_secret_rotation.this[0].id : null
}

output "rotation_lambda_arn" {
  description = "The ARN of the rotation Lambda function"
  value       = var.create_rotation_lambda ? aws_lambda_function.rotation[0].arn : var.existing_rotation_lambda_arn
}

# ============================================================
# ИМИТАЦИЯ ВЫВОДА ЗАТРАТ (Cost Estimation Output)
# ============================================================

output "cost_estimation" {
  description = "Estimated monthly costs for Secrets Manager rotation"
  value = {
    base_resource_cost = {
      description = "aws_secretsmanager_secret_rotation base resource"
      cost        = "$0.00"
    }
    secret_storage = {
      description = "Secrets Manager Storage (${var.monthly_secret_count} secrets)"
      cost        = "$${local.monthly_storage_cost}"
    }
    api_calls = {
      description = "Secrets Manager API Calls (${var.monthly_api_calls} calls)"
      cost        = "$${local.monthly_api_cost}"
    }
    rotation_lambda = {
      description = "Rotation Lambda (${var.monthly_rotation_invocations} invocations)"
      cost        = "$${local.monthly_lambda_cost}"
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
# РЕКОМЕНДАЦИИ ПО ОПТИМИЗАЦИИ (FinOps Recommendations)
# ============================================================

output "finops_recommendations" {
  description = "Cost optimization recommendations"
  value       = local.finops_recommendations
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