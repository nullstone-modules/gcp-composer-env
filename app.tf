data "ns_app_env" "this" {
  stack_id = data.ns_workspace.this.stack_id
  app_id   = data.ns_workspace.this.block_id
  env_id   = data.ns_workspace.this.env_id
}

locals {
  app_name    = data.ns_workspace.this.block_name
  app_version = data.ns_app_env.this.version
}

locals {
  app_metadata = tomap({
    // Inject app metadata into capabilities here (e.g. service_account_id)
    service_account_id    = google_service_account.app.id
    service_account_email = google_service_account.app.email
    environment_name      = local.environment_name
    dag_gcs_prefix        = google_composer_environment.this.config[0].dag_gcs_prefix
  })
}
