output "topic_id" {
  description = "Fully-qualified ID of the main topic."
  value       = google_pubsub_topic.main.id
}

output "topic_name" {
  description = "Short name of the main topic."
  value       = google_pubsub_topic.main.name
}

output "subscription_name" {
  description = "Short name of the subscription consumers pull from."
  value       = google_pubsub_subscription.main.name
}

output "dead_letter_topic_id" {
  description = "Fully-qualified ID of the dead-letter topic."
  value       = google_pubsub_topic.dead_letter.id
}
