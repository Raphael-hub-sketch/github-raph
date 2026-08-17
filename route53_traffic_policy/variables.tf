# ... существующие переменные ...

variable "estimated_queries_per_month" {
  description = "Ориентировочное количество DNS-запросов в месяц для расчета затрат"
  type        = number
  default     = 100000
}

variable "health_checks_count" {
  description = "Количество проверок работоспособности, используемых в политике"
  type        = number
  default     = 2
}