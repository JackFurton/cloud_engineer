# Workload identities for the pipeline.
#
# AWS analogy: each of these is like an IAM role that a workload assumes — but
# in GCP a service account is also a full principal with its own email address,
# e.g. processor@<project>.iam.gserviceaccount.com.
#
# This module ONLY creates the identities. The actual permission grants live in
# the environment, bound to specific resources (the topic, the bucket) so we
# never hand out project-wide access. That separation is deliberate.

resource "google_service_account" "this" {
  for_each = var.service_accounts

  project      = var.project_id
  account_id   = each.key
  display_name = each.value.display_name
  description  = each.value.description
}
