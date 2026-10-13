# =====================================================================
# CIDR Collection (если create_collection = true)
# =====================================================================
resource "aws_route53_cidr_collection" "main" {
  count = var.create_collection ? 1 : 0

  name = var.collection_name

  tags = merge(local.common_tags, {
    Name = var.collection_name
  })
}

# =====================================================================
# Локальное значение ID коллекции (созданной или существующей)
# =====================================================================
locals {
  collection_id = var.create_collection ? aws_route53_cidr_collection.main[0].id : var.existing_collection_id
}