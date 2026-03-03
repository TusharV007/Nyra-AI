from dotenv import load_dotenv
load_dotenv()

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from scraper import run_deepfake_scan

app = FastAPI(title="Nyra AI Backend", description="Backend for identity scanning and evidence gathering.")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ScanRequest(BaseModel):
    uid: str
    target_name: Optional[str] = "Anonymous"
    photo_url: Optional[str] = None

@app.post("/api/scan")
async def trigger_scan(request: ScanRequest):
    """
    Performs the AI analysis and returns findings as JSON.
    The Flutter app writes the results to Firestore using its own authenticated Firebase SDK.
    The backend no longer touches Firestore directly, which eliminates the
    'invalid_grant: Invalid JWT Signature' error from the Firebase Admin SDK.
    """
    if not request.uid:
        raise HTTPException(status_code=400, detail="uid is required")
    try:
        findings = await run_deepfake_scan(request.target_name, request.photo_url)
        return {
            "status": "success",
            "message": "Scan completed.",
            "findings_count": len(findings),
            "findings": findings,   # Flutter reads this and saves to Firestore
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
def health_check():
    return {"status": "ok"}
