output "collection_id" {
  description = "ID созданной коллекции CIDR"
  value       = aws_route53_cidr_collection.main.id
}

output "collection_arn" {
  description = "ARN созданной коллекции CIDR"
  value       = aws_route53_cidr_collection.main.arn
}

output "location_names" {
  description = "Список имен созданных локаций"
  value       = keys(aws_route53_cidr_location.locations)
}