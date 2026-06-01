# Analytics warehouse for processed telemetry.
#
# AWS analogy: closest is Athena (serverless SQL over data) or Redshift (a
# warehouse), but BigQuery is its own thing — fully serverless, you pay per byte
# scanned. That pricing model is WHY partitioning + clustering matter so much:
# they shrink how much data each query reads.

resource "google_bigquery_dataset" "this" {
  project                    = var.project_id
  dataset_id                 = var.dataset_id
  location                   = var.location
  delete_contents_on_destroy = var.delete_contents_on_destroy
  labels                     = var.labels
}

resource "google_bigquery_table" "events" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.this.dataset_id
  table_id   = var.table_id
  schema     = var.schema
  labels     = var.labels

  # Partition by day on a TIMESTAMP/DATE column. A query filtering on this column
  # only scans the matching days = dramatically less data billed (partition pruning).
  dynamic "time_partitioning" {
    for_each = var.partition_field == "" ? [] : [1]
    content {
      type  = "DAY"
      field = var.partition_field
    }
  }

  # Clustering co-locates rows by these columns within a partition, so filters on
  # them read fewer blocks. Great for high-cardinality dimensions like site/severity.
  clustering = var.clustering_fields

  deletion_protection = false # dev convenience; leave true in prod
}
