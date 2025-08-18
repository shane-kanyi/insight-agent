output "cloud_run_service_url" {
  description = "The URL of the deployed Cloud Run service."
  value       = google_cloud_run_v2_service.insight_agent.uri
}

output "workload_identity_provider" {
  description = "The resource name of the Workload Identity Provider for GitHub Actions."
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}

output "github_actions_service_account_email" {
  description = "The email address of the service account for GitHub Actions."
  value       = google_service_account.github_actions_sa.email
}