# Nyra AI — Prompt Log

---

## Prompt 1 — Firebase Auth (Login & Register)

| Field              | Details                                                  |
| ------------------ | -------------------------------------------------------- |
| **Date**           | Feb 2026                                                 |
| **Category**       | Authentication                                           |
| **Model**          | Antigravity (Gemini)                                     |
| **Files Affected** | `main.dart`, `login_screen.dart`, `register_screen.dart` |

**Prompt:**

> Build a Flutter login screen and register screen using Firebase Email & Password authentication. Include an `AuthWrapper` that listens to `FirebaseAuth.instance.authStateChanges()` and routes to `MainLayout` if logged in, or `LoginScreen` if not. Show a loading spinner while the auth state is loading.

**AI Response Summary:**
Created `LoginScreen` and `RegisterScreen` with form validation and Firebase sign-in/sign-up calls. Added `AuthWrapper` in `main.dart` using `StreamBuilder<User?>` that shows a `CircularProgressIndicator` while waiting, routes to `MainLayout` on valid session, and falls back to `LoginScreen` when signed out.

---

## Prompt 2 — Manual AI Scan (Backend Integration)

| Field              | Details                            |
| ------------------ | ---------------------------------- |
| **Date**           | Feb 2026                           |
| **Category**       | Core Feature / Backend Integration |
| **Model**          | Antigravity (Gemini)               |
| **Files Affected** | `home_screen.dart`                 |

**Prompt:**

> Add a "Run Manual Scan" button to the home screen. When tapped, call `POST /api/scan` with the user's `uid`, `target_name`, and `photo_url` as JSON. Show a loading state while scanning. On success, save the response `findings` array to Firestore under `users/{uid}/scan_logs`, then navigate to `ScanResultsScreen` passing the findings.

**AI Response Summary:**
Added `_runManualScan()` as an async method in `HomeScreen`. Used the `http` package to `POST` to the backend with a 60-second timeout. On a `200` response, decoded the `findings` list, wrote a full scan log document to Firestore (including the raw findings array, timestamp, date, findings count, and status), then navigated to `ScanResultsScreen`. Added error handling with descriptive `SnackBar` messages.

---

## Prompt 3 — Identity Reference Photo Upload

| Field              | Details                                                                |
| ------------------ | ---------------------------------------------------------------------- |
| **Date**           | Feb 2026                                                               |
| **Category**       | Profile / Firebase Storage                                             |
| **Model**          | Antigravity (Gemini)                                                   |
| **Files Affected** | `profile_screen.dart`, `storage_service.dart`, `database_service.dart` |

**Prompt:**

> In the Profile screen, let the user pick a photo from gallery using `image_picker`. Upload it to Firebase Storage at `users/{uid}/profile_photo.jpg`. After uploading, get the download URL and call `user.updatePhotoURL(downloadUrl)`. Show a loading indicator during upload. Display the current photo if one exists, with UPDATE and DELETE options.

**AI Response Summary:**
Created `StorageService` with `uploadProfilePhoto()` and `deleteProfilePhoto()` methods with a 15-second timeout and descriptive error on timeout. In `ProfileScreen`, added `_uploadPhoto()` and `_deletePhoto()` flows with loading states. The profile header reactively re-renders with `NetworkImage` when `user.photoURL` is non-null, and falls back to a person icon.

---

## Prompt 4 — Evidence Locker Screen

| Field              | Details                                         |
| ------------------ | ----------------------------------------------- |
| **Date**           | Feb 2026                                        |
| **Category**       | Core Feature / UI                               |
| **Model**          | Antigravity (Gemini)                            |
| **Files Affected** | `evidence_screen.dart`, `database_service.dart` |

**Prompt:**

> Create an Evidence Locker screen that streams evidence records from Firestore. For each record, show a card with the detected image (from `image_url`), severity badge (Critical/High/Medium), platform, date, source URL (tappable), cryptographic hash, and AI score. Add a delete button per card. Add an "EXPORT PDF" button that generates a formal legal PDF report using the `pdf` and `printing` packages.

**AI Response Summary:**
Built `EvidenceScreen` with a `StreamBuilder` from `DatabaseService().strEvidence()`. Each card uses a `Stack` with a floating trash icon (with confirm dialog) and an image that opens the source URL via `url_launcher`. The severity badge is rendered as a colored overlay on the image. The `_exportPdfReport()` method generates a full A4 legal notice with header, title, details table, and footer, then shares it via `Printing.sharePdf()`.

---

## Prompt 5 — Dashboard Stats & Recent Activity

| Field              | Details                                     |
| ------------------ | ------------------------------------------- |
| **Date**           | Feb 2026                                    |
| **Category**       | Dashboard / Firestore                       |
| **Model**          | Antigravity (Gemini)                        |
| **Files Affected** | `home_screen.dart`, `database_service.dart` |

**Prompt:**

> On the home screen, stream scan logs and evidence from Firestore in real-time. Display stats for total scans, total alerts, and unique platforms. Below that, show the 5 most recent scan log entries as a tappable list. Tapping a log should re-open `ScanResultsScreen` with the stored findings from that log entry.

**AI Response Summary:**
Used nested `StreamBuilder`s for scan logs and evidence. Computed unique platforms with a `Set<String>`. Rendered three stat cards in a `Row`. The recent activity list is capped at 5 entries with a `ListView.separated`. Tapping a log navigates to `ScanResultsScreen` if `findings` is non-empty, shows a snackbar for zero-result logs, and shows a "Old log format" message if findings were not stored.

---

## Prompt 6 — FastAPI Backend (`/api/scan`)

| Field              | Details                 |
| ------------------ | ----------------------- |
| **Date**           | Feb 2026                |
| **Category**       | Backend                 |
| **Model**          | Antigravity (Gemini)    |
| **Files Affected** | `main.py`, `scraper.py` |

**Prompt:**

> Build a FastAPI server with a `POST /api/scan` endpoint that accepts `uid`, `target_name`, and `photo_url`. Run an async deepfake scan using `run_deepfake_scan()`. Return a JSON response with `status`, `findings_count`, and `findings` array. Do NOT write to Firestore from the backend. Add CORS middleware allowing all origins.

**AI Response Summary:**
Created `main.py` with FastAPI, `CORSMiddleware` (all origins allowed), and a `ScanRequest` Pydantic model. The `/api/scan` endpoint calls `await run_deepfake_scan(target_name, photo_url)` and returns a clean JSON payload. Firestore writes were deliberately removed from the backend to eliminate `invalid_grant` JWT signature errors from the Firebase Admin SDK. Added a `/health` GET endpoint for uptime monitoring.

---

## Prompt 7 — Production Deployment (Railway)

| Field              | Details                                   |
| ------------------ | ----------------------------------------- |
| **Date**           | Mar 2026                                  |
| **Category**       | DevOps / Deployment                       |
| **Model**          | Antigravity (Gemini)                      |
| **Files Affected** | `home_screen.dart`, Railway start command |

**Prompt:**

> Configure the FastAPI backend to run on Railway. Set the start command so it binds to Railway's dynamic port. In the Flutter app, set the base URL to the production Railway domain.

**AI Response Summary:**
Updated `baseUrl` in `home_screen.dart` from a local IP (`http://10.29.117.168:8000`) to `https://nyra-ai-production.up.railway.app`. Advised setting the Railway start command to `uvicorn main:app --host 0.0.0.0 --port $PORT` so the process binds to all interfaces and Railway's assigned port — fixing the 502 "Application failed to respond" error caused by the server listening only on `localhost`.

---

## Prompt 8 — Scan Results Storage & Re-Viewing

| Field              | Details                                                                 |
| ------------------ | ----------------------------------------------------------------------- |
| **Date**           | Mar 2026                                                                |
| **Category**       | Data Persistence                                                        |
| **Model**          | Antigravity (Gemini)                                                    |
| **Files Affected** | `home_screen.dart`, `database_service.dart`, `scan_results_screen.dart` |

**Prompt:**

> When saving a scan to Firestore, include the full `findings` array in the document. When the user taps a past scan log in Recent Activity, navigate to `ScanResultsScreen` with those stored findings so they can re-view old scan data.

**AI Response Summary:**
Updated the scan logging code in `_runManualScan()` to include the raw `findings` list in the Firestore document. In the recent activity `ListTile.onTap`, added logic to read `log['findings']` and cast it to `List<Map<String, dynamic>>` before passing it to `ScanResultsScreen`. This made the entire scan history interactive and persistent across app sessions.
