# providers.tf
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Дополнительные настройки для production
  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = "route53-cidr"
    }
  }
}

# Для случаев, когда нужен другой регион (например, резервный)
provider "aws" {
  alias  = "backup"
  region = var.backup_region
}