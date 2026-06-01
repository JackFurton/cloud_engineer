variable "project_id" {
  description = "GCP project that owns the dataset."
  type        = string
}

variable "dataset_id" {
  description = "Dataset ID (like a schema/database namespace). Underscores allowed, no hyphens."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z_][a-zA-Z0-9_]*$", var.dataset_id)) && length(var.dataset_id) <= 1024
    error_message = "dataset_id must be <=1024 chars of letters, numbers, or underscores (no hyphens)."
  }
}

variable "location" {
  description = "Dataset location — region (us-east1) or multi-region (US). Immutable after creation."
  type        = string
  default     = "US"
}

variable "table_id" {
  description = "Table ID for the events table."
  type        = string
}

variable "schema" {
  description = "Table schema as a JSON string (use jsonencode([...]) in the caller)."
  type        = string
}

variable "partition_field" {
  description = "TIMESTAMP/DATE column to partition by (DAY granularity). Empty = no partitioning."
  type        = string
  default     = ""
}

variable "clustering_fields" {
  description = "Up to 4 columns to cluster by within each partition (cheap filtering)."
  type        = list(string)
  default     = []
}

variable "delete_contents_on_destroy" {
  description = "If true, `terraform destroy` drops the dataset even when it holds tables. Dev only."
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels applied to the dataset and table."
  type        = map(string)
  default     = {}
}
