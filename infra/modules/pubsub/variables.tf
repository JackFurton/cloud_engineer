variable "project_id" {
  description = "GCP project ID where the Pub/Sub resources live."
  type        = string
}

variable "name" {
  description = "Base name for the topic. The subscription and dead-letter topic are derived from it."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,28}[a-z0-9]$", var.name))
    error_message = "name must be 4-30 chars, lowercase alphanumeric or hyphens, and start with a letter."
  }
}

variable "message_retention_duration" {
  description = "How long the topic retains published messages (e.g. \"86400s\" = 1 day). Max 31 days."
  type        = string
  default     = "86400s"
}

variable "ack_deadline_seconds" {
  description = "Seconds the subscriber has to ack a message before redelivery."
  type        = number
  default     = 30

  validation {
    condition     = var.ack_deadline_seconds >= 10 && var.ack_deadline_seconds <= 600
    error_message = "ack_deadline_seconds must be between 10 and 600."
  }
}

variable "max_delivery_attempts" {
  description = "Deliveries attempted before a message is routed to the dead-letter topic."
  type        = number
  default     = 5

  validation {
    condition     = var.max_delivery_attempts >= 5 && var.max_delivery_attempts <= 100
    error_message = "max_delivery_attempts must be between 5 and 100 (Pub/Sub limit)."
  }
}

variable "labels" {
  description = "Labels applied to every resource in this module."
  type        = map(string)
  default     = {}
}
