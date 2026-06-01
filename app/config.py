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

# Matches infra/envs/dev: module.analytics (dataset "telemetry", table "events").
BQ_DATASET = os.environ.get("BQ_DATASET", "telemetry")
BQ_TABLE = os.environ.get("BQ_TABLE", "events")

# Point the client libraries at the emulators (setdefault = respect overrides).
os.environ.setdefault("PUBSUB_EMULATOR_HOST", "localhost:8085")
os.environ.setdefault("STORAGE_EMULATOR_HOST", "http://localhost:4443")
# BigQuery has no standard *_EMULATOR_HOST env var, so we read this ourselves
# and pass it to the client via client_options below.
os.environ.setdefault("BIGQUERY_EMULATOR_HOST", "http://localhost:9050")
os.environ.setdefault("GOOGLE_CLOUD_PROJECT", PROJECT_ID)

PUBSUB_EMULATOR_HOST = os.environ["PUBSUB_EMULATOR_HOST"]
STORAGE_EMULATOR_HOST = os.environ["STORAGE_EMULATOR_HOST"]
BIGQUERY_EMULATOR_HOST = os.environ["BIGQUERY_EMULATOR_HOST"]


def bq_client():
    """BigQuery client wired to the emulator. Unlike Pub/Sub and Storage, the BQ
    client doesn't auto-detect an emulator env var, so we set api_endpoint and
    anonymous credentials explicitly. In real GCP you'd construct
    bigquery.Client(project=...) with no overrides."""
    from google.api_core.client_options import ClientOptions
    from google.auth.credentials import AnonymousCredentials
    from google.cloud import bigquery

    return bigquery.Client(
        project=PROJECT_ID,
        credentials=AnonymousCredentials(),
        client_options=ClientOptions(api_endpoint=BIGQUERY_EMULATOR_HOST),
    )


def bq_table_ref() -> str:
    return f"{PROJECT_ID}.{BQ_DATASET}.{BQ_TABLE}"


def topic_path() -> str:
    return f"projects/{PROJECT_ID}/topics/{TOPIC_ID}"


def subscription_path() -> str:
    return f"projects/{PROJECT_ID}/subscriptions/{SUBSCRIPTION_ID}"
