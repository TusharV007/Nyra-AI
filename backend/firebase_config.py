import os
import firebase_admin
from firebase_admin import credentials

def initialize_firebase():
    if not firebase_admin._apps:
        key_path = os.path.join(os.path.dirname(__file__), 'serviceAccountKey.json')
        
        if os.path.exists(key_path):
            try:
                cred = credentials.Certificate(key_path)
                firebase_admin.initialize_app(cred)
                print("Firebase Admin Initialized via serviceAccountKey.json.")
            except Exception as e:
                print(f"Failed to initialize via serviceAccountKey.json: {e}")
        else:
            print("=========================================================")
            print("WARNING: serviceAccountKey.json not found in the backend!")
            print("The backend will crash with a 403 error on Firestore writes.")
            print("Please download it from Firebase Console > Project Settings > Service Accounts")
            print("and place it at z:\\Nyra AI\\backend\\serviceAccountKey.json")
            print("=========================================================")
            
            # Fallback to ADC just to keep the server alive
            try:
                cred = credentials.ApplicationDefault()
                firebase_admin.initialize_app(cred, {
                    'projectId': 'nyraai-2d11f',
                })
            except Exception as e:
                pass
