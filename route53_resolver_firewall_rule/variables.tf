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

variable "create_vpc" {
  description = "Создавать ли VPC для демонстрации"
  type        = bool
  default     = true
}

variable "rule_name" {
  description = "Имя firewall rule"
  type        = string
  default     = "block-malware-domains"
}

variable "rule_action" {
  description = "Действие правила (ALLOW, BLOCK, ALERT)"
  type        = string
  default     = "BLOCK"

  validation {
    condition     = contains(["ALLOW", "BLOCK", "ALERT"], var.rule_action)
    error_message = "Допустимые значения: ALLOW, BLOCK, ALERT."
  }
}

variable "rule_priority" {
  description = "Приоритет правила (уникальный в группе)"
  type        = number
  default     = 100

  validation {
    condition     = var.rule_priority >= 100 && var.rule_priority <= 9900
    error_message = "Приоритет должен быть от 100 до 9900."
  }
}

variable "block_response" {
  description = "Ответ при блокировке (NODATA, NXDOMAIN, OVERRIDE)"
  type        = string
  default     = "NXDOMAIN"

  validation {
    condition     = contains(["NODATA", "NXDOMAIN", "OVERRIDE"], var.block_response)
    error_message = "Допустимые значения: NODATA, NXDOMAIN, OVERRIDE."
  }
}

variable "block_override_domain" {
  description = "Домен для override-ответа (только при block_response = OVERRIDE)"
  type        = string
  default     = "blocked.example.com"
}

variable "block_override_dns_type" {
  description = "Тип DNS-записи для override (CNAME)"
  type        = string
  default     = "CNAME"
}

variable "block_override_ttl" {
  description = "TTL для override-записи (секунды)"
  type        = number
  default     = 300
}

variable "blocked_domains" {
  description = "Список доменов для блокировки"
  type        = list(string)
  default     = [
    "malware.example.com",
    "phishing.example.org",
    "c2.badactor.net",
    "ransomware.evil.io",
    "trojan-c2.darkweb.xyz",
  ]
}

variable "allowed_domains" {
  description = "Список доменов для явного разрешения"
  type        = list(string)
  default     = [
    "trusted.example.com",
    "api.internal.example.com",
    "cdn.example.net",
  ]
}

variable "firewall_rule_group_name" {
  description = "Имя группы правил DNS Firewall"
  type        = string
  default     = "dns-firewall-rule-group"
}

variable "firewall_rule_group_association_name" {
  description = "Имя ассоциации группы правил с VPC"
  type        = string
  default     = "dns-firewall-vpc-assoc"
}

variable "create_allow_rule" {
  description = "Создавать ли дополнительное ALLOW-правило"
  type        = bool
  default     = true
}

variable "create_alert_rule" {
  description = "Создавать ли дополнительное ALERT-правило"
  type        = bool
  default     = false
}