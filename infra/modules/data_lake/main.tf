# ============================================================
# Data lake bucket
# Single bucket with prefix-based zones (raw/, staging/, curated/)
# ============================================================

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  # Force destroy is FALSE: even Terraform should not delete a bucket
  # that still has objects. Override only via console for true emergencies.
  force_destroy = false

  tags = {
    Name = var.bucket_name
  }
}

# ============================================================
# Ownership controls
# Bucket-owner-enforced disables ACLs entirely. Modern AWS guidance:
# always use bucket policies + IAM, never ACLs.
# ============================================================

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# ============================================================
# Public access block — all four ON
# ============================================================

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================================
# Versioning — required for data lake durability and recovery
# ============================================================

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ============================================================
# Encryption at rest — SSE-S3 (AES256) with bucket key for cost
# ============================================================

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# ============================================================
# Lifecycle rules
#
# Rule 1 (universal): clean up incomplete multipart uploads.
#   Without this, failed uploads leave orphan parts that bill forever.
#
# Rule 2 (universal): delete noncurrent (versioned) object versions
#   after 90 days. Without this, versioning makes storage grow forever.
#
# Rule 3 (raw/ only): transition to IA after 90 days, Glacier after 180.
#   We keep raw forever for auditability but rarely re-read it.
#   staging/ and curated/ are recomputable; not worth Glaciering.
# ============================================================

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  # Lifecycle config requires versioning to be applied first.
  depends_on = [aws_s3_bucket_versioning.this]

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    # Empty filter targets all objects in the bucket
    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  rule {
    id     = "raw-archive-transitions"
    status = "Enabled"

    filter {
      prefix = "raw/"
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }
  }
}

