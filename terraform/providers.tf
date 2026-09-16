terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.46"
    }
  }

  backend "gcs" {
    bucket = "tfstate-sandbox-g-k-engine-802553692011"
    prefix = "ismartcheck/nonprod"
  }
}

provider "google" {
  project = "sandbox-g-k-engine"
  region  = "asia-south1"
}
