output "primary_http_check_id" {
  description = "The ID of the primary HTTP health check"
  value       = aws_route53_health_check.primary_http.id
}

output "secondary_https_string_match_id" {
  description = "The ID of the secondary HTTPS string match health check"
  value       = aws_route53_health_check.secondary_https_string_match.id
}

output "aggregated_health_check_id" {
  description = "The ID of the aggregated (calculated) health check"
  value       = aws_route53_health_check.aggregated_health_check.id
}

output "sns_topic_arn" {
  description = "The ARN of the SNS topic for health check alerts"
  value       = aws_sns_topic.health_check_alerts.arn
}