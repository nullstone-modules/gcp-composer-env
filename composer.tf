locals {
  environment_name = local.resource_name

  // The Cloud Composer service agent needs roles/composer.ServiceAgentV2Ext to
  // manage environments that run as a user-provided service account.
  composer_service_agent = "serviceAccount:service-${local.project_number}@cloudcomposer-accounts.iam.gserviceaccount.com"

  airflow_config_overrides = merge(local.secrets_backend_overrides, var.airflow_config_overrides)
}

resource "google_project_iam_member" "composer_agent_v2_ext" {
  project = local.project_id
  role    = "roles/composer.ServiceAgentV2Ext"
  member  = local.composer_service_agent
}

resource "google_composer_environment" "this" {
  name   = local.environment_name
  region = local.region
  labels = local.labels

  config {
    environment_size = var.environment_size

    # Private networking: no public IPs. Composer 3 reaches the connected VPC
    # through a Private Service Connect network attachment that it auto-creates
    # from the network + subnetwork below.
    enable_private_environment = var.enable_private_environment

    software_config {
      image_version            = var.image_version
      env_variables            = local.composer_env_variables
      airflow_config_overrides = local.airflow_config_overrides
      pypi_packages            = var.pypi_packages
    }

    node_config {
      service_account = google_service_account.app.email
      network         = local.network_id
      subnetwork      = local.subnetwork_id
    }

    workloads_config {
      scheduler {
        cpu        = var.scheduler.cpu
        memory_gb  = var.scheduler.memory_gb
        storage_gb = var.scheduler.storage_gb
        count      = var.scheduler.count
      }

      web_server {
        cpu        = var.web_server.cpu
        memory_gb  = var.web_server.memory_gb
        storage_gb = var.web_server.storage_gb
      }

      worker {
        cpu        = var.worker.cpu
        memory_gb  = var.worker.memory_gb
        storage_gb = var.worker.storage_gb
        min_count  = var.worker.min_count
        max_count  = var.worker.max_count
      }
    }
  }

  depends_on = [
    google_project_iam_member.app_composer_worker,
    google_project_iam_member.composer_agent_v2_ext,
    google_secret_manager_secret_version.app_secret,
  ]
}
