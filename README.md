# Prayer Times to Google Calendar

## Overview

This project scrapes daily prayer times from the Leeds Grand Mosque website and updates a Google Calendar. Users can subscribe to this calendar to view daily prayer schedules on any device.

## Features

- Scrapes prayer times using Beautiful Soup
- Creates events in Google Calendar via the Google Calendar API
- Deployable as a scheduled job on Google Cloud (Cloud Run + Cloud Scheduler)

## 1. Install Required Tools

Download and install the following:
- Git and Git Bash: https://git-scm.com/install/
- Docker Desktop: https://www.docker.com/products/docker-desktop/
- Python (used 3.13.7): https://www.python.org/downloads/

Verify installation:

```bash
git --version
docker --version
python --version
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
GOOGLE_CLOUD_PROJECT="your_project_id"
REGION="your_region"
SA_NAME="your_service_account_name"
SECRET_NAME="your_secret_name"

EMAIL="your_email@example.com"
CALENDAR_NAME="Leeds Grand Mosque Prayer Times"

REPO="prayer-repo"
IMAGE_NAME="prayer-calendar"

SERVICE_NAME="prayer-calendar-job"
SCHEDULE="0 0 * * *"
TIMEZONE="Europe/London"
```

## 5. Set Up Google Cloud Service Account

Run the service account setup script:

```bash
bash setup_sa.sh
```

This will:
- Create the service account (if it doesn’t exist)
- Assign necessary IAM roles
- Create a secret in Secret Manager

## 6. Set Up Google Calendar

Run the calendar setup script:

```bash
python setup_calendar.py
```

This will:
- Create or update the Google Calendar
- Share it with your configured email
- Print the subscription link

## 7. Deploy to Google Cloud

Deploy the project as a scheduled Cloud Run job:

```bash
bash deploy.sh
```

This will:
- Build and push the Docker image
- Deploy or update the Cloud Run job
- Recreate the Cloud Scheduler job to trigger the Cloud Run job

## 8. Run Locally (Optional)

While the virtual environment is active:

```bash
python main.py
```

This will scrape the prayer times and create events in your Google Calendar.
