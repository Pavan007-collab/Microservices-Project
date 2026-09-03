resource "google_container_cluster" "gke" {
  name     = "ismartcheck-nonprod-demo-gke"
  location = "asia-south1"

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.workload.id

  release_channel {
    channel = "REGULAR"
  }

  networking_mode = "VPC_NATIVE"

  dns_config {
    cluster_dns = "KUBE_DNS"
  }

  workload_identity_config {
    workload_pool = "sandbox-g-k-engine.svc.id.goog"
  }

  enable_shielded_nodes = true

  monitoring_config {
    managed_prometheus {
      enabled = true
    }
  }

  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS",
    ]
  }

  addons_config {
    dns_cache_config {
      enabled = true
    }

    gce_persistent_disk_csi_driver_config {
      enabled = true
    }

    http_load_balancing {
      disabled = false
    }
  }
}
