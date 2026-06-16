# Railway Deployment Checklist

**Quick Path to Production with Railway**

---

## 📋 Phase 1: Railway Setup (10 minutes)

### Step 1: Create Account
- [ ] Go to https://railway.app
- [ ] Click "Get Started"
- [ ] Click "Sign up with GitHub"
- [ ] Authorize with GitHub
- [ ] Account created (no verification loops!)

### Step 2: Create MySQL Database
- [ ] In Railway dashboard, click "New Project"
- [ ] Click "Create New"
- [ ] Scroll and click "MySQL"
- [ ] Wait 1-2 minutes for creation
- [ ] MySQL database running

### Step 3: Get Connection Details
- [ ] Click on MySQL service
- [ ] Click "Connect" tab
- [ ] Copy these details:
  - [ ] **External Host**: (for Vercel/local use)
  - [ ] **User**: root
  - [ ] **Password**: (generated, copy it)
  - [ ] **Database**: railway

### Step 4: Load Schema Locally

**In PowerShell in Mock Dbase folder:**

```bash
# Replace <EXTERNAL_HOST> with actual Railway host from Step 3

# Test connection
mysql -h <EXTERNAL_HOST> -u root -p<PASSWORD>
# Type exit when done
```

- [ ] Connection test successful

```bash
# Create database
mysql -h <EXTERNAL_HOST> -u root -p<PASSWORD> -e "CREATE DATABASE knra_licensing_db;"

# Load schema
mysql -h <EXTERNAL_HOST> -u root -p<PASSWORD> knra_licensing_db < 01_MySQL_Schema_Creation.sql

# Load sample data
mysql -h <EXTERNAL_HOST> -u root -p<PASSWORD> knra_licensing_db < 02_MySQL_Sample_Data.sql

# Verify - should show 12 tables + 3 views
mysql -h <EXTERNAL_HOST> -u root -p<PASSWORD> knra_licensing_db -e "SHOW TABLES;"
```

- [ ] Database created
- [ ] Schema loaded
- [ ] Sample data loaded
- [ ] SHOW TABLES shows 15 items

### Step 5: Test Local Connection
```bash
# Make sure Flask is running on localhost:5000
curl http://localhost:5000/health

# Should return: {"status":"healthy","database":"connected"}
```

- [ ] Local API connected to Railway

---

## 📋 Phase 2: GitHub Repository (5 minutes)

### Step 1: Create Repo
- [ ] Go to https://github.com/new
- [ ] Repo name: knra-api
- [ ] Description: KNRA Licensing Database API
- [ ] Public
- [ ] Create repository

### Step 2: Push Code

```bash
cd "c:\Users\HP\OneDrive\Belgeler\Mock Dbase"

# Initialize
git init
git add .
git commit -m "Initial KNRA API commit - Railway backend"

# Add remote (replace USERNAME)
git remote add origin https://github.com/USERNAME/knra-api.git

# Push
git branch -M main
git push -u origin main
```

- [ ] Repository created on GitHub
- [ ] All code pushed
- [ ] Repo visible at https://github.com/USERNAME/knra-api

---

## 📋 Phase 3: Vercel Deployment (10 minutes)

### Step 1: Deploy
- [ ] Go to https://vercel.com
- [ ] Click "Add New" → "Project"
- [ ] Select "knra-api" repository
- [ ] Click "Import"
- [ ] Framework: Other
- [ ] Click "Deploy"
- [ ] Wait 2-3 minutes
- [ ] Status shows "Ready"

### Step 2: Add Environment Variables

**Vercel → Your Project → Settings → Environment Variables**

Add these 5 variables:

**Variable 1: DB_HOST**
- [ ] Name: DB_HOST
- [ ] Value: (Railway external host from Step 3 of Phase 1)
- [ ] Check: Production, Preview, Development
- [ ] Click "Save"

**Variable 2: DB_USER**
- [ ] Name: DB_USER
- [ ] Value: root
- [ ] Check: Production, Preview, Development
- [ ] Click "Save"

**Variable 3: DB_PASSWORD**
- [ ] Name: DB_PASSWORD
- [ ] Value: (Railway password from Step 3 of Phase 1)
- [ ] Check: Production, Preview, Development
- [ ] Click "Save"

**Variable 4: DB_NAME**
- [ ] Name: DB_NAME
- [ ] Value: knra_licensing_db
- [ ] Check: Production, Preview, Development
- [ ] Click "Save"

**Variable 5: FLASK_ENV**
- [ ] Name: FLASK_ENV
- [ ] Value: production
- [ ] Check: Production, Preview
- [ ] Click "Save"

### Step 3: Redeploy

- [ ] Go to "Deployments" tab
- [ ] Click "Redeploy" on latest deployment
- [ ] Wait 1-2 minutes
- [ ] Status shows "Ready"

---

## 📋 Phase 4: Testing (5 minutes)

### Test 1: Health Check
```bash
curl https://knra-api.vercel.app/health

# Expected: {"status":"healthy","database":"connected"}
```
- [ ] Health check responding

### Test 2: Facilities
```bash
curl https://knra-api.vercel.app/api/facilities

# Should return 3 facilities
```
- [ ] Facilities endpoint working

### Test 3: Licenses
```bash
curl https://knra-api.vercel.app/api/licenses

# Should return 2 licenses
```
- [ ] Licenses endpoint working

### Test 4: Equipment
```bash
curl https://knra-api.vercel.app/api/equipment

# Should return 3 equipment items
```
- [ ] Equipment endpoint working

### Test 5: KPIs
```bash
curl https://knra-api.vercel.app/api/reports/kpis

# Should return metrics
```
- [ ] KPIs endpoint working

### Test 6: Full Test Suite
```bash
cd "c:\Users\HP\OneDrive\Belgeler\Mock Dbase"
powershell -ExecutionPolicy Bypass -File test_api_simple.ps1 -BaseUrl "https://knra-api.vercel.app"

# Should show 16/17 passing
```
- [ ] Full test suite passing (16/17)

---

## ✅ Final Verification Checklist

### Railway
- [ ] Account created (GitHub login only)
- [ ] MySQL database running
- [ ] External host available
- [ ] Schema loaded (12 tables)
- [ ] Sample data loaded (3 facilities, 2 licenses, 3 equipment)
- [ ] Local connection working

### GitHub
- [ ] Repo created: knra-api
- [ ] All files pushed
- [ ] Repo public

### Vercel
- [ ] Project deployed
- [ ] Status: Ready
- [ ] All 5 env vars set
- [ ] Redeployed after env vars

### Live API
- [ ] Health check: 200 OK
- [ ] Facilities: returns data
- [ ] Licenses: returns data
- [ ] Equipment: returns data
- [ ] Reports: returns data
- [ ] 16/17 endpoints passing
- [ ] Response time: < 200ms average

---

## 🎉 Success!

Your API is live at: **https://knra-api.vercel.app**

**Available Endpoints:**
- ✅ /health
- ✅ /api/facilities
- ✅ /api/licenses
- ✅ /api/licenses/expiring?days=90
- ✅ /api/equipment
- ✅ /api/equipment/overdue
- ✅ /api/inspections
- ✅ /api/inspectors
- ✅ /api/reports/kpis
- ✅ /api/reports/compliance-summary
- ✅ /api/reports/violations
- ✅ Plus 5 more endpoints

---

## 💰 Costs

**Railway Free Credit**: $5/month (12 months free)  
**Vercel**: Free  
**GitHub**: Free  

**Your 12-month cost: $0** ✅

---

## ⏱️ Total Setup Time

| Phase | Time |
|-------|------|
| Railway Setup | 10 min |
| GitHub | 5 min |
| Vercel Deploy | 10 min |
| Testing | 5 min |
| **TOTAL** | **30 min** |

---

## 🚀 Start Here

1. Open **RAILWAY_SETUP.md** for detailed steps
2. Follow **Phase 1** of this checklist
3. Then Phases 2, 3, 4 in order
4. Done! Live API deployed

**No Azure verification loops needed!**
