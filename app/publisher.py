"""Publish synthetic telemetry events to the ingestion topic.

Usage:  python publisher.py [count]   (default 10)
"""

import json
import random
import sys
import time
import uuid

import config

from google.cloud import pubsub_v1

SENSOR_TYPES = ["thermal", "acoustic", "rf", "seismic", "optical"]
SITES = ["alpha", "bravo", "charlie", "delta"]
SEVERITIES = ["info", "warning", "critical"]


def make_event() -> dict:
    return {
        "event_id": str(uuid.uuid4()),
        "sensor_type": random.choice(SENSOR_TYPES),
        "site": random.choice(SITES),
        "severity": random.choices(SEVERITIES, weights=[70, 25, 5])[0],
        "reading": round(random.uniform(0, 100), 2),
        "ts": time.time(),
    }


def main(count: int) -> None:
    publisher = pubsub_v1.PublisherClient()
    topic_path = config.topic_path()

    print(f"Publishing {count} events to {config.TOPIC_ID} ...")
    futures = []
    for _ in range(count):
        event = make_event()
        data = json.dumps(event).encode("utf-8")
        # Attributes are message metadata — handy for filtering/routing without
        # decoding the body. Like SNS message attributes.
        future = publisher.publish(
            topic_path,
            data,
            sensor_type=event["sensor_type"],
            severity=event["severity"],
        )
        futures.append((event, future))

    for event, future in futures:
        msg_id = future.result()  # blocks until the publish is acked
        print(f"  -> {event['severity']:8} {event['sensor_type']:8} site={event['site']:8} id={msg_id}")

    print(f"Published {count} events.")


if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 10
    main(n)
