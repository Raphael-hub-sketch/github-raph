# =====================================================================
# S3 Bucket Lifecycle Configuration
# =====================================================================
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count = var.enable_lifecycle ? 1 : 0

  bucket = aws_s3_bucket.main.id

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

  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}