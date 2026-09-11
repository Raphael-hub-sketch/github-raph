# ==============================================================================
# providers.tf
# Настройка двух провайдеров AWS для демонстрации кросс-аккаунтной авторизации
# ==============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Основной провайдер (владелец частной зоны Route 53)
provider "aws" {
  region = var.aws_region

  # Фиктивные учетные данные для валидации синтаксиса (не для реального применения)
  access_key = "AKIAIOSFODNN7EXAMPLE"
  secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

  # Отключаем проверку реальных учетных данных, чтобы файл можно было проверить
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

# Альтернативный провайдер (владелец VPC, который будет ассоциирован)
provider "aws" {
  alias  = "alternate"
  region = var.aws_region

  access_key = "AKIAIOSFODNN7EXAMPLE"
  secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}