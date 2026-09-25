output "firewall_config_id" {
  description = "ID конфигурации firewall"
  value       = var.create_vpc ? aws_route53_resolver_firewall_config.main[0].id : null
}

output "firewall_config_resource_id" {
  description = "ID VPC, к которому применена конфигурация"
  value       = var.create_vpc ? aws_route53_resolver_firewall_config.main[0].resource_id : null
}

output "firewall_config_fail_open" {
  description = "Режим fail-open"
  value       = var.create_vpc ? aws_route53_resolver_firewall_config.main[0].firewall_fail_open : null
}

output "vpc_id" {
  description = "ID созданного VPC"
  value       = var.create_vpc ? aws_vpc.main[0].id : null
}

output "domain_list_id" {
  description = "ID списка заблокированных доменов"
  value       = aws_route53_resolver_firewall_domain_list.blocked.id
}

output "domain_list_arn" {
  description = "ARN списка заблокированных доменов"
  value       = aws_route53_resolver_firewall_domain_list.blocked.arn
}

output "rule_group_id" {
  description = "ID группы правил DNS Firewall"
  value       = aws_route53_resolver_firewall_rule_group.main.id
}

output "rule_group_arn" {
  description = "ARN группы правил DNS Firewall"
  value       = aws_route53_resolver_firewall_rule_group.main.arn
}

output "rule_group_association_id" {
  description = "ID ассоциации группы правил с VPC"
  value       = var.create_vpc ? aws_route53_resolver_firewall_rule_group_association.main[0].id : null
}

# ---------------------------------------------------------------------
# ИМИТАЦИЯ ЗАТРАТ: выходные данные для FinOps
# ---------------------------------------------------------------------
output "cost_report" {
  description = "Детализированный отчёт