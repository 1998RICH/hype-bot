# Strideby Backend

Accounts, run upload, GPS crossing detection, matching, and chat.
FastAPI + SQLite (Postgres-ready via `DATABASE_URL`).

## Run locally

```bash
cd server
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/uvicorn app.main:app --reload
```

Interactive API docs: http://127.0.0.1:8000/docs

## Run the tests

```bash
.venv/bin/pip install -r requirements-dev.txt
.venv/bin/python -m pytest tests/
```

The tests cover the crossing detector (including the "brief pass doesn't
count" rule and home-zone privacy trimming) and the full API flow:
register → upload runs → crossing appears for both → mutual like → match → chat.

## Deploy (free tier, ~10 minutes)

[Render](https://render.com) is the simplest path:

1. Sign up with your GitHub account and click **New → Web Service**.
2. Pick this repository; set **Root Directory** to `server`.
3. Build command: `pip install -r requirements.txt`
4. Start command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
5. Add an environment variable `SECRET_KEY` set to a long random string
   (e.g. run `python3 -c "import secrets; print(secrets.token_hex(32))"`).
6. Deploy — you'll get a URL like `https://strideby-api.onrender.com`.

Then open `ios/Strideby/AppConfig.swift` and set:

```swift
static let apiBaseURL: URL? = URL(string: "https://strideby-api.onrender.com")
```

Rebuild the app — it now uses real accounts and real crossings.

> Note: SQLite on Render's free tier resets on redeploy. Fine for testing
> with friends; before a real beta, add a Postgres instance and set
> `DATABASE_URL` (the code already supports it).

## API overview

| Method & path | What it does |
|---|---|
| `POST /auth/register`, `POST /auth/login` | Returns a bearer token |
| `GET /me`, `PUT /me` | Profile + privacy settings (ghost mode, home-zone hiding) |
| `POST /runs` | Upload a GPS track; crossings are detected immediately |
| `GET /crossings` | Runners you crossed and haven't decided on |
| `POST /crossings/{id}/decision` | Like or pass; reports a match when mutual |
| `GET /matches` | Your matches with last message |
| `GET/POST /matches/{id}/messages` | Chat |
| `GET /health` | Uptime check |

## How crossing detection works

On every run upload, the server prefilters candidate runs by time window and
bounding box, then walks both GPS tracks counting seconds the runners were
within 25 m of each other at the same moment. At least 60 s of shared path
is required — a brief pass (like Strava's false "ran with" groupings) does
not count. Users with **hide home zone** enabled have the first/last 400 m
of every run discarded before comparison, and **ghost mode** users neither
create nor receive crossings. See `app/detection.py`.
