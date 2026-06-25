data "ns_connection" "network" {
  name     = "network"
  contract = "network/gcp/vpc"
}

locals {
  // Cloud Composer environments are deployed into a VPC + subnetwork.
  network_id    = data.ns_connection.network.outputs.vpc_id
  subnetwork_id = data.ns_connection.network.outputs.private_subnet_self_links[0]
}
