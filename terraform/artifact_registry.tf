resource "google_artifact_registry_repository" "docker" {
  location               = "asia-south1"
  repository_id          = "ismartcheck-nonprod-demo-registry"
  format                 = "DOCKER"
  cleanup_policy_dry_run = true

  docker_config {
    immutable_tags = false
  }
}
