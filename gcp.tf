data "google_client_config" "this" {}
data "google_project" "this" {}

locals {
  region         = data.google_client_config.this.region
  project_id     = data.google_client_config.this.project
  project_number = data.google_project.this.number
}

resource "google_project_service" "composer_api" {
  service                    = "composer.googleapis.com"
  disable_on_destroy         = false
  disable_dependent_services = false
}

resource "google_project_service" "secretmanager_api" {
  service                    = "secretmanager.googleapis.com"
  disable_on_destroy         = false
  disable_dependent_services = false
}