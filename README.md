# Leeds Grand Mosque Prayer Times to Google Calendar
## Overview

Muslims pray five times a day and often check the prayer times multiple times throughout the day. By making this process more convenient, we can save time and plan our days more effectively around prayers. This project integrates Leeds Grand Mosque prayer times with a public Google Calendar, allowing Muslims to easily add the daily schedule to their personal calendars.

## Features

- Scrapes daily prayer times from the Leeds Grand Mosque website using Beautiful Soup

- Integrates with the Google Calendar API to update events automatically

- Runs daily on Google Cloud Platform (GCP) using Cloud Functions and Cloud Scheduler

- Provides a public calendar users can subscribe to from any device

## Setting up the Project

### Setting up GitHub Repository

Create GitHub repository
https://github.com/new

Link your local project to the GitHub repository:

Configure your GitHub email (replace with your own):

`git config --global user.email "your-email"`

Initialise a local repository:

`git init`

Add all project files:

`git add .`

Commit your changes:

`git commit -m "Initial commit"`

Link to your GitHub repository (replace with your own URL):

`git remote add origin your-github-url`

Set the main branch:

`git branch -M main`

Push your code to GitHub:

`git push -u origin main`

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

Create a .env file in the project root and add the following environment variables:

```
GOOGLE_API_KEY=your_api_key_here
CALENDAR_ID=your_calendar_id_here
PRAYER_TIMES_URL=https://www.leedsgrandmosque.com/
```

## Run the Project

Install dependencies

`pip install -r requirements.txt`

Run the script locally for testing

`python main.py`

## Deployment on GCP


## Usage

Once deployed, the function:

- Scrapes prayer times for the current day from the Leeds Grand Mosque website

- Updates the prayer times in the connected Google Calendar
