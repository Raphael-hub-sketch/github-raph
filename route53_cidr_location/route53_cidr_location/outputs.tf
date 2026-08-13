# outputs.tf
output "cidr_collection_id" {
  description = "Идентификатор созданной CIDR коллекции"
  value       = aws_route53_cidr_collection.main.id
}

output "cidr_location_id" {
  description = "Идентификатор CIDR местоположения"
  value       = aws_route53_cidr_location.this.id
}

output "cidr_location_name" {
  description = "Название CIDR местоположения"
  value       = aws_route53_cidr_location.this.name
}

output "cidr_blocks_associated" {
  description = "CIDR блоки, ассоциированные с местоположением"
  value       = aws_route53_cidr_location.this.cidr_blocks
}