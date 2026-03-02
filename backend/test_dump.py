import requests
import json
from scraper import REALITY_DEFENDER_API_KEY

def run():
    headers = {"X-API-KEY": REALITY_DEFENDER_API_KEY, "Content-Type": "application/json"}
    req_url = "https://api.prd.realitydefender.xyz/api/files/aws-presigned"
    resp = requests.post(req_url, headers=headers, json={"fileName": "scraped_image.jpg"})
    
    with open("resp.json", "w") as f:
        json.dump(resp.json(), f, indent=2)

if __name__ == "__main__":
    run()
