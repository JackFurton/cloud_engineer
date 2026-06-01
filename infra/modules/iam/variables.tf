variable "project_id" {
  description = "GCP project that owns the service accounts."
  type        = string
}

variable "service_accounts" {
  description = <<-EOT
    Service accounts to create, keyed by a short logical name. Each SA is a
    workload identity (the thing your app runs as) AND an IAM principal you can
    grant roles to. Keep one SA per workload for clean least-privilege.
  EOT
  type = map(object({
    display_name = string
    description  = string
  }))

  validation {
    condition = alltrue([
      for k in keys(var.service_accounts) :
      can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", k))
    ])
    error_message = "Each service account key must be 6-30 chars, lowercase alphanumeric/hyphens (it becomes the account_id)."
  }
}
