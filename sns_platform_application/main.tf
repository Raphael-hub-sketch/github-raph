# main.tf
# Основные ресурсы: SNS Platform Application и связанные с ним конфигурации

# ============================================================
# RANDOM ID FOR RESOURCE NAMING
# ============================================================

resource "random_id" "suffix" {
  byte_length = 4
}

# ============================================================
# SNS TOPICS FOR PLATFORM APPLICATION EVENTS
# ============================================================
# SNS Topics для обработки событий платформенного приложения.
# Эти темы бесплатны, но публикация в них тарифицируется.
# ============================================================

resource "aws_sns_topic" "event_delivery_failure" {
  count = var.create_event_topics ? 1 : 0

  name = "${local.platform_application_name}-delivery-failure"

  tags = merge(local.common_tags, {
    Purpose = "event-notification"
    EventType = "delivery-failure"
  })

  # ============================================================
  # COST IMPACT: SNS Topic
  # ============================================================
  # SNS Topics themselves are free.
  # Publish requests to this topic are billed at $0.50/1M.
  # ============================================================
}

resource "aws_sns_topic" "event_endpoint_created" {
  count = var.create_event_topics ? 1 : 0

  name = "${local.platform_application_name}-endpoint-created"

  tags = merge(local.common_tags, {
    Purpose = "event-notification"
    EventType = "endpoint-created"
  })
}

resource "aws_sns_topic" "event_endpoint_deleted" {
  count = var.create_event_topics ? 1 : 0

  name = "${local.platform_application_name}-endpoint-deleted"

  tags = merge(local.common_tags, {
    Purpose = "event-notification"
    EventType = "endpoint-deleted"
  })
}

resource "aws_sns_topic" "event_endpoint_updated" {
  count = var.create_event_topics ? 1 : 0

  name = "${local.platform_application_name}-endpoint-updated"

  tags = merge(local.common_tags, {
    Purpose = "event-notification"
    EventType = "endpoint-updated"
  })
}

# ============================================================
# IAM ROLES FOR FEEDBACK
# ============================================================
# IAM роли для получения success/failure feedback от SNS.
# Эти роли позволяют SNS писать в CloudWatch Logs.
# ============================================================

resource "aws_iam_role" "failure_feedback" {
  count = var.create_feedback_roles ? 1 : 0

  name = "${local.platform_application_name}-failure-feedback"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Purpose = "sns-feedback"
  })

  # ============================================================
  # COST IMPACT: IAM Role
  # ============================================================
  # IAM Roles are free.
  # CloudWatch Logs charges apply for log storage.
  # ============================================================
}

resource "aws_iam_role_policy" "failure_feedback" {
  count = var.create_feedback_roles ? 1 : 0

  name = "${local.platform_application_name}-failure-feedback-policy"
  role = aws_iam_role.failure_feedback[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "success_feedback" {
  count = var.create_feedback_roles ? 1 : 0

  name = "${local.platform_application_name}-success-feedback"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Purpose = "sns-feedback"
  })
}

resource "aws_iam_role_policy" "success_feedback" {
  count = var.create_feedback_roles ? 1 : 0

  name = "${local.platform_application_name}-success-feedback-policy"
  role = aws_iam_role.success_feedback[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================
# MAIN SNS PLATFORM APPLICATION RESOURCE
# ============================================================
# Ресурс aws_sns_platform_application является основным.
# Стоимость этого ресурса: $0.00 (сам ресурс бесплатен).
# ============================================================

resource "aws_sns_platform_application" "this" {
  name    = local.platform_application_name
  platform = var.platform

  platform_credential = var.platform_credential
  platform_principal  = var.platform_principal

  # ============================================================
  # EVENT TOPICS
  # ============================================================
  # SNS Topics, которые срабатывают при событиях endpoints.
  # ============================================================

  event_delivery_failure_topic_arn = (
    var.create_event_topics
    ? aws_sns_topic.event_delivery_failure[0].arn
    : var.event_delivery_failure_topic_arn
  )

  event_endpoint_created_topic_arn = (
    var.create_event_topics
    ? aws_sns_topic.event_endpoint_created[0].arn
    : var.event_endpoint_created_topic_arn
  )

  event_endpoint_deleted_topic_arn = (
    var.create_event_topics
    ? aws_sns_topic.event_endpoint_deleted[0].arn
    : var.event_endpoint_deleted_topic_arn
  )

  event_endpoint_updated_topic_arn = (
    var.create_event_topics
    ? aws_sns_topic.event_endpoint_updated[0].arn
    : var.event_endpoint_updated_topic_arn
  )

  # ============================================================
  # FEEDBACK ROLES
  # ============================================================
  # IAM роли для получения feedback от SNS.
  # ============================================================

  failure_feedback_role_arn = (
    var.create_feedback_roles
    ? aws_iam_role.failure_feedback[0].arn
    : var.failure_feedback_role_arn
  )

  success_feedback_role_arn = (
    var.create_feedback_roles
    ? aws_iam_role.success_feedback[0].arn
    : var.success_feedback_role_arn
  )

  success_feedback_sample_rate = var.success_feedback_sample_rate

  # ============================================================
  # ИМИТАЦИЯ ЗАТРАТ ДЛЯ aws_sns_platform_application
  # ============================================================
  # Base Resource Cost: $0.00 (сам ресурс бесплатен)
  # Monthly Publish (${var.monthly_api_requests} requests): ~$${local.monthly_publish_cost}
  # Monthly Delivery (${var.monthly_push_notifications} notifications): ~$${local.monthly_delivery_cost}
  # Monthly Endpoint Operations: ~$${local.monthly_endpoint_cost}
  # ---------------------------------
  # Estimated Monthly Total: ~$${local.estimated_monthly_cost}
  # ============================================================
}

# ============================================================
# DATA SOURCES
# ============================================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}