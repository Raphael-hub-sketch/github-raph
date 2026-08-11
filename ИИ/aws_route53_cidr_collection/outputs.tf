# outputs.tf

# ============================================
# ИНФОРМАЦИЯ О КОЛЛЕКЦИИ
# ============================================

output "cidr_collection" {
  description = "Complete CIDR collection information"
  value = {
    id          = aws_route53_cidr_collection.this.id
    arn         = aws_route53_cidr_collection.this.arn
    name        = aws_route53_cidr_collection.this.name
    version     = aws_route53_cidr_collection.this.version
    tags        = aws_route53_cidr_collection.this.tags
  }
}

output "cidr_collection_id" {
  description = "The ID of the CIDR collection"
  value       = aws_route53_cidr_collection.this.id
}

output "cidr_collection_arn" {
  description = "The ARN of the CIDR collection"
  value       = aws_route53_cidr_collection.this.arn
}

output "cidr_collection_version" {
  description = "Current version of the CIDR collection"
  value       = aws_route53_cidr_collection.this.version
}

# ============================================
# ИНФОРМАЦИЯ О ЛОКАЦИЯХ
# ============================================

output "locations" {
  description = "Information about all CIDR locations"
  value = {
    for key, loc in aws_route53_cidr_location.locations :
    key => {
      id          = loc.id
      cidr_blocks = loc.cidr_blocks
    }
  }
}

output "location_names" {
  description = "List of location names"
  value       = keys(aws_route53_cidr_location.locations)
}

output "total_locations" {
  description = "Total number of locations"
  value       = length(aws_route53_cidr_location.locations)
}

output "total_cidr_blocks" {
  description = "Total number of CIDR blocks across all locations"
  value = sum([
    for loc in aws_route53_cidr_location.locations : length(loc.cidr_blocks)
  ])
}

# ============================================
# СВОДНАЯ ИНФОРМАЦИЯ
# ============================================

output "summary" {
  description = "Summary of the Route53 CIDR deployment"
  value = {
    collection_name   = local.collection_name
    collection_id     = aws_route53_cidr_collection.this.id
    collection_version = aws_route53_cidr_collection.this.version
    environment       = var.environment
    region            = data.aws_region.current.name
    account_id        = data.aws_caller_identity.current.account_id
    total_locations   = length(aws_route53_cidr_location.locations)
    total_cidrs       = local.total_cidr_blocks
    locations         = local.locations_summary
  }
}

locals {
  total_cidr_blocks = sum([
    for loc in aws_route53_cidr_location.locations : length(loc.cidr_blocks)
  ])

  locations_summary = {
    for key, loc in aws_route53_cidr_location.locations :
    key => {
      cidr_count = length(loc.cidr_blocks)
      cidrs      = loc.cidr_blocks
    }
  }
}

# ============================================
# ДОПОЛНИТЕЛЬНЫЕ ВЫВОДЫ
# ============================================

output "account_info" {
  description = "AWS account information"
  value = {
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
    user_arn   = data.aws_caller_identity.current.arn
  }
}

output "routing_records" {
  description = "Route53 CIDR routing records"
  value = var.create_route53_records ? {
    record_name = aws_route53_record.cidr_routing[0].name
    record_type = aws_route53_record.cidr_routing[0].type
    zone_id     = aws_route53_record.cidr_routing[0].zone_id
  } : null
}