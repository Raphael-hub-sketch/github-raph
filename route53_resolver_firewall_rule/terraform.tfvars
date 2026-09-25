aws_region              = "us-east-1"
environment             = "prod"
project_name            = "infra-core"
owner                   = "devops-team"
cost_center             = "CC-1042"
vpc_cidr                = "10.0.0.0/16"
create_vpc              = true
rule_name               = "block-malware-domains"
rule_action             = "BLOCK"
rule_priority           = 100
block_response          = "NXDOMAIN"
block_override_domain   = "blocked.example.com"
block_override_dns_type = "CNAME"
block_override_ttl      = 300
blocked_domains = [
  "malware.example.com",
  "phishing.example.org",
  "c2.badactor.net",
  "ransomware.evil.io",
  "trojan-c2.darkweb.xyz",
]
allowed_domains = [
  "trusted.example.com",
  "api.internal.example.com",
  "cdn.example.net",
]
firewall_rule_group_name             = "dns-firewall-rule-group"
firewall_rule_group_association_name = "dns-firewall-vpc-assoc"
create_allow_rule                    = true
create_alert_rule                    = false