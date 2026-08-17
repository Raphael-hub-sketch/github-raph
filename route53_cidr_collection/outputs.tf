output "collection_id" {
  description = "ID созданной коллекции CIDR"
  value       = aws_route53_cidr_collection.main.id
}

output "collection_arn" {
  description = "ARN созданной коллекции CIDR"
  value       = aws_route53_cidr_collection.main.arn
}