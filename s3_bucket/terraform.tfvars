# terraform.tfvars
# ВАЖНО: не коммитьте этот файл в Git с реальными данными!

aws_region   = "us-east-1"
environment  = "dev"
project_name = "s3-cost-demo"

bucket_name = null

enable_versioning          = true
enable_lifecycle           = true
enable_encryption          = true
enable_logging             = false
enable_public_access_block = true

lifecycle_glacier_days    = 90
lifecycle_expiration_days = 365

storage_gb             = 100
monthly_requests       = 1000000
versioning_overhead_gb = 20
logging_gb             = 5
transition_objects     = 10000