# Google Cloud Provider Configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required Google Cloud APIs
resource "google_project_service" "gcp_apis" {
  for_each = toset([
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "firestore.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com"
  ])
  service            = each.key
  disable_on_destroy = false
}

# This is required as some APIs take few seconds to be fully enabled
resource "time_sleep" "wait_30_s" {
  depends_on      = [google_project_service.gcp_apis]
  create_duration = "30s"
}

# Provision Firestore in Native Mode
resource "google_firestore_database" "database" {
  count       = var.create_firestore_database ? 1 : 0
  name        = "(default)"
  location_id = var.firestore_location
  type        = "FIRESTORE_NATIVE"
  depends_on  = [google_project_service.gcp_apis]
}

# Package and Upload Source Code
resource "google_storage_bucket" "source_bucket" {
  name                        = "${var.project_id}-source-code"
  location                    = var.region
  uniform_bucket_level_access = true
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "./src"
  output_path = "./tmp/api_source.zip"
}

resource "google_storage_bucket_object" "code_archive" {
  name   = "source.zip#${data.archive_file.lambda_zip.output_md5}"
  bucket = google_storage_bucket.source_bucket.name
  source = data.archive_file.lambda_zip.output_path
}

# Deploy Google Cloud Function
resource "google_cloudfunctions2_function" "serverless_api" {
  name     = var.function_name
  location = var.region

  depends_on = [time_sleep.wait_30_s]

  build_config {
    runtime     = "python311"
    entry_point = "handler"
    source {
      storage_source {
        bucket = google_storage_bucket.source_bucket.name
        object = google_storage_bucket_object.code_archive.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256Mi"
    timeout_seconds    = 60
  }
}

# Public Access Configuration
resource "google_cloud_run_service_iam_member" "allow_public" {
  location = google_cloudfunctions2_function.serverless_api.location
  service  = google_cloudfunctions2_function.serverless_api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
