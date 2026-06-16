# KNRA Licensing Database

Mock licensing registry for the Kenya Nuclear Regulatory Authority: a Flask REST
API plus a modern React dashboard showing **Facilities**, **Licenses** and
**Inspectors**.

The API uses a **self-contained SQLite database** that is created and seeded
automatically on first run — no MySQL server or environment variables required.
(The original MySQL scripts are kept in the repo for reference.)

## Quick start

### 1. Backend (Flask API)

```bash
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
python app.py                      # serves http://localhost:5000
```

Key endpoints:

| Endpoint | Description |
| --- | --- |
| `GET /health` | API + database health |
| `GET /api/facilities` | Hospital name, location, radiation class |
| `GET /api/licenses` | Issue/expiry dates, status, fee paid |
| `GET /api/inspectors` | Staff ID, assigned facilities, inspection count |
| `GET /api/reports/kpis` | Dashboard summary counts |

### 2. Frontend (React dashboard)

```bash
cd frontend
npm install
npm run dev        # dev server on http://localhost:5173 (proxies /api to :5000)
npm run build      # production build into frontend/dist
```

After `npm run build`, the Flask app serves the dashboard at `http://localhost:5000`.

## Deployment (Vercel)

`vercel.json` builds the React app as a static site and `app.py` as a Python
serverless function. `/api/*` and `/health` route to Flask; everything else
serves the dashboard.

## Data model

`db.py` defines the SQLite schema and seed data (facilities, licenses,
equipment, inspectors, inspections and assignments), mirroring the sample
records in `02_MySQL_Sample_Data.sql`.
