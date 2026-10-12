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

variable "sg_name" {
  description = "Имя Security Group"
  type        = string
  default     = "app-security-group"
}

variable "sg_description" {
  description = "Описание Security Group"
  type        = string
  default     = "Security group for application tier"
}

variable "allowed_ssh_cidrs" {
  description = "CIDR блоки для SSH доступа (ограничьте 0.0.0.0/0 в production)"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "allowed_http_cidrs" {
  description = "CIDR блоки для HTTP/HTTPS доступа"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_port" {
  description = "Порт приложения"
  type        = number
  default     = 8080
}

variable "create_alb_sg" {
  description = "Создавать ли Security Group для ALB"
  type        = bool
  default     = true
}

variable "create_db_sg" {
  description = "Создавать ли Security Group для базы данных"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Включить ли VPC Flow Logs (тарифицируется отдельно)"
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "Срок хранения Flow Logs"
  type        = number
  default     = 14
}