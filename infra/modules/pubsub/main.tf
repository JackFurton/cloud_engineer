# A topic + subscription with a dead-letter path.
#
# AWS analogy: think SNS topic (the topic) fanning into an SQS queue (the
# subscription), with an SQS dead-letter queue (the dead-letter topic) for
# messages that repeatedly fail processing.

resource "google_pubsub_topic" "main" {
  project                    = var.project_id
  name                       = var.name
  message_retention_duration = var.message_retention_duration
  labels                     = var.labels
}

# Messages that exceed max_delivery_attempts land here instead of being lost.
resource "google_pubsub_topic" "dead_letter" {
  project = var.project_id
  name    = "${var.name}-dlq"
  labels  = merge(var.labels, { role = "dead-letter" })
}

resource "google_pubsub_subscription" "main" {
  project = var.project_id
  name    = "${var.name}-sub"
  topic   = google_pubsub_topic.main.id

  ack_deadline_seconds       = var.ack_deadline_seconds
  message_retention_duration = var.message_retention_duration

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = var.max_delivery_attempts
  }

  # Exponential backoff between redeliveries — avoids hammering a failing consumer.
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  labels = var.labels
}
