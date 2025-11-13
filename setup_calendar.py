from google.cloud import secretmanager
from google.oauth2 import service_account
from googleapiclient.discovery import build
from dotenv import load_dotenv
import os, json

def get_service_account_credentials():
    load_dotenv()
    project_id = os.getenv("GOOGLE_CLOUD_PROJECT")
    client = secretmanager.SecretManagerServiceClient()
    secret = list(client.list_secrets(parent=f"projects/{project_id}"))[0]
    payload = client.access_secret_version(name=f"{secret.name}/versions/latest").payload.data.decode("UTF-8")
    return service_account.Credentials.from_service_account_info(
        json.loads(payload),
        scopes=["https://www.googleapis.com/auth/calendar"]
    )

def get_or_create_calendar(service, CALENDAR_NAME):
    calendars = service.calendarList().list().execute().get("items", [])
    if calendars:
        service.calendars().patch(calendarId=calendars[0]["id"], body={"summary": CALENDAR_NAME}).execute()
        print(f"✅ Updated calendar name to: {CALENDAR_NAME}")
        return calendars[0]["id"]

    calendar_id = service.calendars().insert(body={"summary": CALENDAR_NAME, "timeZone": "Europe/London"}).execute()["id"]
    service.acl().insert(calendarId=calendar_id, body={"role": "reader", "scope": {"type": "default"}}).execute()
    print(f"✅ Created new public calendar: {calendar_id}")
    return calendar_id

def share_calendar(service, calendar_id, email):
    service.acl().insert(calendarId=calendar_id, body={"role": "writer", "scope": {"type": "user", "value": email}}).execute()
    print(f"✅ Calendar is shared with {email}")

if __name__ == "__main__":
    load_dotenv()
    EMAIL = os.getenv("EMAIL")
    CALENDAR_NAME = os.getenv("CALENDAR_NAME")

    service = build("calendar", "v3", credentials=get_service_account_credentials())
    calendar_id = get_or_create_calendar(service, CALENDAR_NAME)
    share_calendar(service, calendar_id, EMAIL)

    print(f"🔗 Subscribe: https://calendar.google.com/calendar/u/0/r?cid={calendar_id}")
