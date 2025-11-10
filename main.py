from bs4 import BeautifulSoup
from dotenv import load_dotenv
from google.oauth2 import service_account
from googleapiclient.discovery import build
import requests

import os

def find_prayer_times(soup):
    prayer_times = {}
    prayer_list = soup.find(class_="prayers-list").find_all("li")
    for prayer in prayer_list:
        name = prayer.find(class_="prayer-name").text.capitalize()
        time = prayer.find(class_="date").text
        prayer_times[name] = time

    return prayer_times

def create_event(prayer_times, CALENDAR_ID):    
    SERVICE_ACCOUNT_FILE = 'service-account.json'
    SCOPES = ['https://www.googleapis.com/auth/calendar.events']

    credentials = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE, scopes=SCOPES
    )

    service = build('calendar', 'v3', credentials=credentials)

    event = {
        "summary": "Sample Event",
        "start": {"date": "2025-11-10"},
        "end": {"date": "2025-11-11"},
    }

    created_event = service.events().insert(calendarId=CALENDAR_ID, body=event).execute()
    print(f"Event created: {created_event.get('htmlLink')}")

if __name__ == "__main__":
    response = requests.get("https://www.leedsgrandmosque.com/")
    soup = BeautifulSoup(response.text, "html.parser")

    prayer_times = find_prayer_times(soup)  
    
    load_dotenv()
    CALENDAR_ID = os.getenv("CALENDAR_ID")

    create_event(prayer_times, CALENDAR_ID)