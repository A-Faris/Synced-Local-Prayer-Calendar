terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ============ VARIABLES ============

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "europe-west2"
}

variable "sa_name" {
  description = "Service account name"
  type        = string
  default     = "prayer-scraper-sa"
}

variable "secret_name" {
  description = "Secret Manager secret name"
  type        = string
  default     = "service_account_secret"
}

# ============ ENABLE APIS ============

resource "google_project_service" "secretmanager" {
  service = "secretmanager.googleapis.com"
}

resource "google_project_service" "iam" {
  service = "iam.googleapis.com"
}

resource "google_project_service" "run" {
  service = "run.googleapis.com"
}

resource "google_project_service" "cloudscheduler" {
  service = "cloudscheduler.googleapis.com"
}

# ============ SERVICE ACCOUNT ============

resource "google_service_account" "prayer_scraper_sa" {
  account_id   = var.sa_name
  display_name = "Prayer Scraper Cloud Run Job Service Account"
  description  = "Service account for prayer times scraper job"
  create_ignore_already_exists = true

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    google_project_service.iam
  ]
}

# ============ IAM ROLES ============

resource "google_project_iam_member" "run_jobs_executor" {
  project = var.project_id
  role    = "roles/run.jobsExecutor"
  member  = "serviceAccount:${google_service_account.prayer_scraper_sa.email}"

  depends_on = [google_service_account.prayer_scraper_sa]
}

resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.prayer_scraper_sa.email}"

  depends_on = [google_service_account.prayer_scraper_sa]
}

resource "google_project_iam_member" "secret_viewer" {
  project = var.project_id
  role    = "roles/secretmanager.viewer"
  member  = "serviceAccount:${google_service_account.prayer_scraper_sa.email}"

  depends_on = [google_service_account.prayer_scraper_sa]
}

resource "google_project_iam_member" "run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.prayer_scraper_sa.email}"

  depends_on = [google_service_account.prayer_scraper_sa]
}

# ============ SERVICE ACCOUNT KEY ============

resource "google_service_account_key" "prayer_scraper_key" {
  service_account_id = google_service_account.prayer_scraper_sa.name

  keepers = {
    sa_email = google_service_account.prayer_scraper_sa.email
  }
}

# ============ SECRET MANAGER ============

resource "google_secret_manager_secret" "sa_key" {
  secret_id = var.secret_name

  replication {
    auto {}
  }

  depends_on = [
    google_project_service.secretmanager
  ]
}

resource "google_secret_manager_secret_version" "sa_key_version" {
  secret      = google_secret_manager_secret.sa_key.id
  secret_data = base64decode(google_service_account_key.prayer_scraper_key.private_key)

  depends_on = [
    google_secret_manager_secret.sa_key,
    google_service_account_key.prayer_scraper_key
  ]
}
