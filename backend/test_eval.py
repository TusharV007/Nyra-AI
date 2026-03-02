import requests
import json
from scraper import REALITY_DEFENDER_API_KEY

def run():
    headers = {"X-API-KEY": REALITY_DEFENDER_API_KEY, "Content-Type": "application/json"}
    with open("resp.json", "r") as f:
        data = json.load(f)
        
    endpoints = [
        "https://api.prd.realitydefender.xyz/api/evaluate",
        "https://api.prd.realitydefender.xyz/api/analyze",
        "https://api.prd.realitydefender.xyz/api/detect",
        "https://api.prd.realitydefender.xyz/api/scan",
        "https://api.prd.realitydefender.xyz/api/process",
        "https://api.prd.realitydefender.xyz/api/files/analyze",
        "https://api.prd.realitydefender.xyz/api/media/analyze",
        "https://api.prd.realitydefender.xyz/api/media/evaluate",
        "https://api.prd.realitydefender.xyz/api/v1/evaluate",
        "https://api.prd.realitydefender.xyz/api/v1/analyze",
    ]
    
    for url in endpoints:
        resp = requests.post(url, headers=headers, json={"fileId": data["mediaId"]})
        print(url, "->", resp.status_code)
        if resp.status_code != 404:
            print("JSON:", resp.text)

if __name__ == "__main__":
    run()
