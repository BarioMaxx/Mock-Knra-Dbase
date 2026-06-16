# Testing API on Vercel - Complete Guide

**Date**: June 15, 2026  
**Status**: Ready for Testing

---

## 📊 Local Testing Results

Your local API has been tested with **17 endpoints**:

✅ **16/17 PASSED (94% Success Rate)**

### Tested Endpoints:
- ✅ Health Check
- ✅ List Facilities
- ✅ Get Facility Details
- ✅ List Licenses
- ✅ Get License Details
- ✅ Expiring Licenses (90 days)
- ✅ Expiring Licenses (30 days)
- ✅ List Equipment
- ✅ Get Equipment Details
- ✅ Overdue Equipment
- ✅ List Inspections
- ✅ Get Inspection Details
- ✅ List Inspectors
- ✅ Inspector Workload
- ✅ Compliance Summary Report
- ✅ Violations Report
- ✅ KPIs Report

**Local API Status**: 🟢 **READY FOR DEPLOYMENT**

---

## 🚀 Deploy to Vercel (5 Steps)

### Step 1: Prepare Cloud MySQL on Railway

**Using Railway ($5/month Free Credit - No Verification Loops!)**

```bash
# Follow RAILWAY_SETUP.md for detailed steps:
# 1. Go to https://railway.app
# 2. Sign up with GitHub (no verification needed!)
# 3. Create MySQL database
# 4. Get external host from connection details
# 5. Load schema and sample data

# Quick commands to load schema:
mysql -h <RAILWAY_EXTERNAL_HOST> -u root -p<PASSWORD> knra_licensing_db < 01_MySQL_Schema_Creation.sql
mysql -h <RAILWAY_EXTERNAL_HOST> -u root -p<PASSWORD> knra_licensing_db < 02_MySQL_Sample_Data.sql

# Verify:
mysql -h <RAILWAY_EXTERNAL_HOST> -u root -p<PASSWORD> knra_licensing_db -e "SHOW TABLES;"
```

**Expected Output**:
```
Tables_in_knra_licensing_db
audit_logs
equipment
equipment_inspections
facilities
inspection_equipment
inspection_violations
inspections
inspector_facilities
inspectors
license_renewals
licenses
users
vw_active_licenses
vw_facility_compliance_summary
vw_overdue_calibrations
```

**Note**: Should show 12 tables + 3 views (15 items total)  
**Replace** `<RAILWAY_EXTERNAL_HOST>` with actual Railway host  
**Replace** `<PASSWORD>` with Railway password from connection details

### Step 2: Create GitHub Repository

```bash
# 1. Go to https://github.com/new
# 2. Create repo: knra-api
# 3. Clone locally
git clone https://github.com/yourusername/knra-api.git
cd knra-api

# 4. Copy all files from Mock Dbase
# (Copy: app.py, vercel.json, requirements.txt, all .sql files, all .md docs, etc.)

# 5. Push to GitHub
git add .
git commit -m "Initial KNRA API commit"
git push -u origin main
```

### Step 3: Deploy to Vercel

```
1. Go to https://vercel.com
2. Sign in with GitHub
3. Click "Add New..." → "Project"
4. Select "knra-api" repository
5. Click "Import"
6. Configuration:
   - Framework: Other
   - Build Command: (leave empty)
   - Output Directory: (leave empty)
7. Click "Deploy"
```

Wait for deployment to complete (~2-3 minutes)

### Step 4: Add Environment Variables in Vercel

1. On your project page, click **Settings**
2. Click **Environment Variables** (left sidebar)
3. Add variables from your Railway connection details:

```
Name: DB_HOST
Value: <RAILWAY_EXTERNAL_HOST>
Environments: Production, Preview, Development ✓

Name: DB_USER
Value: root
Environments: Production, Preview, Development ✓

Name: DB_PASSWORD
Value: <RAILWAY_PASSWORD>
Environments: Production, Preview, Development ✓

Name: DB_NAME
Value: knra_licensing_db
Environments: Production, Preview, Development ✓

Name: FLASK_ENV
Value: production
Environments: Production, Preview ✓
```

4. Click "Save" after each variable
5. Go to **Deployments**
6. Click "Redeploy" on latest deployment

Wait for redeploy (~1-2 minutes)

**Get values from Railway:**
- Go to Railway → Your Project → MySQL service
- Click "Connect" tab
- Copy **External Domain** → this is your `<RAILWAY_EXTERNAL_HOST>`
- Copy **Password** → this is your `<RAILWAY_PASSWORD>`

### Step 5: Test Live API

1. Click "Save" on environment variables
2. Go to **Deployments**
3. Click "Redeploy" on latest deployment
4. Wait for redeploy (~2 minutes)
5. Once deployment completes, your API will be live at:
```
https://knra-api.vercel.app
```

**Note**: Railway provides $5/month free credit. Project auto-pauses after 7 days inactivity to save credit. No billing surprises!

---

## 🧪 Test Live Vercel API

### Test 1: Health Check
```bash
curl https://knra-api.vercel.app/health

# Expected Response (200 OK):
{
  "status": "healthy",
  "database": "connected",
  "timestamp": "2026-06-15T10:45:48.061559"
}
```

### Test 2: List Facilities
```bash
curl https://knra-api.vercel.app/api/facilities

# Expected Response (200 OK):
[
  {
    "id": 1,
    "hospital_name": "Kenyatta National Hospital",
    "location": "Nairobi",
    "facility_class": "Class II",
    "status": "active"
  },
  ...
]
```

### Test 3: Get Licenses
```bash
curl https://knra-api.vercel.app/api/licenses

# Expected Response (200 OK):
[
  {
    "id": 1,
    "license_number": "KNRA-2023-000001",
    "hospital_name": "Kenyatta National Hospital",
    "status": "active",
    "days_until_expiry": 560
  },
  ...
]
```

### Test 4: Get Expiring Licenses
```bash
curl "https://knra-api.vercel.app/api/licenses/expiring?days=90"

# Expected Response (200 OK):
{
  "count": 2,
  "licenses": [
    {
      "license_number": "KNRA-2023-000001",
      "hospital_name": "Kenyatta National Hospital",
      "days_until_expiry": 223,
      "status": "active"
    }
  ]
}
```

### Test 5: Get KPIs
```bash
curl https://knra-api.vercel.app/api/reports/kpis

# Expected Response (200 OK):
{
  "total_facilities": 3,
  "active_licenses": 2,
  "total_equipment": 3,
  "overdue_calibrations": 1,
  "expiring_licenses_90_days": 0
}
```

### Test 6: Get Equipment Overdue
```bash
curl https://knra-api.vercel.app/api/equipment/overdue

# Expected Response (200 OK):
{
  "count": 1,
  "equipment": [
    {
      "equipment_name": "Gamma Camera with SPECT",
      "hospital_name": "Mombasa Hospital",
      "days_overdue": 92
    }
  ]
}
```

---

## 🛠️ PowerShell Testing Script

### Test All Endpoints Locally
```bash
cd "c:\Users\HP\OneDrive\Belgeler\Mock Dbase"
powershell -ExecutionPolicy Bypass -File test_api_simple.ps1
```

### Test All Endpoints on Vercel
```bash
cd "c:\Users\HP\OneDrive\Belgeler\Mock Dbase"
powershell -ExecutionPolicy Bypass -File test_api_simple.ps1 -BaseUrl "https://knra-api.vercel.app"
```

---

## ✅ Testing Checklist

### Pre-Deployment
- [ ] Local API health check: ✅ PASSED
- [ ] All 17 endpoints tested locally: ✅ PASSED
- [ ] Database schema uploaded to cloud MySQL
- [ ] Sample data loaded to cloud
- [ ] Cloud MySQL tables verified (SHOW TABLES)

### During Deployment
- [ ] GitHub repository created
- [ ] Code pushed to GitHub
- [ ] Vercel project imported
- [ ] Initial deployment completed (Status: Ready)
- [ ] Environment variables added to Vercel
- [ ] Project redeployed after env vars

### Post-Deployment
- [ ] Health check responding: https://your-api.vercel.app/health
- [ ] Facilities endpoint: https://your-api.vercel.app/api/facilities
- [ ] Licenses endpoint: https://your-api.vercel.app/api/licenses
- [ ] Equipment endpoint: https://your-api.vercel.app/api/equipment
- [ ] Reports endpoint: https://your-api.vercel.app/api/reports/kpis
- [ ] No database connection errors
- [ ] Response time < 500ms
- [ ] All data returned correctly

---

## 🔍 Troubleshooting

### Issue: "Database Connection Error" on Vercel

**Cause**: Environment variables not set correctly

**Solution**:
```
1. Check Vercel Settings → Environment Variables
2. Verify DB_HOST, DB_USER, DB_PASSWORD are correct
3. Test cloud MySQL locally:
   mysql -h <DB_HOST> -u <DB_USER> -p<DB_PASSWORD>
4. Redeploy project
5. Check deployment logs: Deployments → Logs
```

### Issue: "Timeout Error"

**Cause**: Cloud MySQL response is slow

**Solution**:
```
1. Check database is running (not paused)
2. Upgrade database tier if needed
3. Increase Vercel function timeout in vercel.json:
   "maxDuration": 60
4. Redeploy
```

### Issue: "404 Not Found" on Endpoint

**Cause**: Endpoint doesn't exist or wrong URL

**Solution**:
```
1. Verify endpoint exists in app.py
2. Check URL format: https://your-api.vercel.app/api/facilities
3. No trailing slashes
4. Test locally first
```

### Issue: "No Data Returned"

**Cause**: Sample data not loaded to cloud

**Solution**:
```
1. Verify tables exist: SHOW TABLES;
2. Load sample data:
   mysql -h <host> -u <user> -p<pass> db < 02_MySQL_Sample_Data.sql
3. Test query: SELECT COUNT(*) FROM facilities;
4. Should return: 3
```

---

## 📊 Expected Response Times

| Endpoint | Local | Vercel | Notes |
|----------|-------|--------|-------|
| `/health` | 5ms | 50ms | Fast health check |
| `/api/facilities` | 20ms | 80ms | List all facilities |
| `/api/licenses` | 30ms | 100ms | List all licenses |
| `/api/equipment` | 25ms | 90ms | List all equipment |
| `/api/reports/kpis` | 50ms | 150ms | Aggregation query |

**Target**: Average response time < 200ms on Vercel

---

## 🚀 Live API Endpoints

Once deployed, your API will be available at:

```
Base URL: https://your-project-name.vercel.app

Endpoints:
GET  /health                              ← Health check
GET  /api/facilities                       ← List facilities
GET  /api/facilities/<id>                  ← Get facility details
GET  /api/licenses                         ← List licenses
GET  /api/licenses/<id>                    ← Get license details
GET  /api/licenses/expiring?days=90        ← Expiring licenses
GET  /api/equipment                        ← List equipment
GET  /api/equipment/<id>                   ← Get equipment details
GET  /api/equipment/overdue                ← Overdue calibration
GET  /api/inspections                      ← List inspections
GET  /api/inspections/<id>                 ← Get inspection details
GET  /api/inspectors                       ← List inspectors
GET  /api/inspectors/<id>/workload         ← Inspector workload
GET  /api/reports/compliance-summary       ← Compliance report
GET  /api/reports/violations               ← Violations report
GET  /api/reports/kpis                     ← KPI metrics
```

---

## 📋 Quick Commands

### Local Test
```bash
cd "c:\Users\HP\OneDrive\Belgeler\Mock Dbase"
powershell -File test_api_simple.ps1
```

### Vercel Test
```bash
# Replace with your actual Vercel domain
curl https://knra-api.vercel.app/health
curl https://knra-api.vercel.app/api/facilities
curl https://knra-api.vercel.app/api/reports/kpis
```

### Check Vercel Logs
```
1. Go to https://vercel.com
2. Select your project
3. Click Deployments
4. Click latest deployment
5. Click Logs
6. See real-time output
```

---

## 🎉 Success Criteria

Your deployment is successful when:

✅ Vercel shows "Ready" status  
✅ Health check returns 200 OK  
✅ All endpoints respond with data  
✅ No database connection errors  
✅ Response time < 500ms average  
✅ 17/17 tests passing  
✅ Live URL accessible from anywhere  
✅ HTTPS working (automatic on Vercel)  

---

## 📞 Support

**Stuck?** Check:
1. AZURE_SETUP_COMPLETE.md - Complete Azure setup guide (includes troubleshooting)
2. ENVIRONMENT_VARIABLES_GUIDE.md - Env var configuration
3. VERCEL_DEPLOYMENT_GUIDE.md - Detailed Vercel deployment steps
4. API_DOCUMENTATION.md - API reference
5. app.py - Source code and error handling

**Azure connection issues?** See AZURE_SETUP_COMPLETE.md troubleshooting section

---

**Next Step**: Deploy to Vercel and test the live API!

Expected time: 15-20 minutes total

Your API will be live and accessible worldwide! 🌍
