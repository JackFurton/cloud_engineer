"""Pull events from the subscription and archive each one to GCS.

This is the "Cloud Run processor" from the architecture diagram, running as a
plain script against the emulators. It pulls in batches until the subscription
is drained, writing one JSON object per event to the archive bucket.

Usage:  python processor.py
"""

import json

import config

from google.cloud import pubsub_v1, storage


def archive_event(bucket, event: dict, message_id: str) -> str:
    """Write one event to GCS, partitioned by site/severity (a common layout
    that makes downstream queries cheap). Returns the object path."""
    object_path = (
        f"events/site={event.get('site', 'unknown')}"
        f"/severity={event.get('severity', 'unknown')}"
        f"/{event.get('event_id', message_id)}.json"
    )
    blob = bucket.blob(object_path)
    blob.upload_from_string(json.dumps(event), content_type="application/json")
    return object_path


def main() -> None:
    subscriber = pubsub_v1.SubscriberClient()
    sub_path = config.subscription_path()

    storage_client = storage.Client(project=config.PROJECT_ID)
    bucket = storage_client.bucket(config.ARCHIVE_BUCKET)

    print(f"Draining {config.SUBSCRIPTION_ID} -> gs://{config.ARCHIVE_BUCKET}/events/ ...")

    total = 0
    empty_polls = 0
    while empty_polls < 2:  # stop after two consecutive empty pulls
        response = subscriber.pull(
            subscription=sub_path,
            max_messages=10,
            timeout=5,
        )
        if not response.received_messages:
            empty_polls += 1
            continue
        empty_polls = 0

        ack_ids = []
        for received in response.received_messages:
            event = json.loads(received.message.data.decode("utf-8"))
            path = archive_event(bucket, event, received.message.message_id)
            ack_ids.append(received.ack_id)
            total += 1
            print(f"  archived {event['severity']:8} -> {path}")

        # Ack only after a successful write — at-least-once delivery means a
        # crash before this line just redelivers the message later.
        subscriber.acknowledge(subscription=sub_path, ack_ids=ack_ids)

    print(f"Processed and archived {total} events.")


if __name__ == "__main__":
    main()
