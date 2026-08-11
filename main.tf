provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
}

# Both an ALIAS record (contributes alias.zone_id -> ALB) and a standalone zone_association
# (needs zone_id mock -> zone). infra reuses one mock per attr name, so both zone_id values
# collide; without the top-level-priority guard in ReferenceResolver the zone alias is dropped
# as ambiguous and the zone->VPC-b edge is lost. Expect 2 zone->VPC edges + 1 alias edge.
resource "aws_vpc" "a" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_vpc" "b" {
  cidr_block = "10.1.0.0/16"
}

resource "aws_subnet" "a1" {
  vpc_id            = aws_vpc.a.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "a2" {
  vpc_id            = aws_vpc.a.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_lb" "app" {
  name               = "app-lb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.a1.id, aws_subnet.a2.id]
}

resource "aws_route53_zone" "z" {
  name = "internal.example.com"

  vpc {
    vpc_id = aws_vpc.a.id
  }
}

resource "aws_route53_zone_association" "b" {
  zone_id = aws_route53_zone.z.zone_id
  vpc_id  = aws_vpc.b.id
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.z.zone_id
  name    = "www.internal.example.com"
  type    = "A"

  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}
