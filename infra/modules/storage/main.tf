# A hardened GCS bucket for raw event archival.
#
# AWS analogy: an S3 bucket with Block Public Access on, default encryption,
# versioning, and a lifecycle rule to tier cold data — but expressed the GCP way.

resource "google_storage_bucket" "main" {
  project       = var.project_id
  name          = var.name
  location      = var.location
  storage_class = var.storage_class
  force_destroy = var.force_destroy
  labels        = var.labels

  # Enforce IAM-only access (no per-object ACLs). The secure default you almost
  # always want — analogous to disabling S3 ACLs in favor of bucket policies.
  uniform_bucket_level_access = true

  # Block all public access at the bucket level.
  public_access_prevention = "enforced"

  versioning {
    enabled = true
  }

  # Tier aging objects to cheaper storage. Disabled when archive_after_days = 0.
  dynamic "lifecycle_rule" {
    for_each = var.archive_after_days > 0 ? [1] : []
    content {
      condition {
        age = var.archive_after_days
      }
      action {
        type          = "SetStorageClass"
        storage_class = "ARCHIVE"
      }
    }
  }
}
