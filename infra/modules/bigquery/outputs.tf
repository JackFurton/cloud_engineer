output "dataset_id" {
  description = "The dataset ID."
  value       = google_bigquery_dataset.this.dataset_id
}

output "table_id" {
  description = "The events table ID."
  value       = google_bigquery_table.events.table_id
}

output "table_ref" {
  description = "Fully-qualified table reference: project.dataset.table"
  value       = "${var.project_id}.${google_bigquery_dataset.this.dataset_id}.${google_bigquery_table.events.table_id}"
}
