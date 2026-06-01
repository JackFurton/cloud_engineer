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

# ---------------------------------------------------------------------------
# Identities + least-privilege grants
# ---------------------------------------------------------------------------

# One service account per workload.
module "iam" {
  source = "../../modules/iam"

  project_id = var.project_id
  service_accounts = {
    telemetry-publisher = {
      display_name = "Telemetry Publisher"
      description  = "Publishes sensor events to the ingestion topic."
    }
    telemetry-processor = {
      display_name = "Telemetry Processor"
      description  = "Pulls events from the subscription and archives them to GCS."
    }
  }
}

# Publisher may publish to THIS topic only — not project-wide pubsub access.
resource "google_pubsub_topic_iam_member" "publisher" {
  project = var.project_id
  topic   = module.event_ingestion.topic_name
  role    = "roles/pubsub.publisher"
  member  = module.iam.members["telemetry-publisher"]
}

# Processor may pull from THIS subscription only.
resource "google_pubsub_subscription_iam_member" "processor_sub" {
  project      = var.project_id
  subscription = module.event_ingestion.subscription_name
  role         = "roles/pubsub.subscriber"
  member       = module.iam.members["telemetry-processor"]
}

# Processor may CREATE objects in the archive bucket, but not delete or admin it.
# objectCreator (not objectAdmin) is the least-privilege write role.
resource "google_storage_bucket_iam_member" "processor_writer" {
  bucket = module.raw_archive.bucket_name
  role   = "roles/storage.objectCreator"
  member = module.iam.members["telemetry-processor"]
}
