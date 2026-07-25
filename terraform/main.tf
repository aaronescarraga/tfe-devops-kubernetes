terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }

  # Backend remoto en GCS para guardar el estado de Terraform
  backend "gcs" {
    bucket = "project-b94ae20d-a05b-4291-835-tfstate"
    prefix = "terraform/state"
  }
}
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Habilitar las APIs necesarias en GCP
resource "google_project_service" "apis" {
  for_each = toset([
    "container.googleapis.com",       # GKE
    "compute.googleapis.com",         # Compute Engine
    "iam.googleapis.com",             # IAM
    "storage.googleapis.com",         # Cloud Storage
    "cloudresourcemanager.googleapis.com",
    "monitoring.googleapis.com",      # Monitoring
    "logging.googleapis.com",         # Logging
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}
