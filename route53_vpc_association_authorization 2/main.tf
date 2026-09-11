# ==============================================================================
# main.tf
# Основные ресурсы: VPC, частная зона Route 53 и ресурс авторизации
# ==============================================================================

# Основной VPC (владелец зоны)
resource "aws_vpc" "primary" {
  cidr_block           = var.primary_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-primary-vpc"
    Environment = var.environment
    ManagedBy   = "terraform"
    CostCenter  = "network-team"
  }
}

# Альтернативный VPC (в другом аккаунте/регионе)
resource "aws_vpc" "alternate" {
  provider = aws.alternate

  cidr_block           = var.alternate_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-alternate-vpc"
    Environment = var.environment
    ManagedBy   = "terraform"
    CostCenter  = "network-team"
  }
}

# Частная зона Route 53
resource "aws_route53_zone" "private" {
  name = var.hosted_zone_name

  vpc {
    vpc_id = aws_vpc.primary.id
  }

  tags = {
    Name        = "${var.project_name}-private-zone"
    Environment = var.environment
    ManagedBy   = "terraform"
    CostCenter  = "network-team"
  }

  lifecycle {
    ignore_changes = [vpc]
  }
}

# ==============================================================================
# ЦЕЛЕВОЙ РЕСУРС: aws_route53_vpc_association_authorization
# ==============================================================================
#
# ВАЖНО: Этот ресурс НЕ ГЕНЕРИРУЕТ ЗАТРАТ. AWS не взимает плату за создание
# авторизации. Это лишь разрешение для другого аккаунта привязать свой VPC.
#
# В Infracost этот ресурс будет отображаться с $0.00 в месяц.
# Для «имитации затрат» в файле добавлены комментарии с условными ценами,
# которые могли бы быть, если бы AWS взимал плату (например, $0.50 за операцию).
#
# ------------------------------------------------------------------------------

resource "aws_route53_vpc_association_authorization" "example" {
  vpc_id  = aws_vpc.alternate.id
  zone_id = aws_route53_zone.private.id

  # Имитация затрат (в реальности $0.00):
  # - Стоимость создания авторизации: $0.00
  # - Стоимость хранения авторизации: $0.00
  # - Прогнозируемые ежемесячные затраты (Infracost): $0.00
  # - Условная цена (если бы взималась): $0.50 за 1 авторизацию
}

# Ассоциация VPC с зоной (требует авторизации выше)
resource "aws_route53_zone_association" "example" {
  provider = aws.alternate

  vpc_id  = aws_route53_vpc_association_authorization.example.vpc_id
  zone_id = aws_route53_vpc_association_authorization.example.zone_id
}