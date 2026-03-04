variable "project_id" {
  type        = string
  description = "The ID of the Google Cloud Project where resources will be deployed."
}

variable "region" {
  type        = string
  description = "The GCP region for the Cloud Function and storage resources."
  default     = "us-central1"
}

variable "firestore_location" {
  type        = string
  description = "The location for the Firestore database (must be a valid App Engine location)."
  default     = "nam5"
}

variable "function_name" {
  type        = string
  description = "The name of the Cloud Function."
  default     = "gcp-serverless-api"
}
