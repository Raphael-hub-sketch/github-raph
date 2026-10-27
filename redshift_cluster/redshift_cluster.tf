resource "aws_redshift_cluster" "this" {
  cluster_identifier = var.cluster_identifier
  database_name      = var.database_name
  master_username    = var.master_username
  master_password    = var.master_password

  node_type       = var.node_type
  cluster_type    = "multi-node"
  number_of_nodes = var.number_of_nodes

  cluster_subnet_group_name = aws_redshift_subnet_group.this.name
  vpc_security_group_ids    = [aws_security_group.redshift_sg.id]

  publicly_accessible = false
  encrypted           = true
  kms_key_id          = aws_kms_key.redshift.arn

  enhanced_vpc_routing = true
  multi_az             = false

  automated_snapshot_retention_period = 7
  manual_snapshot_retention_period    = 3
  skip_final_snapshot                 = true
  final_snapshot_identifier           = "${var.cluster_identifier}-final-snapshot"

  allow_version_upgrade = true
  apply_immediately     = true

  preferred_maintenance_window = "sun:03:00-sun:04:00"

  availability_zone_relocation_enabled = false

  port = 5439

  cluster_parameter_group_name = aws_redshift_parameter_group.this.name

  iam_roles = [aws_iam_role.redshift_role.arn]

  logging {
    enable        = true
    bucket_name   = aws_s3_bucket.redshift_logs.bucket
    s3_key_prefix = "redshift-logs/"
  }

  snapshot_copy {
    destination_region = "us-west-2"
    retention_period   = 7
  }

  tags = merge(local.redshift_tags, {
    Name                    = var.cluster_identifier
    CostSimulationTier      = "production-simulated"
    SimulatedMonthlyCostUSD = "2400"
    SimulatedHourlyRateUSD  = "3.33"
    CostAllocationTag       = "redshift-cluster"
  })

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [
      master_password,
      preferred_maintenance_window,
    ]
  }
}

resource "aws_redshift_subnet_group" "this" {
  name       = "${local.name_prefix}-redshift-subnet-group"
  subnet_ids = [
    aws_subnet.redshift_subnet_a.id,
    aws_subnet.redshift_subnet_b.id,
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redshift-subnet-group"
  })
}

resource "aws_redshift_parameter_group" "this" {
  name   = "${local.name_prefix}-redshift-param-group"
  family = "redshift-1.0"

  parameter {
    name  = "require_ssl"
    value = "true"
  }

  parameter {
    name  = "enable_user_activity_logging"
    value = "true"
  }

  parameter {
    name  = "max_cursor_result_set_size"
    value = "default"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redshift-param-group"
  })
}

resource "aws_kms_key" "redshift" {
  description             = "KMS key for Redshift cluster encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redshift-kms"
  })
}

resource "aws_kms_alias" "redshift" {
  name          = "alias/${local.name_prefix}-redshift"
  target_key_id = aws_kms_key.redshift.key_id
}

resource "aws_iam_role" "redshift_role" {
  name = "${local.name_prefix}-redshift-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redshift-role"
  })
}

resource "aws_iam_role_policy_attachment" "redshift_s3_read" {
  role       = aws_iam_role.redshift_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_s3_bucket" "redshift_logs" {
  bucket        = "${local.name_prefix}-redshift-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redshift-logs"
    CostSimulation = "logging-storage"
  })
}

resource "aws_s3_bucket_public_access_block" "redshift_logs" {
  bucket = aws_s3_bucket.redshift_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_caller_identity" "current" {}