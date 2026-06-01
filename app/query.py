"""Run a few analytical queries against the events table — the payoff for
landing data in BigQuery. This is the kind of SQL an analyst/engineer runs to
turn raw telemetry into answers.

Usage:  python query.py
"""

import config

QUERIES = {
    "Total events": """
        SELECT COUNT(*) AS total
        FROM `{table}`
    """,
    "Events by severity": """
        SELECT severity, COUNT(*) AS n
        FROM `{table}`
        GROUP BY severity
        ORDER BY n DESC
    """,
    "Avg reading by sensor type": """
        SELECT sensor_type, ROUND(AVG(reading), 1) AS avg_reading, COUNT(*) AS n
        FROM `{table}`
        GROUP BY sensor_type
        ORDER BY avg_reading DESC
    """,
    "Sites with the most warning/critical events": """
        SELECT site, COUNT(*) AS alerts
        FROM `{table}`
        WHERE severity IN ('warning', 'critical')
        GROUP BY site
        ORDER BY alerts DESC
    """,
}


def main() -> None:
    client = config.bq_client()
    table = config.bq_table_ref()

    for title, sql in QUERIES.items():
        print(f"\n=== {title} ===")
        rows = list(client.query(sql.format(table=table)).result())
        if not rows:
            print("  (no rows)")
            continue
        cols = rows[0].keys()
        print("  " + " | ".join(f"{c:>14}" for c in cols))
        for r in rows:
            print("  " + " | ".join(f"{str(r[c]):>14}" for c in cols))


if __name__ == "__main__":
    main()
