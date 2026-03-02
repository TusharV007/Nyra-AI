from realitydefender import RealityDefender
from scraper import REALITY_DEFENDER_API_KEY
import requests

def run():
    print("Testing SDK...")
    # Initialize the client
    client = RealityDefender(REALITY_DEFENDER_API_KEY)
    
    # Download test image to local file first
    img_resp = requests.get("https://upload.wikimedia.org/wikipedia/commons/a/a2/Tushar_Gandhi_2013-10-02_20-41.jpg")
    with open("test.jpg", "wb") as f:
        f.write(img_resp.content)
        
    print("Image downloaded. Scanning via SDK...")
    
    # Let's inspect the client to see what methods it has
    import inspect
    print(dir(client))
    
    # Attempting common signature patterns:
    try:
        if hasattr(client, "images"):
            res = client.images.analyze("test.jpg")
        elif hasattr(client, "media"):
            res = client.media.analyze("test.jpg")
        elif hasattr(client, "scan"):
            res = client.scan("test.jpg")
        else:
            print("Unknown SDK structure.")
            res = None
        print("Result:", res)
    except Exception as e:
        print("SDK Error:", e)

if __name__ == "__main__":
    run()
