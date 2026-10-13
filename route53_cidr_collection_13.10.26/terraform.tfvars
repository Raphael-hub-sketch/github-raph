aws_region      = "us-east-1"
environment     = "prod"
project_name    = "infra-core"
owner           = "devops-team"
cost_center     = "CC-1042"
collection_name = "ip-routing-collection"

locations = [
  {
    name        = "office-moscow"
    cidr_blocks = ["203.0.113.0/24", "198.51.100.0/24"]
  },
  {
    name        = "office-spb"
    cidr_blocks = ["192.0.2.0/24"]
  },
  {
    name        = "vpn-users"
    cidr_blocks = ["10.100.0.0/24", "10.100.1.0/24"]
  }
]