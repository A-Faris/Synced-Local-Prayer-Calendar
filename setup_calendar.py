import os, json
from dotenv import load_dotenv

import google.auth
from google.cloud import secretmanager
from google.oauth2 import service_account
from googleapiclient.discovery import build

def get_service_account_credentials(project_id):
    client = secretmanager.SecretManagerServiceClient()
    secret = list(client.list_secrets(parent=f"projects/{project_id}"))[0]
    payload = client.access_secret_version(name=f"{secret.name}/versions/latest").payload.data.decode("UTF-8")
    return service_account.Credentials.from_service_account_info(
        json.loads(payload),
        scopes=["https://www.googleapis.com/auth/calendar"]
    )

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

if __name__ == "__main__":
    load_dotenv()
    CALENDAR_NAMES = os.getenv("CALENDAR_NAME").split(", ")
    TIMEZONE = os.getenv("TIMEZONE", "Europe/London")
    _, project_id = google.auth.default()

    service = build("calendar", "v3", credentials=get_service_account_credentials(project_id))
    
    for CALENDAR_NAME in CALENDAR_NAMES:
        print(f"\n🕌 {CALENDAR_NAME}\n")
        calendar_id = get_calendar_id(service, CALENDAR_NAME, TIMEZONE)
        
        print(f"📅 View Live Calendar: https://calendar.google.com/calendar/embed?src={calendar_id}")
        print(f"🔗 Subscribe to Calendar: https://calendar.google.com/calendar/u/0/r?cid={calendar_id}")
        print(f"🔗 iCal Subscription (for non-Google calendars): https://calendar.google.com/calendar/ical/{calendar_id}/public/basic.ics")
    