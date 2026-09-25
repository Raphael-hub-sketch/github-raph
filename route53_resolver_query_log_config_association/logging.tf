# =====================================================================
# CloudWatch Log Group (для целевого сервиса логов)
# =====================================================================
resource "aws_cloudwatch_log_group" "query_logs" {
  count = var.log_destination_type == "cloudwatch" ? 1 : 0

  name              = "/aws/route53/${var.project_name}-${var.environment}-query-logs"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-query-logs"
  })
}

# =====================================================================
# S3 Bucket (для целевого сервиса логов)
# =====================================================================
resource "aws_s3_bucket" "query_logs" {
  count = var.log_destination_type == "s3" ? 1 : 0

  bucket = "${var.project_name}-${var.environment}-dns-query-logs-${data.aws_caller_identity.current.account_id}"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-dns-query-logs"
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "query_logs" {
  count = var.log_destination_type == "s3" ? 1 : 0

  bucket = aws_s3_bucket.query_logs[0].id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    expiration {
      days = var.s3_log_retention_days
    }
  }
}

resource "aws_s3_bucket_policy" "query_logs" {
  count = var.log_destination_type == "s3" ? 1 : 0

  bucket = aws_s3_bucket.query_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRoute53Resolver"
        Effect = "Allow"
        Principal = {
          Service = "route53resolver.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.query_logs[0].arn}/*"
      }
    ]
  })
}

# =====================================================================
# Route53 Resolver Query Log Config
# =====================================================================
resource "aws_route53_resolver_query_log_config" "main" {
  name            = var.query_log_config_name
  destination_arn = var.log_destination_type == "cloudwatch" ? aws_cloudwatch_log_group.query_logs[0].arn : (
    var.log_destination_type == "s3" ? aws_s3_bucket.query_logs[0].arn : "arn:aws:firehose:${var.aws_region}:${data.aws_caller_identity.current.account_id}:deliverystream/${var.query_log_config_name}"
  )

  tags = merge(local.common_tags, {
    Name = var.query_log_config_name
  })
}

# =====================================================================
# Data source для account ID
# =====================================================================
data "aws_caller_identity" "current" {}