# ==============================================================================
# outputs.tf
# Выходные значения для отладки и интеграции
# ==============================================================================

output "route53_zone_id" {
  description = "ID созданной частной зоны Route 53"
  value       = aws_route53_zone.private.id
}

output "route53_zone_name" {
  description = "Имя созданной частной зоны Route 53"
  value       = aws_route53_zone.private.name
}

output "vpc_association_authorization_id" {
  description = "ID созданной авторизации ассоциации VPC"
  value       = aws_route53_vpc_association_authorization.example.id
}

output "primary_vpc_id" {
  description = "ID основного VPC"
  value       = aws_vpc.primary.id
}

output "alternate_vpc_id" {
  description = "ID альтернативного VPC"
  value       = aws_vpc.alternate.id
}