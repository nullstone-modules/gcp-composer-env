data "ns_connection" "network" {
  name     = "network"
  contract = "network/gcp/vpc"
}

locals {
  // Composer 3 attaches to this VPC + private subnetwork via a Private Service
  // Connect network attachment. Using the network's private subnet places the
  // environment alongside other private workloads (GKE internal services, the
  // Cloud SQL Private Service Access range, etc.) so DAGs can reach them.
  network_id    = data.ns_connection.network.outputs.vpc_id
  subnetwork_id = data.ns_connection.network.outputs.private_subnet_self_links[0]
}
