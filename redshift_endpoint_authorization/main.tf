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

  publicly_accessible = false

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-cluster"
  })
}

# ============================================================
# MAIN RESOURCE: REDSHIFT ENDPOINT AUTHORIZATION
# ============================================================

resource "aws_redshift_endpoint_authorization" "this" {
  account            = var.grantee_account_id
  cluster_identifier = aws_redshift_cluster.this.cluster_identifier

  vpc_ids      = length(var.vpc_ids) > 0 ? var.vpc_ids : null
  force_delete = var.force_delete
}

# ============================================================
# DATA SOURCES
# ============================================================

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}