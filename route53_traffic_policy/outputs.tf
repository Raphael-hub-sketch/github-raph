output "policy_id" {
  description = "ID созданной политики трафика"
  value       = aws_route53_traffic_policy.example.id
}

output "policy_version" {
  description = "Версия политики трафика"
  value       = aws_route53_traffic_policy.example.version
}

output "policy_arn" {
  description = "ARN созданной политики трафика"
  value       = aws_route53_traffic_policy.example.arn
}

output "policy_instance_id" {
  description = "ID экземпляра политики трафика"
  value       = aws_route53_traffic_policy_instance.example.id
}

# Информация о затратах (дублируется из main.tf для наглядности)
output "monthly_cost_breakdown" {
  description = "Детализация ориентировочных затрат"
  value       = local.cost_breakdown
}