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

# Create a Workload Identity Pool for GitHub Actions
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool1"
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions"
}

# Create a Provider within the Pool for your specific repository
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Actions Provider"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  attribute_condition = "assertion.repository == '${var.github_repo}'" # Simplified condition for broader branch support initially

  # The FIX: Specify the provider type is OIDC and provide its configuration
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Create a dedicated service account for the GitHub Actions runner
resource "google_service_account" "github_actions_sa" {
  account_id   = "github-actions-sa"
  display_name = "Service Account for GitHub Actions"
}

# Grant the GitHub Actions service account the roles it needs to deploy
# In a real production scenario, you would use more granular roles.
resource "google_project_iam_member" "github_actions_roles" {
  for_each = toset([
    "roles/run.admin",
    "roles/iam.serviceAccountUser",
    "roles/artifactregistry.writer"
  ])

  project = var.gcp_project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

# Allow GitHub Actions to impersonate the service account
resource "google_service_account_iam_binding" "github_actions_wif_binding" {
  service_account_id = google_service_account.github_actions_sa.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repo}"
  ]
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
  deletion_protection = false

  template {
    service_account = google_service_account.cloud_run_sa.email
    containers {
      image = "gcr.io/cloudrun/hello"
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
  depends_on = [google_project_service.apis["cloudbuild.googleapis.com"]]
}

# Grant Cloud Build service account permission to deploy to Cloud Run
resource "google_project_iam_member" "cloudbuild_cloud_run_developer" {
  project = var.gcp_project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
  depends_on = [google_project_service.apis["cloudbuild.googleapis.com"]]
}

data "google_project" "project" {}