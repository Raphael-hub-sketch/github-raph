# --- Основной ресурс Route53 Health Check ---
# Ежемесячная стоимость: $0.50 (Базовая проверка HTTP) [citation:7]
resource "aws_route53_health_check" "primary_http" {
  fqdn              = "www.${var.base_domain}"
  port              = 80
  type              = "HTTP"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  # Измерение задержки увеличивает детализацию, но не влияет на стоимость
  measure_latency   = true

  tags = merge(var.common_tags, {
    Name = "primary-http-check"
  })
}

# --- Расширенная проверка с проверкой строки ---
# Ежемесячная стоимость: $1.00 (Расширенная проверка HTTPS_STR_MATCH) [citation:7]
resource "aws_route53_health_check" "secondary_https_string_match" {
  fqdn              = "api.${var.base_domain}"
  port              = 443
  type              = "HTTPS_STR_MATCH"
  resource_path     = "/status"
  failure_threshold = 2
  request_interval  = 10
  search_string     = "healthy"  # Ищет слово "healthy" в ответе

  # Включаем SNI для HTTPS проверок
  enable_sni        = true

  tags = merge(var.common_tags, {
    Name = "secondary-https-string-check"
  })
}

# --- Суммарная (агрегированная) проверка ---
# Эта проверка суммирует статус дочерних проверок.
# Ежемесячная стоимость: $0.50 (Базовая проверка CALCULATED) [citation:7]
resource "aws_route53_health_check" "aggregated_health_check" {
  type                   = "CALCULATED"
  child_health_threshold = 1 # Считается здоровой, если здорова хотя бы одна дочерняя
  child_healthchecks = [
    aws_route53_health_check.primary_http.id,
    aws_route53_health_check.secondary_https_string_match.id
  ]

  tags = merge(var.common_tags, {
    Name = "aggregated-health-check"
  })

  # Зависимость от дочерних проверок для корректного создания
  depends_on = [
    aws_route53_health_check.primary_http,
    aws_route53_health_check.secondary_https_string_match
  ]
}

# --- CloudWatch Alarm (Мониторинг) ---
# Этот ресурс сам по себе не является проверкой здоровья, но используется
# для создания алертов на основе метрик проверки.
# Ежемесячная стоимость: ~$0.10 за каждый стандартный аларм.
resource "aws_cloudwatch_metric_alarm" "health_check_failed" {
  alarm_name          = "route53-health-check-failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "This alarm triggers when the Route53 health check fails"

  # Используем ID агрегированной проверки как измерение
  dimensions = {
    HealthCheckId = aws_route53_health_check.primary_http.id
  }

  tags = var.common_tags
}

# --- SNS Topic (Уведомления) ---
# Создает тему для отправки уведомлений об алертах.
# Ежемесячная стоимость: Зависит от количества отправленных сообщений (~$0.00-$0.01) [citation:7]
resource "aws_sns_topic" "health_check_alerts" {
  name = "health-check-alerts"

  tags = var.common_tags
}

# Подписка на SNS Topic по Email
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.health_check_alerts.arn
  protocol  = "email"
  endpoint  = "admin@${var.base_domain}" # Замените на ваш email
}

# Связываем CloudWatch Alarm с SNS Topic
resource "aws_cloudwatch_metric_alarm" "health_check_failed_with_sns" {
  alarm_name          = "route53-health-check-alarm-sns"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "Triggers when health check fails and sends SNS notification"

  dimensions = {
    HealthCheckId = aws_route53_health_check.secondary_https_string_match.id
  }

  # Связываем с SNS-темой
  alarm_actions = [aws_sns_topic.health_check_alerts.arn]

  tags = var.common_tags
}