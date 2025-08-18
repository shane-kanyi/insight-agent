variable "gcp_project_id" {
  description = "The GCP project ID to deploy resources into."
  type        = string
}

variable "gcp_region" {
  description = "The GCP region to deploy resources into."
  type        = string
  default     = "us-central1"
}

variable "service_name" {
  description = "The name of the Cloud Run service."
  type        = string
  default     = "insight-agent"
}

variable "github_repo" {
  description = "The GitHub repository in the format 'owner/repo_name'."
  type        = string
  # Example: "my-github-username/insight-agent"
}