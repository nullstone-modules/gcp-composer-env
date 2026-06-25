// Scaffold: metrics reader access
//
// Metrics are read by the deployer SA (aliased as the metrics_reader output).
// Grant it monitoring.viewer so the Nullstone UI can query Cloud Monitoring.
resource "google_project_iam_member" "deployer_metrics_viewer" {
  project = local.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.deployer.email}"
}

locals {
  metrics_mappings = concat(local.base_metrics, local.capabilities.metrics)

  // Cloud Composer environment metrics are exposed through Cloud Monitoring.
  // See https://cloud.google.com/composer/docs/monitoring-dashboard
  query_filter = "monitored_resource=\"cloud_composer_environment\",environment_name=\"${local.environment_name}\""

  base_metrics = [
    {
      name = "environment/health"
      type = "usage-percent"
      unit = "%"

      mappings = {
        healthy = {
          query = "avg(composer_googleapis_com_environment_healthy{${local.query_filter}}) * 100"
        }
      }
    },
    {
      name = "dags/parse_time"
      type = "duration"
      unit = "s"

      mappings = {
        total_parse_time = {
          query = "avg(composer_googleapis_com_environment_dag_processing_total_parse_time{${local.query_filter}})"
        }
      }
    },
    {
      name = "workers/pods"
      type = "usage"
      unit = "count"

      mappings = {
        running_workers = {
          query = "avg(composer_googleapis_com_environment_worker_pod_eviction_count{${local.query_filter}})"
        }
      }
    },
  ]
}
