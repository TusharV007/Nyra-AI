from serpapi import GoogleSearch

SERPAPI_KEY = "6dbf95923b3c8a8644208c892b49c3b1018f23618c7745f30b92aaae819d0f29"

# Test with a well-known public image
test_image = "https://upload.wikimedia.org/wikipedia/commons/thumb/9/96/Elon_Musk_-_52089866211.jpg/440px-Elon_Musk_-_52089866211.jpg"

params = {
    "engine": "google_reverse_image",
    "image_url": test_image,
    "api_key": SERPAPI_KEY,
}

print("Calling SerpAPI Google Reverse Image Search...")
search = GoogleSearch(params)
data = search.get_dict()

# Check what we got
if "error" in data:
    print(f"SerpAPI Error: {data['error']}")
else:
    matches = data.get("image_results") or data.get("inline_images") or data.get("visual_matches") or []
    print(f"Success! Found {len(matches)} image match(es).")
    for m in matches[:3]:
        print(f"  - {m.get('title', 'No title')} | {m.get('link', m.get('source', 'no link'))}")

print("Keys in response:", list(data.keys()))
