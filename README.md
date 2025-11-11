# Prayer Times to Google Calendar

## Overview

This project scrapes daily prayer times from the Leeds Grand Mosque website and updates a Google Calendar. Users can subscribe to this calendar to view daily prayer schedules on any device.#

## Features

- Scrapes prayer times using Beautiful Soup

- Creates events in Google Calendar via the Google Calendar API

- Deployable as a scheduled job on Google Cloud (Cloud Run + Cloud Scheduler)

## Setting up the Project

### Setting up GitHub Repository

Create GitHub repository
https://github.com/new

Link your local project to the GitHub repository:

```bash
git config --global user.email "your-email@example.com"

git init

git add .

git commit -m "Initial commit"

git remote add origin <your-github-url>

git branch -M main

git push -u origin main

git status
```

Replace "your-email@example.com" and <your-github-url> with your details.

### Download Python

Download and install the latest version of Python: https://www.python.org/downloads/
(Python version used: 3.13.7)

Verify installation:

```bash
python --version
```

### Install Docker

Download Docker Desktop: https://www.docker.com/products/docker-desktop/

Verify installation:

```bash
docker --version
```

### Create Virtual Environment 

```bash
python -m venv .venv        # Create virtual environment
source .venv/bin/activate   # Activate the environment
deactivate                  # Deactivate the environment
```

## Configuration

Create a `.env` file in the project root containing:

```bash
CALENDAR_ID="your_calendar_id_here"
PROJECT_ID="your_project_id_here"
SECRET_NAME="your_secret_name_here"
```

Make sure your service account secret exists in Google Secret Manager and has permission to access the calendar.

## Run the Project Locally

Activate virtual environment then install dependencies

```bash
pip install -r requirements.txt
```

Run the script locally for testing

```bash
python main.py
```

This will scrape the prayer times and create events in your Google Calendar.

## Usage

Once deployed, the scheduled function will:

- Scrape prayer times for the current day

- Create events in the configured Google Calendar