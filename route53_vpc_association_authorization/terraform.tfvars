aws_region = "us-west-2"
zone_name = "internal.mycompany.com"
owner_vpc_id = "vpc-1234567890abcdef0"
estimated_dns_queries_per_month = 2000000

vpc_associations = {
  "vpc-prod-1" = {
    vpc_id = "vpc-11111111111111111"
    vpc_region = "us-west-2"
  }
  "vpc-prod-2" = {
    vpc_id = "vpc-22222222222222222"
    vpc_region = "us-west-2"
  }
  "vpc-dev-1" = {
    vpc_id = "vpc-33333333333333333"
    vpc_region = "us-east-1"
  }
  "vpc-dev-2" = {
    vpc_id = "vpc-44444444444444444"
    vpc_region = "us-east-1"
  }
  "vpc-test-1" = {
    vpc_id = "vpc-55555555555555555"
    vpc_region = "eu-west-1"
  }
  "vpc-test-2" = {
    vpc_id = "vpc-66666666666666666"
    vpc_region = "eu-west-1"
  }
  "vpc-staging-1" = {
    vpc_id = "vpc-77777777777777777"
    vpc_region = "ap-southeast-1"
  }
  "vpc-staging-2" = {
    vpc_id = "vpc-88888888888888888"
    vpc_region = "ap-southeast-1"
  }
  "vpc-backup-1" = {
    vpc_id = "vpc-99999999999999999"
    vpc_region = "us-west-2"
  }
  "vpc-backup-2" = {
    vpc_id = "vpc-aaaaaaaaaaaaaaaaa"
    vpc_region = "us-east-1"
  }
}