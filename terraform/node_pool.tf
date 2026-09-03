# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform from "projects/sandbox-g-k-engine/locations/asia-south1/clusters/ismartcheck-nonprod-demo-gke/nodePools/ismartcheck-nonprod-demo-node-pool"
resource "google_container_node_pool" "nodes" {
  cluster                   = "ismartcheck-nonprod-demo-gke"
  deletion_policy           = "DELETE"
  ignore_node_count_changes = false
  initial_node_count        = 1
  location                  = "asia-south1"
  max_pods_per_node         = 110
  name                      = "ismartcheck-nonprod-demo-node-pool"
  node_count                = 1
  node_locations            = ["asia-south1-a", "asia-south1-b", "asia-south1-c"]
  project                   = "sandbox-g-k-engine"
  version                   = "1.35.7-gke.1027000"
  autoscaling {
    location_policy      = "BALANCED"
    max_node_count       = 0
    min_node_count       = 0
    total_max_node_count = 6
    total_min_node_count = 3
  }
  management {
    auto_repair  = true
    auto_upgrade = true
  }
  network_config {
    accelerator_network_profile = null
    create_pod_range            = false
    enable_private_nodes        = false
    pod_ipv4_cidr_block         = "10.80.0.0/21"
    pod_range                   = "gke-ismartcheck-nonprod-demo-gke-pods-ec416adf"
    subnetwork                  = "projects/sandbox-g-k-engine/regions/asia-south1/subnetworks/ismartcheck-nonprod-demo-workload-subnet"
  }
  node_config {
    boot_disk_kms_key           = null
    disk_size_gb                = 100
    disk_type                   = "pd-standard"
    enable_confidential_storage = false
    flex_start                  = false
    image_type                  = "COS_CONTAINERD"
    labels                      = {}
    local_ssd_count             = 0
    local_ssd_encryption_mode   = null
    logging_variant             = "DEFAULT"
    machine_type                = "e2-medium"
    max_run_duration            = null
    metadata = {
      disable-legacy-endpoints = "true"
    }
    node_group   = null
    oauth_scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
    preemptible  = false
    resource_labels = {
      goog-gke-node-pool-provisioning-model = "on-demand"
    }
    resource_manager_tags = {}
    service_account       = "default"
    spot                  = false
    storage_pools         = []
    tags                  = []
    advanced_machine_features {
      enable_nested_virtualization = false
      performance_monitoring_unit  = null
      threads_per_core             = 0
    }
    boot_disk {
      disk_type              = "pd-standard"
      provisioned_iops       = 0
      provisioned_throughput = 0
      size_gb                = 100
    }
    ephemeral_storage_local_ssd_config {
      data_cache_count = 0
      local_ssd_count  = 0
    }
    kubelet_config {
      allowed_unsafe_sysctls                      = []
      container_log_max_files                     = 0
      container_log_max_size                      = null
      cpu_cfs_quota                               = false
      cpu_cfs_quota_period                        = null
      cpu_manager_policy                          = null
      eviction_max_pod_grace_period_seconds       = 0
      image_gc_high_threshold_percent             = 0
      image_gc_low_threshold_percent              = 0
      image_maximum_gc_age                        = null
      image_minimum_gc_age                        = null
      insecure_kubelet_readonly_port_enabled      = "FALSE"
      max_parallel_image_pulls                    = 2
      pod_pids_limit                              = 0
      shutdown_grace_period_critical_pods_seconds = 0
      shutdown_grace_period_seconds               = 0
      single_process_oom_kill                     = false
    }
    node_image_config {
      image         = "gke-1357-gke1027000-cos-125-19216-532-25-c-pre"
      image_project = "gke-node-images"
    }
    shielded_instance_config {
      enable_integrity_monitoring = true
      enable_secure_boot          = false
    }
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
  placement_policy {
    policy_name  = null
    tpu_topology = null
    type         = ""
  }
  queued_provisioning {
    enabled = false
  }
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }
}
