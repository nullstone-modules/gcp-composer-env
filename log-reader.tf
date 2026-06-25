// Scaffold: log reader service account
//
// Impersonated by the Nullstone agent to stream Composer/Airflow logs from
// Cloud Logging.

locals {
  max_log_reader_name_len = 30 - length("log-reader--${random_string.resource_suffix.result}")
  log_reader_name         = "log-reader-${substr(local.block_ref, 0, local.max_log_reader_name_len)}-${random_string.resource_suffix.result}"
}

resource "google_service_account" "log_reader" {
  account_id   = local.log_reader_name
  display_name = "Log Reader for ${local.app_name}"
}

resource "google_project_iam_member" "log_reader_logs_access" {
  project = local.project_id
  role    = "roles/logging.viewer"
  member  = "serviceAccount:${google_service_account.log_reader.email}"
}

resource "google_service_account_iam_binding" "log_reader_impersonators" {
  service_account_id = google_service_account.log_reader.id
  role               = "roles/iam.serviceAccountTokenCreator"
  members            = [for email in local.op_impersonater_emails : "serviceAccount:${email}"]
}
