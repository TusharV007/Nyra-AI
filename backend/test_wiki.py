import requests

HEADERS = {'User-Agent': 'NyraScanner/1.0'}

# Test Wikipedia image search
resp = requests.get('https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=Elon+Musk&utf8=&format=json', headers=HEADERS, timeout=10)
pages = resp.json().get('query', {}).get('search', [])
print(f'Wikipedia search: found {len(pages)} pages')

if pages:
    title = pages[0]['title']
    print(f'Top result: {title}')
    img_resp = requests.get(f'https://en.wikipedia.org/w/api.php?action=query&titles={title}&prop=images&format=json&imlimit=10', headers=HEADERS, timeout=10)
    for _, p in img_resp.json().get('query', {}).get('pages', {}).items():
        for img in p.get('images', []):
            filename = img['title']
            if any(ext in filename.lower() for ext in ['.jpg', '.jpeg', '.png']):
                # Get the actual URL
                file_resp = requests.get(f'https://en.wikipedia.org/w/api.php?action=query&titles={filename}&prop=imageinfo&iiprop=url&format=json', headers=HEADERS, timeout=10)
                for _, fp in file_resp.json().get('query', {}).get('pages', {}).items():
                    urls = fp.get('imageinfo', [])
                    if urls:
                        print(f"Image URL: {urls[0]['url']}")
                        break
                break
else:
    print("No Wikipedia results found")
print("Test complete.")
