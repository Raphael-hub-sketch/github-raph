# =====================================================================
# SNS Topic (если create_topic = true)
# =====================================================================
resource "aws_sns_topic" "main" {
  count = var.create_topic ? 1 : 0

  name = var.topic_name

  tags = merge(local.common_tags, {
    Name = var.topic_name
  })
}

# =====================================================================
# Локальное значение ARN топика (созданного или существующего)
# =====================================================================
locals {
  topic_arn = var.create_topic ? aws_sns_topic.main[0].arn : var.existing_topic_arn
}