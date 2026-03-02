import requests
from scraper import REALITY_DEFENDER_API_KEY

def run():
    print("Key:", REALITY_DEFENDER_API_KEY)
    headers = {"X-API-KEY": REALITY_DEFENDER_API_KEY, "Content-Type": "application/json"}
    req_url = "https://api.prd.realitydefender.xyz/api/files/aws-presigned"
    resp = requests.post(req_url, headers=headers, json={"fileName": "scraped_image.jpg"})
    print("Presigned status:", resp.status_code)
    print("Presigned JSON:", resp.json())
    
    upload_url = resp.json().get("url")
    file_id = resp.json().get("fileId")
    print("upload_url:", upload_url)
    
    # Download test image
    img_resp = requests.get("https://upload.wikimedia.org/wikipedia/commons/a/a2/Tushar_Gandhi_2013-10-02_20-41.jpg")
    print("img get:", img_resp.status_code)
    
    put_resp = requests.put(upload_url, data=img_resp.content)
    print("PUT AWS:", put_resp.status_code)
    
    eval_url = "https://api.prd.realitydefender.xyz/api/evaluate"
    print("Eval POSTing...")
    eval_resp = requests.post(eval_url, headers=headers, json={"fileId": file_id})
    print("Eval Status:", eval_resp.status_code)
    print("Eval JSON:", eval_resp.json())

if __name__ == "__main__":
    run()
