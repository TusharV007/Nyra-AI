from serpapi import GoogleSearch

KEY = "6dbf95923b3c8a8644208c892b49c3b1018f23618c7745f30b92aaae819d0f29"
name = "Alia Bhatt"

test_cases = [
    ("google", f'"{name}" site:mrdeepfakes.com', {"safe": "off"}),
    ("google", f'"{name}" deepfake site:reddit.com', {"safe": "off"}),
    ("google", f'"{name}" site:xvideos.com OR site:xnxx.com OR site:spankbang.com', {"safe": "off"}),
    ("bing",   f'"{name}" deepfake', {}),
    ("bing",   f'"{name}" site:mrdeepfakes.com', {}),
]

for engine, query, extra in test_cases:
    params = {"engine": engine, "q": query, "api_key": KEY, "num": 3, **extra}
    r = GoogleSearch(params).get_dict()
    err = r.get("error", "")
    results = r.get("organic_results", [])
    print(f"[{engine}] {query[:65]}")
    print(f"  Error: {err or 'none'} | Results: {len(results)}")
    for item in results[:2]:
        print(f"  -> {item.get('link', '')[:80]}")
    print()
