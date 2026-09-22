# =====================================================================
# Route53 Profile
# =====================================================================
resource "aws_route53profiles_profile" "main" {
  name = var.profile_name

  tags = merge(local.common_tags, {
    Name = var.profile_name
  })
}