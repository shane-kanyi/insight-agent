output "cloud_run_service_url" {
  description = "The URL of the deployed Cloud Run service."
  value       = google_cloud_run_v2_service.insight_agent.uri
}