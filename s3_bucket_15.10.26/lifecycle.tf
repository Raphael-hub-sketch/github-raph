# =====================================================================
# S3 Bucket Lifecycle Configuration
# ---------------------------------------------------------------------
# Автоматическое переключение между классами хранения для экономии.
# ВАЖНО: объекты < 128 KB не переключаются и не тарифицируются
# за мониторинг Intelligent-Tiering [citation:8][citation:19].
# =====================================================================
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count = var.enable_lifecycle ? 1 : 0

  bucket = aws_s3_bucket.main.id

  # Правило для текущих версий
  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    filter {
      prefix = "data/"
    }

    transition {
      days          = var.lifecycle_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.lifecycle_glacier_days
      storage_class = "GLACIER_IR"
    }

    transition {
      days          = var.lifecycle_deep_archive_days
      storage_class = "DEEP_ARCHIVE"
    }

    dynamic "expiration" {
      for_each = var.lifecycle_expiration_days > 0 ? [1] : []
      content {
        days = var.lifecycle_expiration_days
      }
    }
  }

  # Правило для noncurrent версий (если versioning включен)
  dynamic "rule" {
    for_each = var.enable_versioning ? [1] : []
    content {
      id     = "expire-noncurrent-versions"
      status = "Enabled"

      filter {}

      noncurrent_version_transition {
        noncurrent_days = 30
        storage_class   = "STANDARD_IA"
      }

      noncurrent_version_expiration {
        noncurrent_days = 90
      }
    }
  }

  # Правило для незавершённых multipart uploads
  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}