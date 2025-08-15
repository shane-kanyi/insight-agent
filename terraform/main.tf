terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com"
  ])
  service                    = each.key
  disable_dependent_services = true
}

# Create an Artifact Registry repository for Docker images
resource "google_artifact_registry_repository" "repo" {
  location      = var.gcp_region
  repository_id = "${var.service_name}-repo"
  format        = "DOCKER"
  depends_on    = [google_project_service.apis]
}

# Create a dedicated service account for the Cloud Run service
resource "google_service_account" "cloud_run_sa" {
  account_id   = "${var.service_name}-sa"
  display_name = "Service Account for ${var.service_name}"
}

# Create the Cloud Run service
resource "google_cloud_run_v2_service" "insight_agent" {
  name     = var.service_name
  location = var.gcp_region

  template {
    service_account = google_service_account.cloud_run_sa.email
    containers {
      image = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${google_artifact_registry_repository.repo.repository_id}/insight-agent:latest" # This will be updated by CI/CD
    }
  }

  # Restrict access to internal traffic only
  ingress = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  depends_on = [google_project_service.apis]
}

# Grant Cloud Build service account permission to push to Artifact Registry
resource "google_project_iam_member" "cloudbuild_artifact_writer" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

# Grant Cloud Build service account permission to deploy to Cloud Run
resource "google_project_iam_member" "cloudbuild_cloud_run_developer" {
  project = var.gcp_project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

data "google_project" "project" {}