import requests
from bs4 import BeautifulSoup

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Accept-Language": "en-US,en;q=0.9",
    "Referer": "https://mrdeepfakes.com/",
}

name = "Alia Bhatt"
query = name.replace(" ", "+")
url = f"https://mrdeepfakes.com/?s={query}"

print(f"Fetching: {url}")
resp = requests.get(url, headers=HEADERS, timeout=15)
print(f"Status: {resp.status_code}")

soup = BeautifulSoup(resp.text, "html.parser")

# Try to find video/post cards
cards = soup.select("article") or soup.select(".post") or soup.select(".video-item")
print(f"Found {len(cards)} cards")

for card in cards[:3]:
    title_el = card.select_one("h2, h3, .title, a[title]")
    link_el = card.select_one("a[href]")
    img_el = card.select_one("img")
    print(f"  Title: {title_el.get_text(strip=True)[:60] if title_el else 'N/A'}")
    print(f"  Link:  {link_el['href'] if link_el else 'N/A'}")
    print(f"  Image: {img_el.get('src', img_el.get('data-src', 'N/A'))[:60] if img_el else 'N/A'}")
    print()
