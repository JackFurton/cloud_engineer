variable "project_id" {
  description = "GCP project ID for the dev environment."
  type        = string
}

variable "region" {
  description = "Default region for regional resources."
  type        = string
  default     = "us-east1"
}

variable "event_topic_name" {
  description = "Name of the ingestion topic."
  type        = string
  default     = "telemetry-events"
}

variable "archive_bucket_name" {
  description = "Globally-unique name for the raw-event archive bucket."
  type        = string
}
