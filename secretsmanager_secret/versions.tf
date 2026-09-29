terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Опционально: удалённое хранение state
  # backend "s3" {
  #   bucket = "my-tf-state-bucket"
  #   key    = "secretsmanager-secret/terraform.tfstate"
  #   region = "us-east-1"
  # }
}