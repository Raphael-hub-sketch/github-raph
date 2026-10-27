resource "aws_redshift_snapshot_schedule" "this" {
  identifier = "${local.name_prefix}-snapshot-schedule"

  definitions = [
    "rate(12 hours)",
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-snapshot-schedule"
    CostSimulation = "backup-storage"
  })
}

resource "aws_redshift_snapshot_copy_grant" "this" {
  snapshot_copy_grant_name = "${local.name_prefix}-snapshot-copy-grant"
  kms_key_id               = aws_kms_key.redshift.arn

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-snapshot-copy-grant"
  })
}

resource "aws_redshift_event_subscription" "this" {
  name          = "${local.name_prefix}-redshift-events"
  sns_topic_arn = aws_sns_topic.redshift_events.arn
  source_type   = "cluster"
  source_ids    = [aws_redshift_cluster.this.id]
  severity      = "INFO"

  event_categories = [
    "monitoring",
    "management",
    "security",
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redshift-events"
  })
}

resource "aws_sns_topic" "redshift_events" {
  name = "${local.name_prefix}-redshift-events"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redshift-sns"
  })
}

resource "aws_cloudwatch_metric_alarm" "redshift_cpu" {
  alarm_name          = "${local.name_prefix}-redshift-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/Redshift"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Redshift CPU utilization above 80%"
  alarm_actions       = [aws_sns_topic.redshift_events.arn]

  dimensions = {
    ClusterIdentifier = aws_redshift_cluster.this.cluster_identifier
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redshift-cpu-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "redshift_storage" {
  alarm_name          = "${local.name_prefix}-redshift-storage-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "PercentageDiskSpaceUsed"
  namespace           = "AWS/Redshift"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Redshift disk space usage above 85%"
  alarm_actions       = [aws_sns_topic.redshift_events.arn]

  dimensions = {
    ClusterIdentifier = aws_redshift_cluster.this.cluster_identifier
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redshift-storage-alarm"
  })
}

resource "aws_redshift_cluster_iam_roles" "additional" {
  cluster_identifier = aws_redshift_cluster.this.cluster_identifier
  iam_role_arns      = [aws_iam_role.redshift_role.arn]
}