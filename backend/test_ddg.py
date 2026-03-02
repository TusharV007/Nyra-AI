from duckduckgo_search import DDGS

ddgs = DDGS()
print("Test 1:", len(list(ddgs.text("Tushar deepfake", max_results=5))))
print("Test 2:", len(list(ddgs.text("Tushar photo", max_results=5))))
print("Test 3:", len(list(ddgs.text("Tushar", max_results=5))))
