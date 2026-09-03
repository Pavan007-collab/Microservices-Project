resource "google_compute_subnetwork" "workload" {
  name                     = "ismartcheck-nonprod-demo-workload-subnet"
  description              = "Demo workload subnet"
  region                   = "asia-south1"
  network                  = google_compute_network.vpc.id
  ip_cidr_range            = "10.70.1.0/24"
  private_ip_google_access = true

  secondary_ip_range {
    range_name              = "gke-ismartcheck-nonprod-demo-gke-pods-ec416adf"
    ip_cidr_range           = "10.80.0.0/21"
    reserved_internal_range = "networkconnectivity.googleapis.com/projects/sandbox-g-k-engine/locations/global/internalRanges/gke-ismartcheck-nonprod-demo-gke-pods-ec416adf"
  }
}
