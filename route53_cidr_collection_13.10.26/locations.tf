# =====================================================================
# CIDR Locations (CIDR-блоки внутри коллекции)
# =====================================================================
resource "aws_route53_cidr_location" "main" {
  count = length(var.locations)

  cidr_collection_id = aws_route53_cidr_collection.main.id
  name               = var.locations[count.index].name
  cidr_blocks        = var.locations[count.index].cidr_blocks
}