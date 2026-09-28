# main.tf
# Основные ресурсы: S3 bucket и связанные с ним конфигурации

# ============================================================
# RANDOM ID FOR BUCKET NAME
# ============================================================

resource "random_id" "suffix" {
  byte_length = 4
}

# ============================================================
# MAIN S3 BUCKET RESOURCE
# ============================================================
# Ресурс aws_s3_bucket является основным.
# Стоимость этого ресурса: $0.00 (сам ресурс бесплатен).
# ============================================================

resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name

  # force_destroy позволяет удалить бакет даже если в нём есть объекты
  force_destroy = var.environment != "production"

  tags = local.common_tags

  # ============================================================
  # ИМИТАЦИЯ ЗАТРАТ ДЛЯ aws_s3_bucket
  # ============================================================
  # Base Resource Cost: $0.00
  # Monthly Storage (${var.storage_gb} GB): ~$${local.monthly_storage_cost}
  # Monthly Requests: ~$${local.monthly_request_cost}
  # Versioning Overhead: ~$${local.monthly_versioning_cost}
  # Logging: ~$${local.monthly_logging_cost}
  # Lifecycle Transitions: ~$${local.transition_cost}
  # ---------------------------------
  # Estimated Monthly Total: ~$${local.estimated_monthly_cost}
  # ============================================================
}

# ============================================================
# PUBLIC ACCESS BLOCK
# ============================================================
# Блокировка публичного доступа. Ресурс бесплатен.
# ============================================================

resource "aws_s3_bucket_public_access_block" "this" {
  count = var.enable_public_access_block ? 1 : 0

  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================================
# VERSIONING CONFIGURATION
# ============================================================
# Версионирование. Стоимость: зависит от количества версий.
# Имитация: ~$${local.monthly_versioning_cost}/месяц.
# ============================================================

resource "aws_s3_bucket_versioning" "this" {
  count = var.enable_versioning ? 1 : 0

  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }

  # ============================================================
  # COST IMPACT: Versioning
  # ============================================================
  # Non-current versions consume additional storage.
  # Estimated overhead: ${var.versioning_overhead_gb} GB.
  # ============================================================
}

# ============================================================
# SERVER-SIDE ENCRYPTION CONFIGURATION
# ============================================================
# Шифрование. Ресурс бесплатен, но KMS может стоить денег.
# ============================================================

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = var.enable_encryption ? 1 : 0

  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }

  # ============================================================
  # COST IMPACT: Encryption
  # ============================================================
  # SSE-S3 (AES256) is free.
  # SSE-KMS costs $0.03 per 10,000 requests (not simulated).
  # ============================================================
}

# ============================================================
# LIFECYCLE CONFIGURATION
# ============================================================
# Правила жизненного цикла для оптимизации затрат.
# ============================================================

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.enable_lifecycle ? 1 : 0

  bucket = aws_s3_bucket.this.id

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    transition {
      days          = var.lifecycle_glacier_days
      storage_class = "GLACIER"
    }

    # ============================================================
    # COST IMPACT: Lifecycle Transition to Glacier
    # ============================================================
    # Transition cost: $0.01 per 1,000 objects.
    # Savings: Glacier storage ~$0.004/GB vs $0.023/GB.
    # ============================================================
  }

  rule {
    id     = "expire-old-objects"
    status = "Enabled"

    expiration {
      days = var.lifecycle_expiration_days
    }

    # ============================================================
    # COST IMPACT: Expiration
    # ============================================================
    # Expiring old objects reduces storage costs.
    # ============================================================
  }
}

# ============================================================
# ACCESS LOGGING (OPTIONAL)
# ============================================================
# Логирование доступа. Стоимость: зависит от объёма логов.
# ============================================================

resource "aws_s3_bucket_logging" "this" {
  count = var.enable_logging ? 1 : 0

  bucket = aws_s3_bucket.this.id

  target_bucket = aws_s3_bucket.this.id
  target_prefix = "logs/"

  # ============================================================
  # COST IMPACT: Access Logging
  # ============================================================
  # Estimated: ${var.logging_gb} GB of logs.
  # ============================================================
}

# ============================================================
# DATA SOURCES
# ============================================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}