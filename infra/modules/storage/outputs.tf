output "bucket_name" {
  description = "Name of the bucket."
  value       = google_storage_bucket.main.name
}

output "bucket_url" {
  description = "gs:// URL of the bucket."
  value       = google_storage_bucket.main.url
}

output "self_link" {
  description = "URI of the bucket resource."
  value       = google_storage_bucket.main.self_link
}
