// Scaffold: pusher service account
//
// The pusher is impersonated by the Nullstone agent to sync DAG files to the
// Composer-managed GCS bucket (gs://<bucket>/dags). It is granted object admin
// on that bucket so a sync can create, overwrite, and prune DAG objects.

locals {
  max_pusher_name_len = 30 - length("pusher--${random_string.resource_suffix.result}")
  pusher_name         = "pusher-${substr(local.block_ref, 0, local.max_pusher_name_len)}-${random_string.resource_suffix.result}"

  // Composer manages a GCS bucket for DAGs; dag_gcs_prefix is gs://<bucket>/dags.
  dag_gcs_bucket = split("/", replace(google_composer_environment.this.config[0].dag_gcs_prefix, "gs://", ""))[0]
}

resource "google_service_account" "image_pusher" {
  account_id   = local.pusher_name
  display_name = "DAG Pusher for ${local.app_name}"
}

resource "google_storage_bucket_iam_member" "image_pusher_object_admin" {
  bucket = local.dag_gcs_bucket
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.image_pusher.email}"
}

resource "google_service_account_iam_binding" "image_pusher_impersonators" {
  service_account_id = google_service_account.image_pusher.id
  role               = "roles/iam.serviceAccountTokenCreator"
  members            = [for email in local.op_impersonater_emails : "serviceAccount:${email}"]
}
