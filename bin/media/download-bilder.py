from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from bs4 import BeautifulSoup
import requests
import os
from urllib.parse import urljoin

# Benutzer gibt die URL ein
url = input("Gib die URL der Webseite ein: ").strip()

# Set up Selenium WebDriver
options = Options()
options.add_argument("--headless")  # Ohne GUI starten
options.add_argument("--disable-gpu")
options.add_argument("--no-sandbox")

service = Service("/usr/bin/chromedriver")  # Falls du Windows nutzt: Service("C:/chromedriver/chromedriver.exe")
driver = webdriver.Chrome(service=service, options=options)

# Webseite laden
driver.get(url)

# HTML parsen
soup = BeautifulSoup(driver.page_source, "html.parser")

driver.quit()

# Ordner für Bilder erstellen
if not os.path.exists("bilder"):
    os.makedirs("bilder")

# Alle <img>-Tags finden und Bilder speichern
for img in soup.find_all("img"):
    img_url = img.get("src")
    if img_url:
        img_url = urljoin(url, img_url)  # Relativen Pfad in absoluten Pfad umwandeln
        img_data = requests.get(img_url).content
        with open(os.path.join("bilder", os.path.basename(img_url)), "wb") as f:
            f.write(img_data)

# WebP-Bilder finden und herunterladen
for source in soup.find_all("source"):
    srcset = source.get("srcset")
    if srcset and ".webp" in srcset:
        webp_url = urljoin(url, srcset.split()[0])  # Erste URL aus dem srcset nehmen
        if webp_url.startswith("http"):
            webp_data = requests.get(webp_url).content
            with open(os.path.join("bilder", os.path.basename(webp_url)), "wb") as f:
                f.write(webp_data)

print("Die Bilder sind jetzt im Ordner \"bilder\".")

