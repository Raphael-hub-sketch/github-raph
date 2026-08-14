# Переменная для региона AWS
variable "region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

# Базовый домен для проверки
variable "base_domain" {
  description = "The base domain name for health checks (e.g., example.com)"
  type        = string
  default     = "example.com"
}

# Общие теги для всех ресурсов
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment   = "Production"
    ManagedBy     = "Terraform"
    Project       = "Route53-Health-Check"
  }
}