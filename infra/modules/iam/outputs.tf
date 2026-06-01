output "emails" {
  description = "Map of logical name -> service account email (use to build IAM members)."
  value       = { for k, sa in google_service_account.this : k => sa.email }
}

output "members" {
  description = "Map of logical name -> IAM member string (serviceAccount:<email>), ready to drop into bindings."
  value       = { for k, sa in google_service_account.this : k => "serviceAccount:${sa.email}" }
}

output "ids" {
  description = "Map of logical name -> fully-qualified service account ID."
  value       = { for k, sa in google_service_account.this : k => sa.id }
}
