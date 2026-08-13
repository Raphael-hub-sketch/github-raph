# main.tf

# Создание CIDR коллекции, которая будет содержать наши местоположения.
# Это обязательный шаг, так как aws_route53_cidr_location ссылается на коллекцию [citation:1][citation:2].
resource "aws_route53_cidr_collection" "main" {
  name = var.cidr_collection_name
}

# Создание ресурса CIDR местоположения в пределах созданной выше коллекции.
# Ресурс aws_route53_cidr_location используется для управления CIDR блоками,
# ассоциированными с конкретным местоположением (например, офисом или дата-центром).
# Эта функциональность позволяет AWS Route 53 маршрутизировать трафик на основе географического местоположения CIDR блоков [citation:1][citation:3][citation:7].
resource "aws_route53_cidr_location" "this" {
  # Идентификатор родительской CIDR коллекции (обязательный аргумент)
  cidr_collection_id = aws_route53_cidr_collection.main.id

  # Название местоположения (обязательный аргумент)
  name = var.location_name

  # Список CIDR блоков, связанных с этим местоположением (обязательный аргумент).
  # В этом примере используется список из переменной, но вы можете указать свои блоки [citation:1][citation:3].
  cidr_blocks = var.cidr_blocks

  # Вы можете добавить lifecyle правила, например, для предотвращения случайного удаления.
  # lifecycle {
  #   prevent_destroy = true
  # }
}