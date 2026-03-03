from serpapi import GoogleSearch

KEY = "6dbf95923b3c8a8644208c892b49c3b1018f23618c7745f30b92aaae819d0f29"
name = "Alia Bhatt"

queries = [
    f'"{name}" deepfake site:reddit.com OR site:twitter.com OR site:x.com',
    f'"{name}" deepfake fake AI generated',
    f'"{name}" face swap video',
]

for q in queries:
    r = GoogleSearch({"engine": "google_images", "q": q, "api_key": KEY, "num": 3, "safe": "off"}).get_dict()
    imgs = r.get("images_results", [])
    err = r.get("error", "")
    print(f"Query: {q[:60]}")
    print(f"  Error: {err or 'none'} | Results: {len(imgs)}")
    for img in imgs[:2]:
        print(f"    - [{img.get('source','')}] {img.get('title','')[:50]}")
    print()
