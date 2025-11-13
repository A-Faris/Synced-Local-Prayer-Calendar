import requests
from bs4 import BeautifulSoup
from datetime import datetime, date
from dotenv import load_dotenv
from google.cloud import secretmanager
from google.oauth2 import service_account
from googleapiclient.discovery import build

import os, json

def get_service_account_credentials():
    load_dotenv()
    project_id = os.getenv("GOOGLE_CLOUD_PROJECT")
    client = secretmanager.SecretManagerServiceClient()
    secret = list(client.list_secrets(parent=f"projects/{project_id}"))[0]
    payload = client.access_secret_version(
        name=f"{secret.name}/versions/latest"
    ).payload.data.decode("UTF-8")

    return service_account.Credentials.from_service_account_info(
        json.loads(payload),
        scopes=["https://www.googleapis.com/auth/calendar"]
    )

def find_prayer_times(url):
    soup = BeautifulSoup(requests.get(url).text, "html.parser")
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

    calendar_id = service.calendarList().list().execute().get('items', [])[0]['id']

    for prayer, time in find_prayer_times("https://www.leedsgrandmosque.com/").items():
        create_event(service, calendar_id, prayer, time)

    print(f"🔗 Subscribe to this calendar: https://calendar.google.com/calendar/u/0/r?cid={calendar_id}")
