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
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
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

variable "repo" {
  type        = string
  description = "Artifact Registry repo name"
}

variable "image_name" {
  type        = string
  description = "Docker image name"
}

variable "service_name" {
  type        = string
  description = "Cloud Run Job name"
}

variable "schedule" {
  type        = string
  description = "Cron schedule for Cloud Scheduler"
}

variable "timezone" {
  type        = string
  description = "Time zone for Cloud Scheduler"
  default     = "Europe/London"
}

locals {
  image_uri = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repo}/${var.image_name}"
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

# ============ ARTIFACT REGISTRY ============

resource "google_artifact_registry_repository" "docker_repo" {
  repository_id = var.repo
  format        = "DOCKER"
  location      = var.region

  depends_on = [google_secret_manager_secret_version.sa_key_version]
}

# ============ DOCKER ============

resource "null_resource" "docker_build" {
  provisioner "local-exec" {
    command = "docker build -t ${local.image_uri} ."
  }

  triggers = {
    image_uri       = local.image_uri
    main_hash       = filesha256("${path.module}/main.py")
    dockerfile_hash = filesha256("${path.module}/Dockerfile")
  }
}

resource "null_resource" "docker_push" {
  provisioner "local-exec" {
    command = "docker push ${local.image_uri}"
  }

  depends_on = [
    null_resource.docker_build,
    google_artifact_registry_repository.docker_repo
  ]
}

# ============ CLOUD RUN JOB ============

resource "google_cloud_run_v2_job" "prayer_scraper_job" {
  name     = var.service_name
  location = var.region
  deletion_protection = false

  template {
    template {
      containers {
        image = local.image_uri
      }
      service_account = google_service_account.prayer_scraper_sa.email
    }
  }

  depends_on = [null_resource.docker_push]
}

# ============ CLOUD SCHEDULER JOB ============

resource "google_cloud_scheduler_job" "prayer_scraper_scheduler" {
  name     = "${var.service_name}-scheduler"
  schedule = var.schedule
  time_zone = var.timezone
  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${var.service_name}:run"
    oauth_token {
      service_account_email = google_service_account.prayer_scraper_sa.email
    }
  }

  depends_on = [google_cloud_run_v2_job.prayer_scraper_job]
}
