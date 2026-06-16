# Azure for Students - Complete Setup Guide

**Your Path to Production with $100-200 Free Credit**

---

## 🚀 Quick Start (30 minutes to live API)

### Phase 1: Activate Azure for Students (5 min)

**Step 1: Go to Azure Education Hub**
```
1. Open https://azure.microsoft.com/en-us/free/students/
2. Click "Activate now"
3. Sign in with your student email
4. Verify academic status
5. Confirm $100-200 credit (valid for 12 months)
```

**Step 2: Go to Azure Portal**
```
https://portal.azure.com
```

You should see your subscription with free credit in the top-right corner.

---

### Phase 2: Create Azure MySQL Database (10 min)

**Step 1: Create Database Resource**
```
1. Click "Create a resource" (top-left)
2. Search for "Azure Database for MySQL"
3. Click on result
4. Click "Create"
```

**Step 2: Configure Database**
```
Fill in the form:

Subscription: (your student subscription)
Resource Group: Click "Create new" → "knra-db-group"
Server name: knra-mysql-server
Region: (choose closest to you, or East US)
MySQL version: 8.0
Admin username: adminuser
Admin password: (create strong password - SAVE THIS!)
Storage: 20 GB (default is fine)
Compute tier: Burstable (cheapest - fine for this project)
```

**Step 3: Create**
```
Click "Review + Create"
Then click "Create"
Wait 5-10 minutes for database creation
```

**Step 4: Get Connection Details**
```
1. Once created, go to your database resource
2. Click "Connection strings" (left sidebar)
3. Copy the MYSQL connection string
4. Note the details:
   - Host: knra-mysql-server.mysql.database.azure.com
   - Username: adminuser@knra-mysql-server
   - Password: (your password from step 2)
   - Database: (we'll create this called "knra_licensing_db")
```

---

### Phase 3: Open Firewall for Local Access (5 min)

**Step 1: Configure Firewall**
```
1. In your database resource, click "Connection security"
2. Find "Firewall rules"
3. Click "Add current client IP"
4. Click "Save"
```

**Step 2: Allow Vercel (Important!)**
```
1. Click "Add a firewall rule"
2. Rule name: AllowVercel
3. Start IP: 0.0.0.0
4. End IP: 255.255.255.255
5. Click "OK"
6. Click "Save"
```

**This allows any IP to connect (needed for Vercel)**

---

### Phase 4: Load Database Schema (5 min)

**Step 1: Install MySQL Client (if needed)**

**Windows - Option A: Use MySQL Workbench**
```
1. Download from https://dev.mysql.com/downloads/workbench/
2. Install it
3. Open MySQL Workbench
4. Click "+" to add connection
5. Connection name: KNRA Azure
6. Hostname: knra-mysql-server.mysql.database.azure.com
7. Username: adminuser@knra-mysql-server
8. Password: (your password)
9. Click "Test Connection"
10. Should say "Successfully made the MySQL connection"
```

**Windows - Option B: Use MySQL CLI**
```
1. Download MySQL from https://dev.mysql.com/downloads/mysql/
2. During install, add to PATH
3. Then use commands below
```

**Step 2: Load Schema from Command Line**

```bash
# Open PowerShell in your Mock Dbase folder

# Step 1: Test connection
mysql -h knra-mysql-server.mysql.database.azure.com -u adminuser@knra-mysql-server -p

# When prompted, enter your password
# You should see: mysql>
# Type "exit" to leave

# Step 2: Create database
mysql -h knra-mysql-server.mysql.database.azure.com -u adminuser@knra-mysql-server -p -e "CREATE DATABASE knra_licensing_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Step 3: Load schema
mysql -h knra-mysql-server.mysql.database.azure.com -u adminuser@knra-mysql-server -p knra_licensing_db < 01_MySQL_Schema_Creation.sql

# Step 4: Load sample data
mysql -h knra-mysql-server.mysql.database.azure.com -u adminuser@knra-mysql-server -p knra_licensing_db < 02_MySQL_Sample_Data.sql

# Step 5: Verify
mysql -h knra-mysql-server.mysql.database.azure.com -u adminuser@knra-mysql-server -p knra_licensing_db -e "SHOW TABLES;"
```

**Expected output from SHOW TABLES:**
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

**You should see 12 tables + 3 views = 15 total**

---

### Phase 5: Test Azure Connection Locally (5 min)

```bash
# Test health check with Azure database
curl http://localhost:5000/health

# Expected response:
{
  "status": "healthy",
  "database": "connected",
  "timestamp": "2026-06-15T10:45:48.061559"
}

# Test facilities
curl http://localhost:5000/api/facilities

# Should return array of 3 facilities
```

---

## 🔧 Azure Connection String Reference

**Your credentials:**
```
Host: knra-mysql-server.mysql.database.azure.com
Username: adminuser@knra-mysql-server
Password: (your strong password)
Database: knra_licensing_db
Port: 3306
```

**Connection string format (for reference):**
```
mysql://adminuser@knra-mysql-server:password@knra-mysql-server.mysql.database.azure.com:3306/knra_licensing_db
```

---

## 🚀 Deploy to Vercel with Azure (15 min)

### Step 1: Create GitHub Repository

```bash
# Go to https://github.com/new
# Create repository named: knra-api

# Then in your terminal:
cd "c:\Users\HP\OneDrive\Belgeler\Mock Dbase"

# Initialize git (if not already)
git init
git add .
git commit -m "Initial KNRA API commit - Azure backend"
git remote add origin https://github.com/YOUR_USERNAME/knra-api.git
git branch -M main
git push -u origin main
```

### Step 2: Deploy to Vercel

```
1. Go to https://vercel.com
2. Click "Add New" → "Project"
3. Select your GitHub account
4. Find and select "knra-api" repository
5. Click "Import"
6. Click "Deploy"
7. Wait 2-3 minutes for deployment
```

### Step 3: Add Azure Credentials to Vercel

**Go to Vercel → Your Project → Settings → Environment Variables**

Add these variables:

```
DB_HOST = knra-mysql-server.mysql.database.azure.com
DB_USER = adminuser@knra-mysql-server
DB_PASSWORD = (your password from Azure setup)
DB_NAME = knra_licensing_db
FLASK_ENV = production
```

For each variable:
- Check: Production, Preview, Development
- Click "Add"

### Step 4: Redeploy

```
1. Go to Deployments tab
2. Click "Redeploy" on the latest deployment
3. Wait 1-2 minutes
4. Status should change to "Ready"
```

### Step 5: Test Live API

```bash
# Replace "knra-api" with your actual Vercel project name
curl https://knra-api.vercel.app/health

# Expected response (200 OK):
{
  "status": "healthy",
  "database": "connected"
}

# Test facilities:
curl https://knra-api.vercel.app/api/facilities

# Test KPIs:
curl https://knra-api.vercel.app/api/reports/kpis
```

---

## ✅ Verification Checklist

### Azure Setup
- [ ] Student Developer Pack activated ($100-200 credit visible)
- [ ] Azure MySQL database created
- [ ] Firewall rules configured
- [ ] Schema and sample data loaded
- [ ] SHOW TABLES showing 15 items (12 tables + 3 views)
- [ ] Local health check working with Azure

### Vercel Deployment
- [ ] GitHub repository created and pushed
- [ ] Vercel project imported and deployed
- [ ] Environment variables added (all 5)
- [ ] Project redeployed after env vars
- [ ] Deployment status shows "Ready"
- [ ] Live health check responding
- [ ] Live API endpoints returning data

---

## 🧪 Testing Your Live API

### Quick Test
```bash
# Health check
curl https://your-vercel-url.vercel.app/health

# Get facilities
curl https://your-vercel-url.vercel.app/api/facilities

# Get KPIs
curl https://your-vercel-url.vercel.app/api/reports/kpis
```

### Full Test with PowerShell
```bash
cd "c:\Users\HP\OneDrive\Belgeler\Mock Dbase"
powershell -ExecutionPolicy Bypass -File test_api_simple.ps1 -BaseUrl "https://your-vercel-url.vercel.app"

# Should show 16/17 tests passing with Azure database
```

---

## 💰 Cost Breakdown

**Azure for Students:**
- Free credit: $100-200
- Valid for: 12 months
- MySQL database (single server): ~$35/month (covered by credit)
- Total cost for 12 months: $0 ✅

**After 12 months:**
- Option 1: Upgrade to student discount Azure
- Option 2: Switch to truly free tier (Railway, TiDB, etc.)
- Option 3: Pay-as-you-go (~$35/month)

---

## 🔍 Troubleshooting

### Issue: "Connection refused" when loading schema

**Solution:**
```
1. Verify firewall rule allows your IP
2. Azure → Your database → Connection security
3. Confirm "Add current client IP" was done
4. Try pinging: mysql -h knra-mysql-server.mysql.database.azure.com -u adminuser@knra-mysql-server -p -e "SELECT 1;"
```

### Issue: "Authentication failed" when loading schema

**Solution:**
```
1. Double-check username: adminuser@knra-mysql-server (NOT just adminuser)
2. Double-check password is correct
3. Azure portal → Database → Overview → Admin username should show exact format
```

### Issue: "Database error" on Vercel

**Solution:**
```
1. Vercel → Deployments → Click latest
2. Click "Logs" to see error
3. Verify environment variables match exactly
4. Redeploy after fixing
```

### Issue: "Timeout error" on Vercel

**Solution:**
```
1. Azure MySQL may be paused (upgrade from free tier pauses after inactivity)
2. Azure portal → Your database → Start it
3. Vercel → Redeploy
```

---

## 📊 Expected Performance

| Metric | Value |
|--------|-------|
| Health check response | 50-100ms |
| Facilities endpoint | 100-150ms |
| KPIs report | 150-300ms |
| All endpoints working | 16/17 tests pass |

---

## 🎓 What You've Learned

Using Azure for Students teaches:
✅ Cloud database management  
✅ Environment configuration  
✅ Database security & firewalls  
✅ MySQL administration  
✅ Production deployment  
✅ DevOps best practices  

**Great for your CV!**

---

## 📋 Next Steps (In Order)

1. ✅ Activate Azure for Students
2. ✅ Create MySQL database
3. ✅ Load schema and sample data
4. ✅ Test local connection
5. ✅ Create GitHub repository
6. ✅ Deploy to Vercel
7. ✅ Add environment variables
8. ✅ Redeploy and test

**Total time: 30-40 minutes**

---

## 🎉 When You're Done

Your production API will be:
- ✅ Running on Vercel (globally distributed)
- ✅ Backed by Azure MySQL (enterprise-grade)
- ✅ Free for 12 months with student credit
- ✅ Accessible from anywhere in the world
- ✅ Using your own domain (optional: add custom domain to Vercel)
- ✅ Using HTTPS automatically

**Example live URL:** `https://knra-api.vercel.app/api/facilities`

---

## 🚀 Ready to Start?

Follow the phases above in order. If you get stuck on any step, refer back to this guide or check the troubleshooting section.

**Estimated total time: 30-40 minutes**

**Result: Production-grade API with enterprise database!**
