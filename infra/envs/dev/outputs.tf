output "topic_name" {
  description = "Ingestion topic the publishers write to."
  value       = module.event_ingestion.topic_name
}

output "subscription_name" {
  description = "Subscription the processor pulls from."
  value       = module.event_ingestion.subscription_name
}

output "dead_letter_topic_id" {
  description = "Where poison messages end up."
  value       = module.event_ingestion.dead_letter_topic_id
}

output "archive_bucket" {
  description = "Bucket holding raw archived events."
  value       = module.raw_archive.bucket_name
}

output "service_account_emails" {
  description = "Workload identities created for the pipeline."
  value       = module.iam.emails
}

output "analytics_table" {
  description = "BigQuery table receiving processed events."
  value       = module.analytics.table_ref
}
