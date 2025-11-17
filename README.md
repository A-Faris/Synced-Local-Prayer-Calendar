# Prayer Times to Google Calendar

## Overview

This project scrapes daily prayer times from the Leeds Grand Mosque website and updates a Google Calendar. Users can subscribe to this calendar to view daily prayer schedules on any device.

## Features

- Scrapes prayer times using Beautiful Soup
- Creates events in Google Calendar via the Google Calendar API
- Deployable as a scheduled job on Google Cloud (Cloud Run + Cloud Scheduler)

## Architecture Diagram

<img width="1698" height="1301" alt="Prayer Times Architecture Diagram" src="https://github.com/user-attachments/assets/037dcbaa-4ffa-45f7-bfd8-653b5d86821e" />

## 1. Install Required Tools

Download and install the following:
- Git and Git Bash: https://git-scm.com/install/
- Docker Desktop: https://www.docker.com/products/docker-desktop/
- Python (used 3.13.7): https://www.python.org/downloads/
- Google Cloud CLI: https://docs.cloud.google.com/sdk/docs/install-sdk
- Terraform: https://developer.hashicorp.com/terraform/install

Verify installation:

```bash
git --version
docker --version
python --version
gcloud --version
terraform --version
```

## 2. GitHub Repository

Create a GitHub repository: https://github.com/new

Link your local project to the GitHub repository:

```bash
git config --global user.email "your-email@example.com"
git init
git add .
git commit -m "Initial commit"
git remote add origin your-github-url
git branch -M main
git push -u origin main
git status
```

Replace `"your-email@example.com"` and `your-github-url` with your own details.

## 3. Create Virtual Environment 

Create and activate a virtual environment, then install dependencies:

```bash
python -m venv .venv
source .venv/Scripts/activate   # Activate the environment
pip install -r requirements.txt
deactivate                  # Deactivate the environment
```

## 4. Configuration

Create a `.env` file in the project root with the following variables:

```bash
EMAIL="your_email@example.com"
CALENDAR_NAME="Masjid Prayer Times"
```

Create a `terraform.tfvars` file in the project root with the following variables:

```hcl
project_id  = "your_project_id"
region      = "your_region"
sa_name     = "your_service_account_name"
secret_name = "your_secret_name"
repo        = "your_repo_name"
image_name  = "your_image_name"
service_name= "your_service_name"
schedule    = "* * * * *"
timezone    = "your_timezone"
```

## 5. Authenticate Google Cloud CLI

Before running any setup or deployment scripts, authenticate and set your project:

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
gcloud config get-value project
```

Replace `YOUR_PROJECT_ID` with your details.

## 6. Deploy Google Cloud Infrastructure with Terraform

Run the terraform script:

```bash
terraform plan
terraform apply
```

This will:
- Create the service account
- Assign necessary IAM roles
- Store service account key in Secret Manager
- Build and push the Docker image to Artifact Registry
- Create the Cloud Run job
- Create the Cloud Scheduler to trigger the Cloud Run job

## 7. Set Up Google Calendar

Run the calendar setup script:

```bash
python setup_calendar.py
```

This will:
- Create or update the Google Calendar
- Share it with your configured email
- Print the subscription link

## 8. Test the Project

### 8.1 Run Locally

Activate the virtual environment and run the script:

```bash
source .venv/bin/activate
python main.py
```

### 8.2 Trigger Cloud Run Job Manually

You can execute the scheduled Cloud Run job anytime using the `.env` variables:

```bash
source .env
gcloud run jobs execute $SERVICE_NAME \
  --region $REGION \
  --project $PROJECT_ID
```

These will scrape the prayer times and create events in your Google Calendar.

- **View Live Calendar:** [Open Calendar](https://calendar.google.com/calendar/embed?src=80110e3124bdedfb7a61d57c33bfd69a3a2ee799c89ff186a3a5ee5850edf0bc%40group.calendar.google.com&ctz=Europe%2FLondon)
- **Subscribe to Calendar:** [Subscribe Link](https://calendar.google.com/calendar/u/0/r?cid=80110e3124bdedfb7a61d57c33bfd69a3a2ee799c89ff186a3a5ee5850edf0bc@group.calendar.google.com)
- **iCal Subscription (for non-Google calendars):** [Download .ics](https://calendar.google.com/calendar/ical/80110e3124bdedfb7a61d57c33bfd69a3a2ee799c89ff186a3a5ee5850edf0bc%40group.calendar.google.com/public/basic.ics)