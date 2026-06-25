output "project_id" {
  value       = local.project_id
  description = "string ||| The GCP Project ID hosting this Cloud Composer environment."
}

output "region" {
  value       = local.region
  description = "string ||| The GCP region where this Cloud Composer environment is hosted."
}

output "environment_name" {
  value       = google_composer_environment.this.name
  description = "string ||| The name of the Cloud Composer environment."
}

output "environment_id" {
  value       = google_composer_environment.this.id
  description = "string ||| The fully-qualified ID of the Cloud Composer environment."
}

output "airflow_uri" {
  value       = local.airflow_uri
  description = "string ||| The URI of the Apache Airflow web UI hosted within this environment."
}

output "dag_gcs_prefix" {
  value       = google_composer_environment.this.config[0].dag_gcs_prefix
  description = "string ||| The GCS path (gs://<bucket>/dags) where DAGs are uploaded for this environment."
}

output "gke_cluster" {
  value       = google_composer_environment.this.config[0].gke_cluster
  description = "string ||| The GKE cluster that backs this Cloud Composer environment."
}

output "app_service_account" {
  value = {
    id    = google_service_account.app.id
    name  = google_service_account.app.name
    email = google_service_account.app.email
  }
  description = "object({ id: string, name: string, email: string }) ||| The app runtime service account the Composer environment runs as."
}

output "log_provider" {
  value       = "cloudlogging"
  description = "string ||| The log provider used for this app."
}

output "log_reader" {
  value = {
    project_id  = local.project_id
    email       = google_service_account.log_reader.email
    id          = google_service_account.log_reader.id
    impersonate = true
  }
  description = "object({ email: string, impersonate: bool }) ||| A GCP service account with explicit privilege to stream logs from this Cloud Composer environment."
}

output "log_filter" {
  value       = "resource.type=\"cloud_composer_environment\" AND resource.labels.environment_name=\"${local.environment_name}\""
  description = "string ||| A Cloud Logging filter that selects logs for this Cloud Composer environment."
}

output "metrics_provider" {
  value       = "cloudmonitoring"
  description = "string ||| The metrics provider used for this app."
}

output "metrics_reader" {
  value = {
    project_id  = local.project_id
    email       = google_service_account.deployer.email
    impersonate = true
  }
  description = "object({ email: string, impersonate: bool }) ||| A GCP service account with explicit privilege to view metrics for this app."
}

output "metrics_mappings" {
  value       = local.metrics_mappings
  description = "string ||| A mapping of metric definitions used to render app metrics in the Nullstone UI."
}

output "deployer" {
  value = {
    project_id  = local.project_id
    email       = google_service_account.deployer.email
    id          = google_service_account.deployer.id
    impersonate = true
  }
  description = "object({ email: string, impersonate: bool }) ||| A GCP service account with explicit privilege to deploy DAGs to this Cloud Composer environment."
}

output "service_name" {
  value       = ""
  description = "string ||| This is blank because Composer does not expose a single service endpoint."
}

output "private_urls" {
  value       = local.private_urls
  description = "list(string) ||| A list of URLs only accessible inside the network."
}

output "public_urls" {
  value       = local.public_urls
  description = "list(string) ||| A list of URLs accessible to the public."
}
