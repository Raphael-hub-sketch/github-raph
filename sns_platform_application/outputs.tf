# outputs.tf
# Выходные значения, включая имитацию отчёта о затратах

# ============================================================
# ИНФОРМАЦИЯ О PLATFORM APPLICATION
# ============================================================

output "platform_application_id" {
  description = "The ARN of the SNS platform application"
  value       = aws_sns_platform_application.this.id
}

output "platform_application_arn" {
  description = "The ARN of the SNS platform application"
  value       = aws_sns_platform_application.this.arn
}

output "platform_application_name" {
  description = "The name of the SNS platform application"
  value       = aws_sns_platform_application.this.name
}

output "platform" {
  description = "The platform of the SNS platform application"
  value       = aws_sns_platform_application.this.platform
}

# ============================================================
# ИНФОРМАЦИЯ О EVENT TOPICS
# ============================================================

output "event_topics" {
  description = "SNS Topics created for platform application events"
  value = var.create_event_topics ? {
    delivery_failure  = aws_sns_topic.event_delivery_failure[0].arn
    endpoint_created  = aws_sns_topic.event_endpoint_created[0].arn
    endpoint_deleted  = aws_sns_topic.event_endpoint_deleted[0].arn
    endpoint_updated  = aws_sns_topic.event_endpoint_updated[0].arn
  } : null
}

# ============================================================
# ИНФОРМАЦИЯ О FEEDBACK ROLES
# ============================================================

output "feedback_roles" {
  description = "IAM Roles created for feedback"
  value = var.create_feedback_roles ? {
    failure_feedback = aws_iam_role.failure_feedback[0].arn
    success_feedback = aws_iam_role.success_feedback[0].arn
  } : null
}

# ============================================================
# ИМИТАЦИЯ ВЫВОДА ЗАТРАТ (Cost Estimation Output)
# ============================================================

output "cost_estimation" {
  description = "Estimated monthly costs for the SNS platform application"
  value = {
    base_resource_cost = {
      description = "aws_sns_platform_application base resource"
      cost        = "$0.00"
    }
    publish = {
      description = "SNS Publish API Requests (${var.monthly_api_requests} requests)"
      cost        = "$${local.monthly_publish_cost}"
    }
    delivery = {
      description = "Mobile Push Notifications (${var.monthly_push_notifications} notifications)"
      cost        = "$${local.monthly_delivery_cost}"
    }
    endpoints = {
      description = "Platform Endpoint Operations (${var.monthly_endpoint_operations} operations)"
      cost        = "$${local.monthly_endpoint_cost}"
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
    "1. Первые 1 миллион мобильных push-уведомлений в месяц бесплатны [citation:1].",
    "2. Использование SNS для мобильных push ($0.50/1M) значительно дешевле SMS [citation:7].",
    "3. Мониторинг количества endpoints помогает избежать неожиданных затрат на операции.",
    "4. Feedback roles бесплатны, но CloudWatch Logs может генерировать расходы.",
    "5. Регулярный аудит неактивных endpoints снижает затраты на доставку."
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