from serpapi import GoogleSearch

KEY = "6dbf95923b3c8a8644208c892b49c3b1018f23618c7745f30b92aaae819d0f29"
name = "Alia Bhatt"

# Bing Images - less restricted than Google
print("=== Bing Images ===")
r = GoogleSearch({"engine": "bing_images", "q": f'"{name}" deepfake', "api_key": KEY}).get_dict()
err = r.get("error", "")
imgs = r.get("value", [])
print(f"Error: {err or 'none'} | Results: {len(imgs)}")
for i in imgs[:3]:
    print(f"  -> [{i.get('hostPageDomainFriendlyName', '')}] {i.get('name', '')[:50]}")
    print(f"     Image: {i.get('contentUrl', '')[:60]}")
print()

# Reddit deepfake communities via Google
print("=== Reddit Deepfake Communities ===")
r2 = GoogleSearch({"engine": "google", "q": f'"{name}" deepfake site:reddit.com/r/DeepFakeNSFW OR site:reddit.com/r/SFWdeepfakes OR site:reddit.com/r/Bollywood', "api_key": KEY, "safe": "off", "num": 5}).get_dict()
results = r2.get("organic_results", [])
print(f"Results: {len(results)}")
for item in results[:3]:
    print(f"  -> {item.get('link', '')}")
