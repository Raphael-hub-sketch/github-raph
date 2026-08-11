# main.tf

# ============================================
# ЛОКАЛЬНЫЕ ЗНАЧЕНИЯ
# ============================================

locals {
  # Генерация имени коллекции, если не указано
  collection_name = var.cidr_collection_name != null ? var.cidr_collection_name : "${var.project_name}-${var.environment}-collection"

  # Общие теги для всех ресурсов
  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }, var.cidr_collection_tags)

  # Случайный суффикс для уникальности (если нужно)
  random_suffix = random_string.this.result
}

resource "random_string" "this" {
  length  = 4
  special = false
  upper   = false
}

# ============================================
# ОСНОВНОЙ РЕСУРС: Route53 CIDR Collection
# ============================================

resource "aws_route53_cidr_collection" "this" {
  name = local.collection_name

  tags = merge(local.common_tags, {
    Name = local.collection_name
  })
}

# ============================================
# CIDR LOCATIONS
# ============================================

resource "aws_route53_cidr_location" "this" {
  # Создаем только если включено и переданы локации
  count = var.enable_locations && length(var.locations) > 0 ? length(var.locations) : 0

  cidr_collection_id = aws_route53_cidr_collection.this.id
  name               = keys(var.locations)[count.index]
  cidr_blocks        = values(var.locations)[count.index].cidr_blocks

  # Примечание: ресурс не поддерживает теги
}

# Альтернативный вариант через for_each (более удобный)
resource "aws_route53_cidr_location" "locations" {
  for_each = var.enable_locations ? var.locations : {}

  cidr_collection_id = aws_route53_cidr_collection.this.id
  name               = each.key
  cidr_blocks        = each.value.cidr_blocks
}

# ============================================
# DATA SOURCES
# ============================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_route53_zone" "this" {
  count = var.create_route53_records && var.hosted_zone_id != null ? 1 : 0
  zone_id = var.hosted_zone_id
}

# ============================================
# РЕСУРСЫ ДЛЯ РОУТИНГА (опционально)
# ============================================

resource "aws_route53_record" "cidr_routing" {
  count = var.create_route53_records ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = var.record_name
  ttl     = var.record_ttl
  type    = "A"

  cidr_routing_policy {
    collection_id = aws_route53_cidr_collection.this.id
    location_name = keys(var.locations)[0] # Берем первую локацию для примера
  }

  set_identifier = "cidr-routing-${keys(var.locations)[0]}"
  records        = ["192.0.2.1"]

  depends_on = [aws_route53_cidr_location.locations]
}

# ============================================
# ДОПОЛНИТЕЛЬНЫЙ РЕСУРС: random для демонстрации
# ============================================

resource "random_id" "suffix" {
  byte_length = 8
}

# ============================================
# ТАЙМЕРЫ/ТРИГГЕРЫ (для демонстрации)
# ============================================

# Нулевой ресурс для триггеров (например, для обновления по расписанию)
resource "null_resource" "update_trigger" {
  triggers = {
    timestamp = timestamp()
  }
}