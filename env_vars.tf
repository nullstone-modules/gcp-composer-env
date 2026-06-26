// Environment Variables and Secrets
//
// This file aggregates environment variables and secrets from multiple sources
// - Standard Environment Variables (NULLSTONE_APP, etc.)
// - Google Environment Variables (GOOGLE_CLOUD_PROJECT, etc.)
// - User Input (var.env_vars, var.secrets)
// - Capability Outputs (output.env, output.secrets)
//
// Non-secret values are injected into the Composer environment as Airflow
// environment variables (software_config.env_variables). Secrets are stored in
// GCP Secret Manager and surfaced to DAGs through the Airflow Secret Manager
// backend (see secrets.tf).

variable "env_vars" {
  type        = map(string)
  default     = {}
  description = <<EOF
The environment variables to inject into the Composer environment.
These are typically used to configure an app per environment.
It is dangerous to put sensitive information in this variable because they are not protected and could be unintentionally exposed.
EOF
}

variable "secrets" {
  type        = map(string)
  default     = {}
  sensitive   = true
  description = <<EOF
The sensitive environment variables to make available to the Composer environment.
These are stored in GCP Secret Manager and resolved by Airflow's Secret Manager backend.
EOF
}

locals {
  cap_env_vars = {
    for item in local.capabilities.env : "${local.cap_env_prefixes[item.cap_tf_id]}${item.name}" => item.value
  }
  cap_secrets = {
    for item in local.capabilities.secrets : "${local.cap_env_prefixes[item.cap_tf_id]}${item.name}" => sensitive(item.value)
  }

  standard_env_vars = tomap({
    NULLSTONE_STACK      = data.ns_workspace.this.stack_name
    NULLSTONE_APP        = data.ns_workspace.this.block_name
    NULLSTONE_ENV        = data.ns_workspace.this.env_name
    NULLSTONE_VERSION    = data.ns_app_env.this.version
    NULLSTONE_COMMIT_SHA = data.ns_app_env.this.commit_sha
  })
  // GOOGLE_CLOUD_PROJECT is kept here so it is available in the interpolation
  // context (other env vars / capabilities can reference it). It is reserved by
  // Cloud Composer and stripped from the map passed to the environment resource
  // via local.reserved_env_var_names below — Composer injects it at runtime.
  google_env_vars = tomap({
    GOOGLE_CLOUD_PROJECT         = local.project_id
    GOOGLE_CLOUD_REGION          = local.region
    GOOGLE_CLOUD_PROJECT_NUMBER  = local.project_number
    GOOGLE_SERVICE_ACCOUNT_EMAIL = google_service_account.app.email
  })

  input_env_vars    = merge(local.standard_env_vars, local.google_env_vars, local.cap_env_vars, var.env_vars)
  input_secrets     = merge(local.cap_secrets, var.secrets)
  input_secret_keys = nonsensitive(concat(keys(local.cap_secrets), keys(var.secrets)))
}

data "ns_env_variables" "this" {
  input_env_variables = local.input_env_vars
  input_secrets       = local.input_secrets
}

// "existing" adds support for the `secret(...)` syntax
// This only supports `secret(...)` specified by the user
data "ns_env_variables" "existing" {
  input_env_variables = var.env_vars
  input_secrets       = {}
}

data "ns_secret_keys" "this" {
  input_env_variables = var.env_vars
  input_secret_keys   = local.input_secret_keys
}

locals {
  // all_env_vars contains all environment variables excluding those detected as secrets
  // This is a map of name => value
  all_env_vars = data.ns_env_variables.this.env_variables

  // Cloud Composer reserves a set of environment variable names that it manages
  // itself and rejects on the API. Strip any colliding names (from standard,
  // google, user, or capability sources) so a single reserved key cannot fail
  // the whole environment apply. List per the Composer 3 docs:
  // https://cloud.google.com/composer/docs/composer-3/set-environment-variables
  reserved_env_var_names = toset([
    "AIRFLOW_DATABASE_VERSION", "AIRFLOW_HOME", "AIRFLOW_SRC_DIR", "AIRFLOW_WEBSERVER",
    "AUTO_GKE", "CLOUDSDK_METRICS_ENVIRONMENT", "CLOUD_LOGGING_ONLY",
    "COMPOSER_AGENT_BUILD_SERVICE_ACCOUNT", "COMPOSER_ENVIRONMENT", "COMPOSER_ENVIRONMENT_SIZE",
    "COMPOSER_GKE_LOCATION", "COMPOSER_GKE_NAME", "COMPOSER_GKE_ZONE", "COMPOSER_LOCATION",
    "COMPOSER_OPERATION_UUID", "COMPOSER_PYTHON_VERSION", "COMPOSER_VERSION",
    "CONTAINER_NAME", "C_FORCE_ROOT", "DAGS_FOLDER", "GCE_METADATA_TIMEOUT",
    "GCP_PROJECT", "GCP_TENANT_PROJECT", "GCSFUSE_EXTRACTED", "GCS_BUCKET",
    "GKE_CLUSTER_NAME", "GKE_IN_TENANT", "GOOGLE_APPLICATION_CREDENTIALS", "GOOGLE_CLOUD_PROJECT",
    "MAJOR_VERSION", "MINOR_VERSION", "PATH", "PIP_DISABLE_PIP_VERSION_CHECK", "PORT",
    "PROJECT_ID", "PYTHONPYCACHEPREFIX", "PYTHONWARNINGS", "REDIS_PASSWORD", "REDIS_PORT",
    "REDIS_USER", "SQL_DATABASE", "SQL_HOST", "SQL_INSTANCE", "SQL_PASSWORD", "SQL_PROJECT",
    "SQL_REGION", "SQL_USER",
  ])
  // Composer also rejects Airflow config-style overrides (AIRFLOW__<SECTION>__<KEY>)
  // as env vars; those belong in var.airflow_config_overrides instead.
  reserved_env_var_prefixes = ["AIRFLOW__"]

  // composer_env_variables is the safe subset passed to software_config.env_variables.
  composer_env_variables = {
    for k, v in local.all_env_vars : k => v
    if !contains(local.reserved_env_var_names, k) && length([for p in local.reserved_env_var_prefixes : true if startswith(k, p)]) == 0
  }

  // unmanaged_secret_keys are secrets that are not managed by this module
  // This is a list of string for all references where a user specified {{ secret(...) }}
  // The value of each item is the "..." inside secret()
  unmanaged_secret_keys = toset([for key, value in data.ns_env_variables.existing.secret_refs : key])
  // managed_secret_keys is a list of keys for secrets that this module manages
  // This excludes references to existing secrets {{ secret(...) }}
  managed_secret_keys = setsubtract(data.ns_secret_keys.this.secret_keys, local.unmanaged_secret_keys)
  all_secret_keys     = toset(concat(tolist(local.unmanaged_secret_keys), tolist(local.managed_secret_keys)))

  // unmanaged_secrets is a map of name => secret_ref
  unmanaged_secrets = data.ns_env_variables.existing.secret_refs
  // managed_secrets is a map of name => secret_id
  managed_secrets = { for key in local.managed_secret_keys : key => google_secret_manager_secret.app_secret[key].secret_id }
  // managed_secret_values is a map of name => value
  managed_secret_values = data.ns_env_variables.this.secrets
  all_secrets           = merge(local.unmanaged_secrets, local.managed_secrets)
}
