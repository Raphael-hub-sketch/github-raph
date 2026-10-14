# =====================================================================
# Traffic Policy Instance (запись на основе политики)
# ---------------------------------------------------------------------
# ВНИМАНИЕ: Это платный ресурс — ежемесячная плата за каждую запись.
# =====================================================================
resource "aws_route53_traffic_policy_instance" "main" {
  count = var.create_instance ? 1 : 0

  name                   = var.instance_name
  traffic_policy_id      = aws_route53_traffic_policy.main.id
  traffic_policy_version = aws_route53_traffic_policy.main.version
  hosted_zone_id         = var.hosted_zone_id
  ttl                    = var.instance_ttl
}