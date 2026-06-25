// Scaffold: deployer service account
//
// The deployer is impersonated by the Nullstone agent to ship DAGs. It uploads
// DAG files to the Composer-managed GCS bucket (gs://<bucket>/dags) and reads
// environment configuration. roles/composer.environmentAndStorageObjectAdmin
// grants both: get/list on Composer environments and object admin on their
// associated storage buckets.

locals {
  max_deployer_name_len = 30 - length("deployer--${random_string.resource_suffix.result}")
  deployer_name         = "deployer-${substr(local.block_ref, 0, local.max_deployer_name_len)}-${random_string.resource_suffix.result}"
}

resource "google_service_account" "deployer" {
  account_id   = local.deployer_name
  display_name = "Deployer for ${local.app_name}"
}

resource "google_project_iam_member" "deployer_composer_admin" {
  project = local.project_id
  role    = "roles/composer.environmentAndStorageObjectAdmin"
  member  = "serviceAccount:${google_service_account.deployer.email}"
}

# Allows the deployer to act as the app runtime SA (required to update an
# environment that runs as a user-managed service account).
resource "google_service_account_iam_member" "deployer_act_as_runtime" {
  service_account_id = google_service_account.app.id
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.deployer.email}"
}

resource "google_service_account_iam_binding" "deployer_impersonators" {
  service_account_id = google_service_account.deployer.id
  role               = "roles/iam.serviceAccountTokenCreator"
  members            = [for email in local.op_impersonater_emails : "serviceAccount:${email}"]
}
