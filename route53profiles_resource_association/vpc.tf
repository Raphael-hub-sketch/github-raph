# =====================================================================
# VPC (для демонстрации ассоциации профиля)
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
# Profile Association с VPC (влияет на биллинг Route53 Profiles)
# =====================================================================
resource "aws_route53profiles_association" "main" {
  count = var.create_vpc && var.associate_profile_with_vpc ? 1 : 0

  name        = "${var.profile_name}-vpc-assoc"
  profile_id  = aws_route53profiles_profile.main.id
  resource_id = aws_vpc.main[0].id

  tags = merge(local.common_tags, {
    Name = "${var.profile_name}-vpc-assoc"
  })
}