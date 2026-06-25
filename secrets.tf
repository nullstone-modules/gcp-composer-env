// Managed secrets are stored in GCP Secret Manager. They are named
// "<resource_name>-<KEY>" so that Airflow's Secret Manager backend can resolve
// them: with variables_prefix = "<resource_name>" and sep = "-", a DAG calling
// Variable.get("KEY") reads the secret "<resource_name>-KEY".
resource "google_secret_manager_secret" "app_secret" {
  for_each = local.managed_secret_keys

  // Valid secret_id: [a-zA-Z0-9_-]
  secret_id = "${local.resource_name}-${replace(each.value, "/[^a-zA-Z0-9_-]/", "-")}"
  labels    = local.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "app_secret" {
  for_each = local.managed_secret_keys

  secret      = google_secret_manager_secret.app_secret[each.value].id
  secret_data = local.managed_secret_values[each.value]
}

# Grant the app runtime SA access to every secret the workload references
# (both managed secrets from this module and unmanaged `{{ secret(...) }}` refs).
resource "google_secret_manager_secret_iam_member" "secrets_access" {
  for_each = local.all_secret_keys

  secret_id = local.all_secrets[each.value]
  project   = local.project_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.app.email}"
}

locals {
  // When this module manages any secrets, configure Airflow to resolve Variables
  // (and Connections) through the GCP Secret Manager backend.
  // https://airflow.apache.org/docs/apache-airflow-providers-google/stable/secrets-backends/google-cloud-secret-manager-backend.html
  secrets_backend_overrides = length(local.managed_secret_keys) > 0 ? {
    "secrets-backend" = "airflow.providers.google.cloud.secrets.secret_manager.CloudSecretManagerBackend"
    "secrets-backend_kwargs" = jsonencode({
      project_id       = local.project_id
      variables_prefix = local.resource_name
      sep              = "-"
    })
  } : {}
}
