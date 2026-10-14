aws_region            = "us-east-1"
environment           = "prod"
project_name          = "infra-core"
owner                 = "devops-team"
cost_center           = "CC-1042"
vpc_cidr              = "10.0.0.0/16"
firewall_fail_open    = "DISABLED"
create_vpc            = true
blocked_domains = [
  "malware.example.com",
  "phishing.example.org",
  "c2.badactor.net",
  "ransomware.evil.io",
  "trojan-c2.darkweb.xyz",
]
firewall_rule_group_name             = "dns-firewall-blocklist"
firewall_rule_group_association_name = "dns-firewall-vpc-assoc"