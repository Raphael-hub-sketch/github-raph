terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Настройка провайдера AWS
# Переменная region определена в variables.tf
provider "aws" {
  region = var.region
}