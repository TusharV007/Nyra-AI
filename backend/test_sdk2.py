from realitydefender import RealityDefender
from scraper import REALITY_DEFENDER_API_KEY
import requests

def run():
    print("Testing SDK detect_file...")
    client = RealityDefender(REALITY_DEFENDER_API_KEY)
    
    # Download test image to local file first
    img_resp = requests.get("https://upload.wikimedia.org/wikipedia/commons/a/a2/Tushar_Gandhi_2013-10-02_20-41.jpg")
    with open("test.jpg", "wb") as f:
        f.write(img_resp.content)
        
    print("Image downloaded. Scanning via SDK detect_file...")
    
    try:
        res = client.detect_file("test.jpg")
        print("Detection Result:", res)
    except Exception as e:
        print("SDK Error:", e)

if __name__ == "__main__":
    run()
