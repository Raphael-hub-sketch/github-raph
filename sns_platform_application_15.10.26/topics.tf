# topics.tf
resource "aws_sns_topic" "event_endpoint_created" {
  count = var.create_event_topics ? 1 : 0

  name = "${var.project_name}-${var.environment}-push-endpoint-created"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-push-endpoint-created"
    Role = "event-endpoint-created"
  })
}

resource "aws_sns_topic" "event_endpoint_updated" {
  count = var.create_event_topics ? 1 : 0

  name = "${var.project_name}-${var.environment}-push-endpoint-updated"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-push-endpoint-updated"
    Role = "event-endpoint-updated"
  })
}

resource "aws_sns_topic" "event_endpoint_deleted" {
  count = var.create_event_topics ? 1 : 0

  name = "${var.project_name}-${var.environment}-push-endpoint-deleted"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-push-endpoint-deleted"
    Role = "event-endpoint-deleted"
  })
}

resource "aws_sns_topic" "event_delivery_failure" {
  count = var.create_event_topics ? 1 : 0

  name = "${var.project_name}-${var.environment}-push-delivery-failure"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-push-delivery-failure"
    Role = "event-delivery-failure"
  })
}