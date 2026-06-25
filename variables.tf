variable "image_version" {
  type        = string
  default     = "composer-2-airflow-2"
  description = <<EOF
The version of the Composer/Airflow image to run.
Use an alias such as "composer-2-airflow-2" to track the latest patch, or pin a
specific build like "composer-2.10.5-airflow-2.10.5".
EOF
}

variable "environment_size" {
  type        = string
  default     = "ENVIRONMENT_SIZE_SMALL"
  description = <<EOF
The size of the Cloud Composer environment.
One of ENVIRONMENT_SIZE_SMALL, ENVIRONMENT_SIZE_MEDIUM, or ENVIRONMENT_SIZE_LARGE.
EOF
}

variable "pypi_packages" {
  type        = map(string)
  default     = {}
  description = <<EOF
Custom PyPI packages to install into the Airflow environment.
The map key is the package name and the value is an optional version specifier
(e.g. { "scikit-learn" = "==1.4.2", "numpy" = "" }).
EOF
}

variable "airflow_config_overrides" {
  type        = map(string)
  default     = {}
  description = <<EOF
Airflow configuration overrides applied to the environment.
Keys use the "section-key" format (e.g. "core-dags_are_paused_at_creation").
EOF
}

variable "scheduler" {
  type = object({
    cpu        = number
    memory_gb  = number
    storage_gb = number
    count      = number
  })
  default = {
    cpu        = 0.5
    memory_gb  = 1.875
    storage_gb = 1
    count      = 1
  }
  description = "Resource allocation for the Airflow scheduler(s)."
}

variable "web_server" {
  type = object({
    cpu        = number
    memory_gb  = number
    storage_gb = number
  })
  default = {
    cpu        = 0.5
    memory_gb  = 1.875
    storage_gb = 1
  }
  description = "Resource allocation for the Airflow web server."
}

variable "worker" {
  type = object({
    cpu        = number
    memory_gb  = number
    storage_gb = number
    min_count  = number
    max_count  = number
  })
  default = {
    cpu        = 0.5
    memory_gb  = 1.875
    storage_gb = 1
    min_count  = 1
    max_count  = 3
  }
  description = "Resource allocation and autoscaling bounds for the Airflow workers."
}
