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

def create_calendar_id(service, calendar_name, timezone="Europe/London"):
    calendar_id = service.calendars().insert(body={"summary": calendar_name, "timeZone": timezone}).execute()["id"]
    service.acl().insert(calendarId=calendar_id, body={"role": "reader", "scope": {"type": "default"}}).execute()
    print(f"✅ Created new public calendar: {calendar_id}")
    return calendar_id

def get_calendar_id(service, calendar_name, timezone="Europe/London"):
    calendars = service.calendarList().list().execute().get("items", [])
    for calendar in calendars:
        if calendar_name in calendar["summary"]:
            return calendar["id"]
        
    return create_calendar_id(service, calendar_name, timezone)

def event_exists(service, calendar_id, prayer):
    return bool(service.events().list(
        calendarId=calendar_id,
        timeMin=datetime.combine(date.today(), datetime.min.time()).isoformat() + "Z",
        timeMax=datetime.combine(date.today(), datetime.max.time()).isoformat() + "Z",
        singleEvents=True,
        q=prayer
    ).execute().get("items", []))

def create_event(service, calendar_id, prayer, time):
    if event_exists(service, calendar_id, prayer):
        print(f"⏩ Skipping existing event: {prayer} at {time}")
        return
    
    dt = datetime.combine(date.today(), datetime.strptime(time, "%H:%M").time())
    event = {
        "summary": prayer,
        "start": {"dateTime": dt.isoformat(), "timeZone": "Europe/London"},
        "end": {"dateTime": dt.isoformat(), "timeZone": "Europe/London"},
    }
    created = service.events().insert(calendarId=calendar_id, body=event).execute()
    print("Event created:", created.get('htmlLink'))

def share_calendar(service, calendar_id, email):
    service.acl().insert(calendarId=calendar_id, body={"role": "reader", "scope": {"type": "user", "value": email}}).execute()
    print(f"✅ Calendar is shared with {email}")

if __name__ == "__main__":
    MASJIDS = {"Leeds Grand Mosque": get_LGM_prayer_times}

    service = build('calendar', 'v3', credentials=get_service_account_credentials())

    for masjid, get_prayer_times in MASJIDS.items():
        calendar_name = f"{masjid} Prayer Times"
        print(f"\n🕌 {calendar_name}\n")

        calendar_id = get_calendar_id(service, calendar_name)
        prayer_times = get_prayer_times()
        for prayer, time in prayer_times.items():
            create_event(service, calendar_id, prayer, time)

        print(f"📅 View Live Calendar: https://calendar.google.com/calendar/embed?src={calendar_id}")
        print(f"🔗 Subscribe to Calendar: https://calendar.google.com/calendar/u/0/r?cid={calendar_id}")
        print(f"🔗 iCal Subscription (for non-Google calendars): https://calendar.google.com/calendar/ical/{calendar_id}/public/basic.ics")
