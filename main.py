from bs4 import BeautifulSoup
from dotenv import load_dotenv
from google.oauth2 import service_account
from googleapiclient.discovery import build
from datetime import datetime, date
import requests

import os

def find_prayer_times(url):
    response = requests.get(url)
    soup = BeautifulSoup(response.text, "html.parser")

    prayer_times = {}
    prayer_list = soup.find(class_="prayers-list").find_all("li")
    for prayer in prayer_list:
        name = prayer.find(class_="prayer-name").text.capitalize()
        time = prayer.find(class_="date").text
        prayer_times[name] = time

    return prayer_times

def create_event(prayer, time, CALENDAR_ID):
    SERVICE_ACCOUNT_FILE = 'service-account.json'
    # https://developers.google.com/workspace/calendar/api/auth
    SCOPES = ['https://www.googleapis.com/auth/calendar.events']

    credentials = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE, scopes=SCOPES
    )

    service = build('calendar', 'v3', credentials=credentials)

    hour, minute = map(int, time.split(":"))
    today = date.today()
    start_dt = datetime(today.year, today.month, today.day, hour, minute)

    # https://developers.google.com/resources/api-libraries/documentation/calendar/v3/python/latest/calendar_v3.events.html#insert
    event = {
        "summary": prayer,
        "start": {"dateTime": start_dt.isoformat()},
        "end": {"dateTime": start_dt.isoformat()},
    }

    return service.events().insert(calendarId=CALENDAR_ID, body=event).execute()

if __name__ == "__main__":
    prayer_times = find_prayer_times("https://www.leedsgrandmosque.com/")
    
    load_dotenv()
    CALENDAR_ID = os.getenv("CALENDAR_ID")

    for prayer, time in prayer_times.items():
        event = create_event(prayer, time, CALENDAR_ID)
        print(f"Event created: {event.get('htmlLink')}")