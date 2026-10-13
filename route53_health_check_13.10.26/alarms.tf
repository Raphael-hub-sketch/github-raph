# =====================================================================
# CloudWatch Alarm на основе Health Check
# =====================================================================
resource "aws_cloudwatch_metric_alarm" "health_check" {
  count = var.create_cloudwatch_alarm ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-${var.health_check_name}-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "Health check status for ${var.health_check_name}"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]
  insufficient_data_actions = [var.sns_topic_arn]

  dimensions = {
    HealthCheckId = aws_route53_health_check.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-${var.health_check_name}-alarm"
  })
}