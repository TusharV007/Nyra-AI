import requests

REALITY_DEFENDER_API_KEY = "rd_60b48a81e8c77a7e_112ab69952ca9c8e5ccfae03ba59f699"

def test_auth(headers):
    req_url = "https://api.prd.realitydefender.xyz/api/files/aws-presigned"
    resp = requests.post(req_url, headers=headers, json={"fileName": "scraped_image.jpg"})
    print(list(headers.keys())[0], "-> Status:", resp.status_code, "JSON:", resp.text)

if __name__ == "__main__":
    test_auth({"X-API-KEY": REALITY_DEFENDER_API_KEY, "Content-Type": "application/json"})
    test_auth({"x-api-key": REALITY_DEFENDER_API_KEY, "Content-Type": "application/json"})
    test_auth({"Authorization": f"Bearer {REALITY_DEFENDER_API_KEY}", "Content-Type": "application/json"})
    test_auth({"Authorization": REALITY_DEFENDER_API_KEY, "Content-Type": "application/json"})
    test_auth({"ApiKey": REALITY_DEFENDER_API_KEY, "Content-Type": "application/json"})
