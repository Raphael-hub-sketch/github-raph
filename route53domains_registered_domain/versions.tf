terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Опционально: удалённое хранение state
  # backend "s3" {
  #   bucket = "my-tf-state-bucket"
  #   key    = "route53-domain/terraform.tfstate"
  #   region = "us-east-1"
  # }
}