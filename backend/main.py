from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
from scraper import run_deepfake_scan

app = FastAPI(title="Nyra AI Backend", description="Backend for identity scanning and evidence gathering.")

class ScanRequest(BaseModel):
    uid: str
    target_name: Optional[str] = "Anonymous"
    photo_url: Optional[str] = None

@app.post("/api/scan")
async def trigger_scan(request: ScanRequest):
    try:
        # Trigger the mock scanning utility
        results = await run_deepfake_scan(request.uid, request.target_name, request.photo_url)
        return {"status": "success", "message": "Scan completed.", "findings_count": len(results)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
def health_check():
    return {"status": "ok"}
