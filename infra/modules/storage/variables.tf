variable "project_id" {
  description = "GCP project ID that owns the bucket."
  type        = string
}

variable "name" {
  description = "Globally-unique bucket name (GCS buckets share one global namespace, like S3)."
  type        = string
}

variable "location" {
  description = "Bucket location — a region (US-EAST1) or multi-region (US)."
  type        = string
  default     = "US"
}

variable "storage_class" {
  description = "Default storage class for new objects."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "storage_class must be one of STANDARD, NEARLINE, COLDLINE, ARCHIVE."
  }
}

variable "force_destroy" {
  description = "If true, `terraform destroy` deletes the bucket even when it still holds objects."
  type        = bool
  default     = false
}

variable "archive_after_days" {
  description = "Age in days after which objects transition to ARCHIVE class. 0 disables the rule."
  type        = number
  default     = 30
}

variable "labels" {
  description = "Labels applied to the bucket."
  type        = map(string)
  default     = {}
}
