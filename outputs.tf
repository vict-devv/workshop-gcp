# 1. The primary API Gateway / Trigger URL
output "api_endpoint" {
  description = "The public URL of your Serverless CRUD API."
  value       = google_cloudfunctions2_function.serverless_api.service_config[0].uri
}

# 2. Project Confirmation
output "gcp_project_id" {
  description = "The Project ID where resources were deployed."
  value       = var.project_id
}

# 3. Deployment Region
output "deployment_region" {
  description = "The region used for the Cloud Function deployment."
  value       = google_cloudfunctions2_function.serverless_api.location
}

# 4. Function URI (Cloud Run service name)
output "function_service_name" {
  description = "The underlying Cloud Run service name for the Function."
  value       = google_cloudfunctions2_function.serverless_api.name
}