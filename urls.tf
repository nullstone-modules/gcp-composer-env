locals {
  // The Airflow web UI is an IAM-gated HTTPS endpoint provided by Composer.
  airflow_uri = google_composer_environment.this.config[0].airflow_uri

  // Private and public URLs are shown in the Nullstone UI
  // Typically, they are created through capabilities attached to the application
  additional_private_urls = []
  additional_public_urls  = [local.airflow_uri]

  private_urls = concat([for cur in local.capabilities.private_urls : cur.url], local.additional_private_urls)
  public_urls  = concat([for cur in local.capabilities.public_urls : cur.url], local.additional_public_urls)
}
