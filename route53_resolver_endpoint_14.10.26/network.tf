# =====================================================================
# VPC
# =====================================================================
resource "aws_vpc" "main" {
  count = var.create_vpc ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

# =====================================================================
# Subnets (минимум две в разных Availability Zones)
# =====================================================================
resource "aws_subnet" "resolver" {
  count = var.create_vpc ? length(var.subnet_cidrs) : 0

  vpc_id            = aws_vpc.main[0].id
  cidr_block        = var.subnet_cidrs[count.index]
  availability_zone = "${var.aws_region}${element(["a", "b", "c"], count.index)}"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-resolver-subnet-${count.index + 1}"
  })
}

# =====================================================================
# Security Group для Resolver Endpoint
# =====================================================================
resource "aws_security_group" "resolver" {
  count = var.create_vpc ? 1 : 0

  name        = "${var.project_name}-${var.environment}-resolver-sg"
  description = "Security group for Route 53 Resolver endpoint"
  vpc_id      = aws_vpc.main[0].id

  # DNS TCP
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "DNS TCP from allowed networks"
  }

  # DNS UDP
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "DNS UDP from allowed networks"
  }

  # DoH (если используется)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "DNS over HTTPS (DoH)"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-resolver-sg"
  })
}