resource "google_compute_network" "vpc" {
  name                    = "ismartcheck-nonprod-demo-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}
