# Prayer Times to Google Calendar

## Overview

This project scrapes daily prayer times from the Leeds Grand Mosque website and updates a Google Calendar so users can subscribe to a public calendar and view daily prayer schedules on any device.

## Features

- Scrapes prayer times (Beautiful Soup)

- Creates/updates events in Google Calendar (Google Calendar API)

- Deployable as a scheduled job on Google Cloud (Cloud Functions + Cloud Scheduler)

## Setting up the Project

### Setting up GitHub Repository

Create GitHub repository
https://github.com/new

Link your local project to the GitHub repository:

```bash
git config --global user.email "your-email"

git init

git add .

git commit -m "Initial commit"

git remote add origin your-github-url

git branch -M main

git push -u origin main

git status
```

Configure your GitHub email (replace with your own)

Link to your GitHub repository (replace with your own URL)

### Download Python

Download and install the latest version of Python
https://www.python.org/downloads/

(Python version used: 3.13.7)

Verify the installation

`python -V`

### Set up Virtual Environment 

Create a virtual environment

`python -m venv .venv`

Activate the virtual environment

`source .venv/bin/activate`

Deactivate the virtual environment

`deactivate`


## Configuration

Create a `.env` file in the project root containing:

```bash
GOOGLE_API_KEY=your_api_key_here
CALENDAR_ID=your_calendar_id_here
PRAYER_TIMES_URL=https://www.leedsgrandmosque.com/
```

## Run the Project

Install dependencies

`pip install -r requirements.txt`

Run the script locally for testing

`python main.py`

The script will scrape the configured `PRAYER_TIMES_URL` and attempt to update events in the configured calendar.

## Usage

Once deployed, the scheduled function will:

- Scrape prayer times for the current day from the configured `PRAYER_TIMES_URL`

- Create or update events in the configured Google Calendar