import requests

r = requests.post(
    "http://127.0.0.1:8000/api/scan",
    json={
        "uid": "test_uid_debug",
        "target_name": "Test Person",
        "photo_url": "https://firebasestorage.googleapis.com/v0/b/nyraai-2d11f.appspot.com/o/test.jpg?alt=media"
    },
    timeout=60
)
print("Status:", r.status_code)
print("Body:", r.text[:500])
