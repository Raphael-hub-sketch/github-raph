aws_region = "us-west-2"
zone_name = "mycompany.com"
estimated_dns_queries_per_month = 2000000

records = {
  "www-a" = {
    name    = "www"
    type    = "A"
    ttl     = 300
    records = ["192.0.2.1", "192.0.2.2"]
  }
  "mail-cname" = {
    name    = "mail"
    type    = "CNAME"
    ttl     = 3600
    records = ["mail.mycompany.com"]
  }
  "mx-record" = {
    name    = ""
    type    = "MX"
    ttl     = 3600
    records = ["10 mail.mycompany.com", "20 mail2.mycompany.com"]
  }
  "txt-verification" = {
    name    = "verify"
    type    = "TXT"
    ttl     = 300
    records = ["v=spf1 include:_spf.mycompany.com ~all"]
  }
  "dev-weighted" = {
    name    = "api"
    type    = "A"
    ttl     = 60
    records = ["10.0.1.10"]
    set_identifier = "dev"
    weighted_routing_policy = {
      weight = 10
    }
  }
  "prod-weighted" = {
    name    = "api"
    type    = "A"
    ttl     = 60
    records = ["10.0.1.20"]
    set_identifier = "prod"
    weighted_routing_policy = {
      weight = 90
    }
  }
  "api-gateway-alias" = {
    name    = "apigateway"
    type    = "A"
    alias = {
      name    = "d-10qxlbvagl.execute-api.us-west-2.amazonaws.com"
      zone_id = "Z2FDTNDATAQYW2"
      evaluate_target_health = false
    }
  }
  "s3-website-alias" = {
    name    = "site"
    type    = "A"
    alias = {
      name    = "s3-website-us-west-2.amazonaws.com"
      zone_id = "Z3BJ6K6RIION7M"
      evaluate_target_health = false
    }
  }
  "ns-subdomain" = {
    name    = "subdomain"
    type    = "NS"
    ttl     = 172800
    records = ["ns-123.awsdns-01.com.", "ns-456.awsdns-02.net."]
  }
}