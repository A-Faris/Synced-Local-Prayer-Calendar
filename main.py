import json
import requests
from bs4 import BeautifulSoup
from datetime import datetime, date

import google.auth
from google.cloud import secretmanager
from google.oauth2 import service_account
from googleapiclient.discovery import build

def get_service_account_credentials():
    _, project_id = google.auth.default()
    client = secretmanager.SecretManagerServiceClient()
    secret = list(client.list_secrets(parent=f"projects/{project_id}"))[0]
    payload = client.access_secret_version(
        name=f"{secret.name}/versions/latest"
    ).payload.data.decode("UTF-8")
    
    return service_account.Credentials.from_service_account_info(
        json.loads(payload),
        scopes=["https://www.googleapis.com/auth/calendar"]
    )

def get_LGM_prayer_times():
    soup = BeautifulSoup(requests.get("https://www.leedsgrandmosque.com/").text, "html.parser")
    return {
        prayer.find(class_="prayer-name").text.capitalize():
        prayer.find(class_="date").text
        for prayer in soup.find(class_="prayers-list").find_all("li")
    }

def create_event(service, calendar_id, prayer, time):
    dt = datetime.combine(date.today(), datetime.strptime(time, "%H:%M").time())
    event = {
        "summary": prayer,
        "start": {"dateTime": dt.isoformat(), "timeZone": "Europe/London"},
        "end": {"dateTime": dt.isoformat(), "timeZone": "Europe/London"},
    }
    created = service.events().insert(calendarId=calendar_id, body=event).execute()
    print("Event created:", created.get('htmlLink'))

if __name__ == "__main__":
    service = build('calendar', 'v3', credentials=get_service_account_credentials())

    calendars = service.calendarList().list().execute().get('items', [])
    for calendar in calendars:
        if calendar['summary'] == "Leeds Grand Mosque Prayer Times":
            for prayer, time in get_LGM_prayer_times().items():
                create_event(service, calendar['id'], prayer, time)