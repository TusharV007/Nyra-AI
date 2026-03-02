import requests

def test_wiki(query):
    try:
        url = f"https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch={query}&utf8=&format=json"
        headers = {'User-Agent': 'NyraScanner/1.0 (contact@nyra.ai)'}
        response = requests.get(url, headers=headers, timeout=10)
        data = response.json()
        results = data.get('query', {}).get('search', [])
        print(f"Results for '{query}':", len(results))
        for r in results[:2]:
            print(f"- {r['title']}")
    except Exception as e:
        print("Error:", e)

test_wiki("Python programming")
test_wiki("Tushar")
