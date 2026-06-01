# Secure Event Ingestion Platform (GCP practice)

A hands-on project for practicing **Google Cloud engineering**, Terraform-first,
runnable entirely on a laptop with **no GCP account and $0 cost**.

The scenario is a defense-flavored telemetry pipeline: agents publish events,
they're queued, processed, and landed in both an analytics store and a raw
archive — with least-privilege IAM, networking, and infra-as-code throughout.

```
 agents/sensors ──▶ Pub/Sub topic ──▶ Cloud Run processor ──┬──▶ BigQuery (analytics)
                     (+ dead-letter)                         └──▶ GCS  (raw archive)
```

## Two layers (and why)

Emulators only implement the **data plane** (publish a message, write an object),
not the **control plane** (create a topic). So Terraform can't `apply` into an
emulator. We split the project the way real GCP shops do:

| Layer | Tooling | Local loop |
|-------|---------|-----------|
| **Infra** | Terraform (`google` provider) | `fmt` → `validate` → `plan` → `terraform test` (mocked providers, no cloud) |
| **Runtime** | Docker emulators + a small app | `make up`, publish events, watch them flow |

Both layers agree on resource names, so they stay consistent.

## Layout

```
infra/
  modules/        Reusable, single-concern Terraform modules
    pubsub/         Topic + subscription + dead-letter path
    storage/        Hardened GCS bucket (uniform access, versioning, lifecycle)
  envs/
    dev/            Wires the modules into a dev environment
local/            docker-compose for emulators (coming next)
app/              Pipeline processor (coming next)
Makefile          Command cheat-sheet — run `make help`
```

## Quickstart

**Infra layer (Terraform):**
```bash
make init      # download the google provider
make check     # fmt + validate (the fast local gate)
```

**Runtime layer (run the pipeline locally):**
```bash
make up        # start the Pub/Sub + GCS + BigQuery emulators in Docker
make venv      # one-time: create the Python venv + install deps
make demo      # bootstrap -> publish -> process (GCS + BQ) -> query
make down      # stop the emulators
```
You'll see events published, pulled, written to
`gs://.../events/site=<site>/severity=<sev>/<id>.json`, streamed into BigQuery,
and then queried with SQL.

## AWS → GCP cheat sheet (you're coming from AWS ADC)

| AWS | GCP | Notes |
|-----|-----|-------|
| Account | Project | The unit of isolation & billing |
| IAM role / policy | IAM role + binding on a resource | GCP binds *members* to *roles* on a *resource* |
| IAM role (assumed by service) | Service Account | An identity *and* a principal |
| SNS + SQS | Pub/Sub (topic + subscription) | One service does both fan-out and queueing |
| SQS dead-letter queue | Dead-letter topic | Same idea, configured on the subscription |
| S3 bucket | GCS bucket | One global namespace, like S3 |
| S3 Block Public Access | `public_access_prevention = "enforced"` | |
| S3 disable ACLs | `uniform_bucket_level_access = true` | IAM-only access |
| Lambda / Fargate | Cloud Functions / Cloud Run | Cloud Run = container, Fargate-ish |
| Athena / Redshift | BigQuery | Serverless analytical warehouse |
| VPC / subnet / SG | VPC / subnet / firewall rule | Firewall rules are project-level, tag-targeted |
| CloudFormation | Deployment Manager (rare) — **Terraform** is standard | |
| CloudWatch | Cloud Monitoring + Cloud Logging | |

## IAM design notes (coming from AWS)

GCP inverts the AWS model. Instead of writing a policy document and attaching it,
you **bind a member to a role on a resource**:

```
member: serviceAccount:telemetry-processor@<project>...   (who)
role:   roles/pubsub.subscriber                            (what)
on:     the telemetry-events-sub subscription              (where)  <-- the key part
```

What this project does on purpose:
- **One service account per workload** (publisher, processor) — never a shared SA.
- **Resource-scoped bindings**, not project-wide. The publisher gets
  `pubsub.publisher` on *one topic*; the processor gets `storage.objectCreator`
  (create-only, not admin) on *one bucket*. See `infra/envs/dev/main.tf`.
- **`*_iam_member`** (additive, one principal) rather than `*_iam_binding`
  (authoritative, overwrites the whole list) or `*_iam_policy` (replaces
  everything). `member` is the safe default — it can't accidentally revoke
  grants made elsewhere. This `member` vs `binding` vs `policy` distinction is a
  classic Terraform-GCP gotcha worth knowing cold.

Role tiers, fyi: **primitive** (Owner/Editor/Viewer — too broad, avoid),
**predefined** (`roles/pubsub.subscriber` — what we use), **custom** (hand-pick
permissions when predefined is still too wide).

## BigQuery design notes

BigQuery bills **per byte scanned**, so the whole game is reading less data:
- **Partitioning** (`time_partitioning` on `event_ts`, DAY granularity): a query
  with `WHERE event_ts >= ...` only scans the matching day-partitions, not the
  whole table. This is the single biggest cost lever.
- **Clustering** (`site`, `severity`): within a partition, rows are sorted by
  these columns so a filter on them reads fewer storage blocks.
- **Streaming insert** (`tabledata.insertAll`, via `insert_rows_json`): rows are
  queryable within seconds — what the processor uses. The alternative is batch
  load jobs (free, but higher latency).

Note the table schema lives in Terraform (`infra/envs/dev/main.tf`, as
`jsonencode([...])`) — schema-as-code, versioned and reviewed like everything else.

## Status

- [x] Terraform skeleton: `pubsub` + `storage` modules, `dev` env, validating
- [x] Local emulator stack (`local/docker-compose.yml`) — Pub/Sub + GCS
- [x] Python pipeline: publisher → Pub/Sub → processor → GCS archive, running locally
- [x] `iam` module (service accounts + resource-scoped least-privilege bindings)
- [x] `bigquery` module (partitioned + clustered events table) + dataset IAM
- [x] Processor streams to BigQuery; `query.py` runs analytical SQL
- [ ] `terraform test` suites with mocked providers
- [ ] CI gate (fmt/validate/test) + a `prod` env
- [ ] Dead-letter failure demo
