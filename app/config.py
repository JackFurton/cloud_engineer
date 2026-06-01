"""Single source of truth for resource names + emulator endpoints.

These names MUST match what Terraform defines in infra/envs/dev so the two
layers stay consistent. Setting the *_EMULATOR_HOST env vars is what makes the
Google client libraries talk to our local containers instead of real GCP.
"""

import os

PROJECT_ID = os.environ.get("PROJECT_ID", "darkwolf-practice-dev")

# Matches infra/envs/dev: module.event_ingestion (name = "telemetry-events").
TOPIC_ID = os.environ.get("TOPIC_ID", "telemetry-events")
SUBSCRIPTION_ID = os.environ.get("SUBSCRIPTION_ID", "telemetry-events-sub")

# Matches infra/envs/dev: var.archive_bucket_name.
ARCHIVE_BUCKET = os.environ.get("ARCHIVE_BUCKET", "darkwolf-practice-dev-raw-archive")

# Point the client libraries at the emulators (setdefault = respect overrides).
os.environ.setdefault("PUBSUB_EMULATOR_HOST", "localhost:8085")
os.environ.setdefault("STORAGE_EMULATOR_HOST", "http://localhost:4443")
os.environ.setdefault("GOOGLE_CLOUD_PROJECT", PROJECT_ID)

PUBSUB_EMULATOR_HOST = os.environ["PUBSUB_EMULATOR_HOST"]
STORAGE_EMULATOR_HOST = os.environ["STORAGE_EMULATOR_HOST"]


def topic_path() -> str:
    return f"projects/{PROJECT_ID}/topics/{TOPIC_ID}"


def subscription_path() -> str:
    return f"projects/{PROJECT_ID}/subscriptions/{SUBSCRIPTION_ID}"
