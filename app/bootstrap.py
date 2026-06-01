"""Create the topic, subscription, and bucket inside the emulators.

This is the bridge between our two layers. In real GCP, Terraform creates these.
The emulators don't speak Terraform's control-plane API, so we recreate the same
resources (same names!) here. Run this once after `make up`.
"""

import config  # noqa: F401  (import sets the emulator env vars on load)

from google.api_core.exceptions import AlreadyExists
from google.cloud import bigquery, pubsub_v1, storage


def ensure_topic_and_subscription() -> None:
    publisher = pubsub_v1.PublisherClient()
    subscriber = pubsub_v1.SubscriberClient()

    topic_path = config.topic_path()
    sub_path = config.subscription_path()

    try:
        publisher.create_topic(name=topic_path)
        print(f"  created topic        {config.TOPIC_ID}")
    except AlreadyExists:
        print(f"  topic exists         {config.TOPIC_ID}")

    try:
        subscriber.create_subscription(
            name=sub_path,
            topic=topic_path,
            ack_deadline_seconds=30,
        )
        print(f"  created subscription {config.SUBSCRIPTION_ID}")
    except AlreadyExists:
        print(f"  subscription exists  {config.SUBSCRIPTION_ID}")


def ensure_bucket() -> None:
    client = storage.Client(project=config.PROJECT_ID)
    try:
        client.create_bucket(config.ARCHIVE_BUCKET)
        print(f"  created bucket       {config.ARCHIVE_BUCKET}")
    except Exception as exc:  # fake-gcs-server raises Conflict on re-create
        if "exist" in str(exc).lower() or "conflict" in str(exc).lower():
            print(f"  bucket exists        {config.ARCHIVE_BUCKET}")
        else:
            raise


# Mirrors the schema in infra/modules/bigquery (via the dev env). The emulator
# table is simpler (no partitioning/clustering) — that's the documented
# control-plane/data-plane divergence, same as everywhere else in this project.
BQ_SCHEMA = [
    bigquery.SchemaField("event_id", "STRING", mode="REQUIRED"),
    bigquery.SchemaField("sensor_type", "STRING"),
    bigquery.SchemaField("site", "STRING"),
    bigquery.SchemaField("severity", "STRING"),
    bigquery.SchemaField("reading", "FLOAT"),
    bigquery.SchemaField("event_ts", "TIMESTAMP"),
    bigquery.SchemaField("ingest_ts", "TIMESTAMP"),
]


def ensure_bigquery() -> None:
    # Get-then-create (not try-create-catch): the goccy emulator doesn't return a
    # clean 409 on duplicate creates, so we check existence first to stay idempotent.
    from google.api_core.exceptions import NotFound

    client = config.bq_client()
    dataset_fqn = f"{config.PROJECT_ID}.{config.BQ_DATASET}"

    try:
        client.get_dataset(dataset_fqn)
        print(f"  dataset exists       {config.BQ_DATASET}")
    except NotFound:
        client.create_dataset(bigquery.Dataset(dataset_fqn))
        print(f"  created dataset      {config.BQ_DATASET}")

    try:
        client.get_table(config.bq_table_ref())
        print(f"  table exists         {config.BQ_DATASET}.{config.BQ_TABLE}")
    except NotFound:
        client.create_table(bigquery.Table(config.bq_table_ref(), schema=BQ_SCHEMA))
        print(f"  created table        {config.BQ_DATASET}.{config.BQ_TABLE}")


if __name__ == "__main__":
    print("Bootstrapping emulator resources:")
    ensure_topic_and_subscription()
    ensure_bucket()
    ensure_bigquery()
    print("Done.")
