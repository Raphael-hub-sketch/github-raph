aws_region                    = "us-east-1"
environment                   = "prod"
project_name                  = "infra-core"
owner                         = "devops-team"
cost_center                   = "CC-1042"
vpc_id                        = "vpc-0123456789abcdef0"
security_group_id             = "sg-0123456789abcdef0"
enable_flow_logs_simulation   = true
flow_logs_data_gb_per_month   = 50

ingress_rules = [
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  },
  {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from internet"
  },
  {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "SSH from VPC"
  }
]

egress_rules = [
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }
]