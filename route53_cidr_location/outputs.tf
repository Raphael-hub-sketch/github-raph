output "collection_id" {
  description = "ID созданной коллекции CIDR [citation:2]"
  value       = aws_route53_cidr_collection.main.id
}

output "collection_arn" {
  description = "ARN созданной коллекции CIDR [citation:2]"
  value       = aws_route53_cidr_collection.main.arn
}

output "location_names" {
  description = "Список имен созданных локаций"
  value       = keys(aws_route53_cidr_location.locations)
}

output "location_count" {
  description = "Общее количество созданных локаций"
  value       = local.location_count
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