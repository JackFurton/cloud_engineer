locals {
  # Labels every resource carries — invaluable for cost attribution and
  # security audits ("show me everything tagged env=dev owned by team=platform").
  common_labels = {
    env        = "dev"
    project    = "event-ingestion"
    managed_by = "terraform"
    team       = "platform"
  }
}

# Ingestion pipeline entrypoint: a topic + subscription + dead-letter path.
module "event_ingestion" {
  source = "../../modules/pubsub"

  project_id            = var.project_id
  name                  = var.event_topic_name
  ack_deadline_seconds  = 30
  max_delivery_attempts = 5
  labels                = local.common_labels
}

# Raw-event archive: every event lands here verbatim for replay / forensics.
module "raw_archive" {
  source = "../../modules/storage"

  project_id         = var.project_id
  name               = var.archive_bucket_name
  location           = var.region
  archive_after_days = 30
  force_destroy      = true # dev only — never in prod
  labels             = local.common_labels
}
