output "zone_id" {
  description = "ID созданной зоны хостинга"
  value       = aws_route53_zone.main.zone_id
}

output "zone_name_servers" {
  description = "Список NS-серверов зоны"
  value       = aws_route53_zone.main.name_servers
}

output "record_ids" {
  description = "ID созданных DNS-записей"
  value = {
    for k, v in aws_route53_record.this :
    k => v.id
  }
}

output "record_fqdns" {
  description = "Полные доменные имена созданных записей"
  value = {
    for k, v in aws_route53_record.this :
    k => v.fqdn
  }
}

output "record_count" {
  description = "Общее количество созданных DNS-записей"
  value       = local.record_count
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