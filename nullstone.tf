data "ns_workspace" "this" {}

data "ns_agent" "this" {}

locals {
  ns_agent_service_account_email = data.ns_agent.this.gcp_service_account_email

  // Service accounts that are allowed to impersonate the scaffolding SAs
  // (deployer, log reader). The Nullstone agent impersonates these to deploy
  // DAGs and stream logs.
  op_impersonater_emails = [local.ns_agent_service_account_email]
}

// Generate a random suffix to ensure uniqueness of resources
resource "random_string" "resource_suffix" {
  length  = 5
  lower   = true
  upper   = false
  numeric = false
  special = false
}

locals {
  labels        = data.ns_workspace.this.gcp_labels
  block_name    = data.ns_workspace.this.block_name
  block_ref     = data.ns_workspace.this.block_ref
  resource_name = "${local.block_ref}-${random_string.resource_suffix.result}"
}
