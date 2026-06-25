// Scaffold: app runtime service account
//
// This is the service account that the Cloud Composer environment runs as
// (schedulers, workers, web server, triggerer). Capability-layer bindings
// (e.g. secretmanager.secretAccessor, bigquery.dataEditor) should target this
// SA's email so DAGs inherit those grants at runtime.

locals {
  max_app_name_len  = 30 - length("-${random_string.resource_suffix.result}")
  app_sa_account_id = "${substr(local.block_ref, 0, local.max_app_name_len)}-${random_string.resource_suffix.result}"
}

resource "google_service_account" "app" {
  account_id   = local.app_sa_account_id
  display_name = "Service Account for Nullstone App ${local.app_name}"
}

# Allows the app SA to mint OAuth tokens for itself — needed, for example, to
# generate signed URLs for GCS bucket objects from within a DAG.
resource "google_service_account_iam_member" "app_generate_token_self" {
  service_account_id = google_service_account.app.id
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.app.email}"
}

# Cloud Composer requires the environment's service account to hold
# roles/composer.worker on the project.
resource "google_project_iam_member" "app_composer_worker" {
  project = local.project_id
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.app.email}"
}
