from google.cloud.api_keys_v2 import Key
from bs4 import BeautifulSoup
from dotenv import load_dotenv
import requests

from google.cloud import api_keys_v2
import os

def find_prayer_times(soup):
    prayer_times = {}
    prayer_list = soup.find(class_="prayers-list").find_all("li")
    for prayer in prayer_list:
        name = prayer.find(class_="prayer-name").text.capitalize()
        time = prayer.find(class_="date").text
        prayer_times[name] = time

    return prayer_times

def restrict_api_key_http(project_id: str, key_id: str) -> Key:
    # template from https://cloud.google.com/docs/authentication/api-keys?sjid=3473226570899666805-EU#python_2
    """
    Restricts an API key. To restrict the websites that can use your API key,
    you add one or more HTTP referrer restrictions.

    TODO(Developer): Replace the variables before running this sample.

    Args:
        project_id: Google Cloud project id.
        key_id: ID of the key to restrict. This ID is auto-created during key creation.
            This is different from the key string. To obtain the key_id,
            you can also use the lookup api: client.lookup_key()

    Returns:
        response: Returns the updated API Key.
    """

    # Create the API Keys client.
    client = api_keys_v2.ApiKeysClient()

    # Restrict the API key usage to specific websites by adding them to the list of allowed_referrers.
    browser_key_restrictions = api_keys_v2.BrowserKeyRestrictions()
    browser_key_restrictions.allowed_referrers = ["https://www.leedsgrandmosque.com/"]

    # Set the API restriction.
    # For more information on API key restriction, see:
    # https://cloud.google.com/docs/authentication/api-keys
    restrictions = api_keys_v2.Restrictions()
    restrictions.browser_key_restrictions = browser_key_restrictions

    key = api_keys_v2.Key()
    key.name = f"projects/{project_id}/locations/global/keys/{key_id}"
    key.restrictions = restrictions

    # Initialize request and set arguments.
    request = api_keys_v2.UpdateKeyRequest()
    request.key = key
    request.update_mask = "restrictions"

    # Make the request and wait for the operation to complete.
    response = client.update_key(request=request).result()

    print(f"Successfully updated the API key: {response.name}")
    # Use response.key_string to authenticate.
    return response

if __name__ == "__main__":
    response = requests.get("https://www.leedsgrandmosque.com/")
    soup = BeautifulSoup(response.text, "html.parser")

    prayer_times = find_prayer_times(soup)
    
    load_dotenv()
    
    # Example usage of restrict_api_key_http
    project_id = os.getenv("PROJECT_ID")
    key_id = os.getenv("KEY_ID")
    restrict_api_key_http(project_id, key_id)