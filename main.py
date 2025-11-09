from bs4 import BeautifulSoup
import requests

response = requests.get("https://www.leedsgrandmosque.com/")
soup = BeautifulSoup(response.text, "html.parser")

prayer_times = {}
prayer_list = soup.find(class_="prayers-list").find_all("li")
for prayer in prayer_list:
    name = prayer.find(class_="prayer-name").text.capitalize()
    time = prayer.find(class_="date").text
    prayer_times[name] = time

print(prayer_times)