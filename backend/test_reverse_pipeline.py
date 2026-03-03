import requests
from serpapi import GoogleSearch

KEY = "6dbf95923b3c8a8644208c892b49c3b1018f23618c7745f30b92aaae819d0f29"

# Step 1: Download a test image
test_src = "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8e/Alia_Bhatt_at_the_premiere_of_Gangubai_Kathiawadi_%28cropped%29.jpg/440px-Alia_Bhatt_at_the_premiere_of_Gangubai_Kathiawadi_%28cropped%29.jpg"
print("Downloading test image...")
img = requests.get(test_src, timeout=15)
print(f"Downloaded {len(img.content)} bytes")

# Step 2: Upload to catbox.moe
print("Uploading to catbox.moe...")
resp = requests.post(
    "https://catbox.moe/user/api.php",
    data={"reqtype": "fileupload", "userhash": ""},
    files={"fileToUpload": ("photo.jpg", img.content, "image/jpeg")},
    timeout=30,
)
public_url = resp.text.strip()
print(f"Public URL: {public_url}")

if not public_url.startswith("https://"):
    print("Upload failed.")
else:
    # Step 3: Reverse image search
    print("Running Google Reverse Image Search...")
    r = GoogleSearch({"engine": "google_reverse_image", "image_url": public_url, "api_key": KEY}).get_dict()
    matches = r.get("image_results") or r.get("inline_images") or r.get("visual_matches") or []
    err = r.get("error", "")
    print(f"Error: {err or 'none'} | Matches: {len(matches)}")
    for m in matches[:3]:
        print(f"  - [{m.get('source', m.get('link',''))}] {m.get('title','')[:60]}")
