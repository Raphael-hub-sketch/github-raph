resource "random_id" "suffix" {
  byte_length = 4
}

# ============================================================
# VPC
# ============================================================

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

# ============================================================
# SUBNETS
# ============================================================

resource "aws_subnet" "this" {
  count = 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-subnet-${count.index + 1}"
  })
}

# ============================================================
# REDSHIFT SUBNET GROUP
# ============================================================

resource "aws_redshift_subnet_group" "this" {
  name       = "${var.project_name}-${var.environment}-subnet-group"
  subnet_ids = aws_subnet.this[*].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-subnet-group"
  })
}

# ============================================================
# SECURITY GROUP
# ============================================================

resource "aws_security_group" "redshift" {
  name        = "${var.project_name}-${var.environment}-redshift-sg"
  description = "Security group for Redshift cluster"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Redshift port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-redshift-sg"
  })
}

# ============================================================
# IAM ROLE FOR REDSHIFT
# ============================================================

resource "aws_iam_role" "redshift" {
  name = "${var.project_name}-${var.environment}-redshift-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "redshift.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "redshift_s3" {
  role       = aws_iam_role.redshift.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# ============================================================
# S3 BUCKET FOR LOGS (if destination = s3)
# ============================================================

resource "aws_s3_bucket" "logs" {
  count = var.log_destination_type == "s3" ? 1 : 0

  bucket        = "${var.project_name}-${var.environment}-logs-${random_id.suffix.hex}"
  force_destroy = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-logs"
  })
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count = var.log_destination_type == "s3" ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "logs" {
  count = var.log_destination_type == "s3" ? 1 : 0

  bucket = aws_s3_bucket.logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "RedshiftLogDelivery"
      Effect    = "Allow"
      Principal = {
        Service = "redshift.amazonaws.com"
      }
      Action = [
        "s3:GetBucketAcl",
        "s3:PutObject"
      ]
      Resource = [
        aws_s3_bucket.logs[0].arn,
        "${aws_s3_bucket.logs[0].arn}/*"
      ]
    }]
  })
}

# ============================================================
# REDSHIFT CLUSTER
# ============================================================

resource "aws_redshift_cluster" "this" {
  cluster_identifier = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
  database_name      = var.redshift_database_name
  master_username    = var.redshift_master_username
  master_password    = var.redshift_master_password
  node_type          = var.redshift_node_type
  cluster_type       = "multi-node"
  number_of_nodes    = var.redshift_node_count

  cluster_subnet_group_name = aws_redshift_subnet_group.this.name
  vpc_security_group_ids    = [aws_security_group.redshift.id]

  iam_roles = [aws_iam_role.redshift.arn]

  publicly_accessible = false

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-cluster"
  })
}

# ============================================================
# MAIN RESOURCE: REDSHIFT LOGGING
# ============================================================

resource "aws_redshift_logging" "this" {
  cluster_identifier   = aws_redshift_cluster.this.id
  log_destination_type = var.log_destination_type

  # S3 destination (required when log_destination_type = s3) [citation:1]
  bucket_name   = var.log_destination_type == "s3" ? aws_s3_bucket.logs[0].id : null
  s3_key_prefix = var.log_destination_type == "s3" ? var.s3_key_prefix : null

  # CloudWatch destination (required when log_destination_type = cloudwatch) [citation:1]
  log_exports = var.log_destination_type == "cloudwatch" ? var.log_exports : null

  depends_on = [
    aws_redshift_cluster.this,
    aws_s3_bucket_policy.logs
  ]
}

# ============================================================
# DATA SOURCES
# ============================================================

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}