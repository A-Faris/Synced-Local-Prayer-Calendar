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

Verify installation:

```bash
git --version
docker --version
python --version
gcloud --version
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
source .venv/bin/activate   # Activate the environment
pip install -r requirements.txt
deactivate                  # Deactivate the environment
```

## 4. Configuration

Create a `.env` file in the project root with the following variables:

```bash
PROJECT_ID="your_project_id"
REGION="your_region"
SA_NAME="your_service_account_name"
SECRET_NAME="your_secret_name"

EMAIL="your_email@example.com"
CALENDAR_NAME="Masjid Prayer Times"

REPO="prayer-repo"
IMAGE_NAME="prayer-calendar"

SERVICE_NAME="prayer-calendar"
SCHEDULE="0 0 * * *"
TIMEZONE="Europe/London"
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

## 6. Set Up Google Cloud Service Account

Run the service account setup script:

```bash
bash setup_sa.sh
```

This will:
- Create the service account (if it doesn’t exist)
- Assign necessary IAM roles
- Create a secret in Secret Manager

## 7. Set Up Google Calendar

Run the calendar setup script:

```bash
python setup_calendar.py
```

This will:
- Create or update the Google Calendar
- Share it with your configured email
- Print the subscription link

## 8. Deploy to Google Cloud

Deploy the project as a scheduled Cloud Run job:

```bash
bash deploy.sh
```

This will:
- Build and push the Docker image
- Deploy or update the Cloud Run job
- Recreate the Cloud Scheduler job to trigger the Cloud Run job

## 9. Test the Project

### 9.1 Run Locally

Activate the virtual environment and run the script:

```bash
source .venv/bin/activate
python main.py
```

### 9.2 Trigger Cloud Run Job Manually

You can execute the scheduled Cloud Run job anytime using the `.env` variables:

```bash
source .env
gcloud run jobs execute $SERVICE_NAME \
  --region $REGION \
  --project $PROJECT_ID
```

These will scrape the prayer times and create events in your Google Calendar.

## Google Calendar Links

You can view or subscribe to the Leeds Grand Mosque Prayer Times calendar:

- **View Live Calendar:** [Open Calendar](https://calendar.google.com/calendar/u/0/embed?src=3b62801c6ae1b791769131be4e222cb93fcb59a55e997cd4a6a2b1bed5e86253@group.calendar.google.com&ctz=Europe/London)
- **Subscribe to Calendar:** [Subscribe Link](https://calendar.google.com/calendar/u/0/r?cid=3b62801c6ae1b791769131be4e222cb93fcb59a55e997cd4a6a2b1bed5e86253@group.calendar.google.com)
- **iCal Subscription:** [Download .ics](https://calendar.google.com/calendar/ical/3b62801c6ae1b791769131be4e222cb93fcb59a55e997cd4a6a2b1bed5e86253%40group.calendar.google.com/public/basic.ics)
