variable "aws_region" {
  description = "AWS регион для развёртывания"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Окружение (dev/stage/prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Допустимые значения: dev, stage, prod."
  }
}

variable "project_name" {
  description = "Имя проекта"
  type        = string
  default     = "infra-core"
}

variable "owner" {
  description = "Ответственный за ресурс"
  type        = string
  default     = "devops-team"
}

variable "cost_center" {
  description = "Cost center для биллинга"
  type        = string
  default     = "CC-1042"
}

variable "vpc_cidr" {
  description = "CIDR блок для VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "firewall_fail_open" {
  description = "Поведение DNS Firewall при сбоях (ENABLED = разрешать запросы, DISABLED = блокировать)"
  type        = string
  default     = "DISABLED"

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.firewall_fail_open)
    error_message = "Допустимые значения: ENABLED, DISABLED."
  }
}

variable "create_vpc" {
  description = "Создавать ли VPC для демонстрации"
  type        = bool
  default     = true
}

variable "blocked_domains" {
  description = "Список доменов для блокировки"
  type        = list(string)
  default = [
    "malware.example.com",
    "phishing.example.org",
    "c2.badactor.net",
    "ransomware.evil.io",
    "trojan-c2.darkweb.xyz",
  ]
}

variable "firewall_rule_group_name" {
  description = "Имя группы правил DNS Firewall"
  type        = string
  default     = "dns-firewall-blocklist"
}

variable "firewall_rule_group_association_name" {
  description = "Имя ассоциации группы правил с VPC"
  type        = string
  default     = "dns-firewall-vpc-assoc"
}