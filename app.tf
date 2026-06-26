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
  // NOTE: app_metadata is consumed by capability modules, whose outputs (env
  // vars / secrets) feed back into the Composer environment. It must therefore
  // only reference values that do NOT depend on google_composer_environment.this
  // (e.g. the app SA + pure locals), otherwise Terraform reports a dependency
  // cycle. Do not add dag_gcs_prefix / airflow_uri / other environment outputs.
  app_metadata = tomap({
    service_account_id    = google_service_account.app.id
    service_account_email = google_service_account.app.email
    environment_name      = local.environment_name
  })
}
