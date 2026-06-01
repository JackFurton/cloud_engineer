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
make up        # start the Pub/Sub + GCS emulators in Docker
make venv      # one-time: create the Python venv + install deps
make demo      # bootstrap resources -> publish 10 events -> archive to GCS
make down      # stop the emulators
```
You'll see events published, pulled, and written to
`gs://.../events/site=<site>/severity=<sev>/<id>.json`.

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

## Status

- [x] Terraform skeleton: `pubsub` + `storage` modules, `dev` env, validating
- [x] Local emulator stack (`local/docker-compose.yml`) — Pub/Sub + GCS
- [x] Python pipeline: publisher → Pub/Sub → processor → GCS archive, running locally
- [ ] `iam` module (service accounts + least-privilege bindings)
- [ ] `bigquery` module (dataset + table for analytics)
- [ ] `terraform test` suites with mocked providers
- [ ] Processor also writes to BigQuery (add emulator)
- [ ] CI gate (fmt/validate/test) + a `prod` env
