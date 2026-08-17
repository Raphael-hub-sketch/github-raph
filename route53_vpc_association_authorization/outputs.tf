output "zone_id" {
  description = "ID созданной приватной зоны"
  value       = aws_route53_zone.private.zone_id
}

output "zone_arn" {
  description = "ARN созданной приватной зоны"
  value       = aws_route53_zone.private.arn
}

output "authorization_ids" {
  description = "ID созданных авторизаций (формат: zone_id:vpc_id) [citation:1]"
  value = {
    for k, v in aws_route53_vpc_association_authorization.this :
    k => v.id
  }
}

output "authorization_count" {
  description = "Общее количество созданных авторизаций"
  value       = local.association_count
}

# Информация о затратах из main.tf
output "cost_estimate" {
  description = "Имитация затрат на использование ресурсов Route53"
  value       = local.cost_breakdown
}

output "total_monthly_cost" {
  description = "Общая ориентировочная стоимость в месяц"
  value       = format("$%.2f", local.base_monthly_cost)
}