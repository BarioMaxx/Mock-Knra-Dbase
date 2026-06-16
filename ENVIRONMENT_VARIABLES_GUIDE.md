# Environment Variables Configuration Guide

**Purpose**: Manage database credentials and API settings securely  
**Date**: June 15, 2026

---

## 📋 Overview

Environment variables store sensitive information (database credentials, API keys) without hardcoding them into the source code.

**Files**:
- `.env.example` - Template (safe to commit to GitHub)
- `.env` - Your local credentials (NEVER commit to GitHub)
- `.env.local` - Alternative local configuration
- Vercel Settings - Cloud environment variables

---

## 🏠 Local Development Setup

### Step 1: Copy Template File
```bash
cd knra-api
cp .env.example .env
```

### Step 2: Edit .env File

Open `.env` and update with your local database credentials:

```
# Local MySQL Database
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=root
DB_NAME=knra_licensing_db

# Flask Settings
FLASK_ENV=development
FLASK_DEBUG=True
```

### Step 3: Verify Configuration

Test that Flask reads the variables:
```bash
python -c "import os; from dotenv import load_dotenv; load_dotenv(); print(f'DB: {os.getenv(\"DB_NAME\")}, User: {os.getenv(\"DB_USER\")}')"
```

Expected output:
```
DB: knra_licensing_db, User: root
```

### Step 4: Start API Server
```bash
python app.py
```

API will connect to your local MySQL database.

---

## ☁️ Vercel Production Setup

### Step 1: Prepare Cloud MySQL Database

**Option 1: PlanetScale (Recommended)**
```
1. Go to https://planetscale.com
2. Sign up (free)
3. Create database: knra_licensing_db
4. Create password
5. Copy connection string:
   
   Host: xxxx.mysql.planetscale.com
   Username: xxxx
   Password: pscale_xxxx
```

**Option 2: AWS RDS**
```
1. Go to https://aws.amazon.com/rds
2. Create MySQL 8.0 instance
3. Get endpoint: xxx.rds.amazonaws.com
4. Create database user
```

**Option 3: Railway.app**
```
1. Go to https://railway.app
2. Create MySQL database
3. Get connection string from dashboard
```

### Step 2: Upload Schema to Cloud MySQL

Test cloud connection and load schema:
```bash
# Test connection
mysql -h <cloud-host> -u <username> -p<password>

# Load schema
mysql -h <cloud-host> -u <username> -p<password> knra_licensing_db < 01_MySQL_Schema_Creation.sql

# Load sample data
mysql -h <cloud-host> -u <username> -p<password> knra_licensing_db < 02_MySQL_Sample_Data.sql

# Verify tables
mysql -h <cloud-host> -u <username> -p<password> knra_licensing_db -e "SHOW TABLES;"
```

Expected output:
```
+--------------------------------+
| Tables_in_knra_licensing_db    |
+--------------------------------+
| audit_logs                     |
| equipment                      |
| equipment_inspections          |
| facilities                     |
| inspection_equipment           |
| inspection_violations          |
| inspections                    |
| inspector_facilities           |
| inspectors                     |
| license_renewals               |
| licenses                        |
| users                          |
+--------------------------------+
```

### Step 3: Get Vercel Project URL

After deploying to Vercel, you'll get:
```
https://your-project-name.vercel.app
```

Example:
```
https://knra-api.vercel.app
```

### Step 4: Add Environment Variables in Vercel

1. Go to your Vercel project dashboard
2. Click **Settings**
3. Click **Environment Variables**
4. Add each variable:

**Variable 1: DB_HOST**
```
Name:  DB_HOST
Value: your-cloud-host.com
Environments: Production, Preview, Development
```

**Variable 2: DB_USER**
```
Name:  DB_USER
Value: your_username
Environments: Production, Preview, Development
```

**Variable 3: DB_PASSWORD**
```
Name:  DB_PASSWORD
Value: your_password
Environments: Production, Preview, Development
```

**Variable 4: DB_NAME**
```
Name:  DB_NAME
Value: knra_licensing_db
Environments: Production, Preview, Development
```

**Variable 5: FLASK_ENV**
```
Name:  FLASK_ENV
Value: production
Environments: Production, Preview
```

5. Click **Save**
6. Redeploy project (Deployments → Redeploy)

---

## 🧪 Testing Environment Variables

### Local Testing

Verify variables are loaded in app.py:
```bash
python -c "
import os
from dotenv import load_dotenv

load_dotenv()
print('=== Environment Variables ===')
print(f'DB_HOST: {os.getenv(\"DB_HOST\")}')
print(f'DB_USER: {os.getenv(\"DB_USER\")}')
print(f'DB_NAME: {os.getenv(\"DB_NAME\")}')
print(f'FLASK_ENV: {os.getenv(\"FLASK_ENV\")}')
"
```

Expected output:
```
=== Environment Variables ===
DB_HOST: localhost
DB_USER: root
DB_NAME: knra_licensing_db
FLASK_ENV: development
```

### Vercel Testing

Test that Vercel receives environment variables:

```bash
# View Vercel deployment logs
# Dashboard → Deployments → Click Latest → Logs

# Or curl the API with verbose output
curl -v https://your-api.vercel.app/health
```

---

## 📝 Environment Variables Reference

### Database Variables

| Variable | Example | Purpose |
|----------|---------|---------|
| `DB_HOST` | `localhost` | Database server host |
| `DB_USER` | `root` | Database username |
| `DB_PASSWORD` | `password123` | Database password |
| `DB_NAME` | `knra_licensing_db` | Database name |

### Flask Variables

| Variable | Values | Purpose |
|----------|--------|---------|
| `FLASK_ENV` | `development`, `production` | Flask environment mode |
| `FLASK_DEBUG` | `True`, `False` | Debug mode (local only) |

### Optional Variables

| Variable | Example | Purpose |
|----------|---------|---------|
| `API_PORT` | `5000` | API port (default: 5000) |
| `API_HOST` | `0.0.0.0` | API host (default: 0.0.0.0) |
| `CORS_ORIGINS` | `https://domain.com` | Allowed CORS origins |

---

## 🔒 Security Best Practices

### DO ✅
```
✅ Use strong passwords
✅ Store passwords in .env (local) or Vercel Secrets
✅ Rotate passwords regularly
✅ Use unique credentials per environment
✅ Limit database user permissions
✅ Enable SSL/TLS for database connection
✅ Audit environment variable access
```

### DON'T ❌
```
❌ Hardcode credentials in app.py
❌ Commit .env to GitHub
❌ Share credentials via email/chat
❌ Use same credentials for dev/prod
❌ Log environment variables
❌ Display passwords in error messages
```

### .gitignore Configuration

Ensure `.gitignore` includes:
```
.env
.env.local
.env.*.local
*.pem
*.key
.DS_Store
__pycache__/
*.pyc
venv/
.venv/
node_modules/
```

---

## 🔄 Different Configurations

### Development (Local)
```bash
# .env file
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=root
DB_NAME=knra_licensing_db
FLASK_ENV=development
FLASK_DEBUG=True
```

### Staging (Cloud - Test)
```bash
# Vercel Environment Variables (Preview)
DB_HOST=staging-db.mysql.com
DB_USER=staging_user
DB_PASSWORD=staging_password
DB_NAME=knra_staging
FLASK_ENV=production
```

### Production (Cloud - Live)
```bash
# Vercel Environment Variables (Production)
DB_HOST=prod-db.mysql.com
DB_USER=prod_user
DB_PASSWORD=prod_password
DB_NAME=knra_licensing_db
FLASK_ENV=production
```

---

## 📊 Vercel Environment Hierarchy

```
┌─────────────────────────────────────────┐
│  Vercel Environment Variables            │
├─────────────────────────────────────────┤
│                                         │
│  Production Environment                 │
│  └─ Variables for live API              │
│  └─ Domain: your-api.vercel.app        │
│                                         │
│  Preview Environment                    │
│  └─ Variables for preview builds        │
│  └─ Domain: your-api-pr-123.vercel.app │
│                                         │
│  Development Environment                │
│  └─ Variables for local dev             │
│  └─ Used by: vercel dev                 │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🐛 Troubleshooting

### Issue: "No Environment Variables Found"
```bash
# Solution 1: Check .env file exists
ls -la .env

# Solution 2: Verify .env format (no spaces around =)
# Correct: DB_HOST=localhost
# Wrong:   DB_HOST = localhost

# Solution 3: Reload environment
source .env  # (Mac/Linux)
# or restart terminal (Windows)
```

### Issue: "Database Connection Failed on Vercel"
```
✓ Check DB_HOST, DB_USER, DB_PASSWORD in Vercel Settings
✓ Verify cloud database credentials are correct
✓ Test cloud database connection locally:
  mysql -h <host> -u <user> -p<password>
✓ Check firewall allows Vercel IPs
✓ Redeploy after adding variables
```

### Issue: "Timeout Connecting to Database"
```
✓ Cloud database may be slow/sleeping
✓ PlanetScale: Ensure database is running (not paused)
✓ AWS RDS: Check instance type (t2.micro is slow)
✓ Increase Vercel function timeout: maxDuration: 60 in vercel.json
```

### Issue: "Connection Refused"
```
✓ Check DB_HOST is correct (not localhost on Vercel)
✓ Verify DB_PASSWORD doesn't have special characters (escape if needed)
✓ Check database user exists and has proper permissions
✓ Test connection: mysql -h <host> -u <user> -p<password>
```

---

## ✅ Verification Checklist

### Local Development
- [ ] .env file created from .env.example
- [ ] Database credentials entered correctly
- [ ] MySQL running locally (`Get-Service MySQL80 | Start-Service`)
- [ ] app.py starts without errors
- [ ] localhost:5000 responds to requests
- [ ] Database queries execute successfully

### Cloud Deployment
- [ ] Cloud MySQL database created
- [ ] Schema uploaded and tables visible
- [ ] Sample data loaded successfully
- [ ] Vercel project created
- [ ] Code pushed to GitHub
- [ ] Environment variables added to Vercel
- [ ] Project redeployed after adding variables
- [ ] Live URL responds to requests
- [ ] All endpoints return data (not connection errors)

---

## 🚀 Quick Setup Commands

### Local Setup
```bash
# 1. Copy template
cp .env.example .env

# 2. Edit .env with your credentials
nano .env  # or use any editor

# 3. Start MySQL
Get-Service MySQL80 | Start-Service

# 4. Run API
python app.py

# 5. Test
curl http://localhost:5000/health
```

### Vercel Setup
```bash
# 1. Push code to GitHub
git add .
git commit -m "Add env variables"
git push

# 2. Go to Vercel Settings → Environment Variables
# 3. Add DB_HOST, DB_USER, DB_PASSWORD, DB_NAME, FLASK_ENV
# 4. Redeploy
# 5. Test: curl https://your-api.vercel.app/health
```

---

## 📚 Reference

### How app.py Uses Environment Variables

```python
import os
from dotenv import load_dotenv

# Load from .env file
load_dotenv()

# Use in code
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),      # default: localhost
    'user': os.getenv('DB_USER', 'root'),            # default: root
    'password': os.getenv('DB_PASSWORD', 'root'),    # default: root
    'database': os.getenv('DB_NAME', 'knra_licensing_db')
}

# Flask environment
FLASK_ENV = os.getenv('FLASK_ENV', 'development')
DEBUG_MODE = FLASK_ENV != 'production'
```

### How Vercel Injects Variables

Vercel automatically sets environment variables from Settings before running your code:
```
1. Vercel reads Settings → Environment Variables
2. Sets them in process.env (accessible as os.environ in Python)
3. Your app.py reads: os.getenv('DB_HOST')
4. Everything happens before any endpoint is called
```

---

## 🎯 Success Indicators

✅ Local: App starts and connects to localhost MySQL  
✅ Local: Health check at http://localhost:5000/health  
✅ Vercel: Project status shows "Ready"  
✅ Vercel: Environment variables visible in Settings  
✅ Vercel: Health check at https://your-api.vercel.app/health  
✅ Vercel: All endpoints return data (no connection errors)  
✅ Database: Queries execute successfully  
✅ Response: < 500ms latency average  

---

**Configured & Ready!** 🎉

Your environment variables are now configured for both local development and cloud deployment on Vercel.

Next: Test the live API endpoints!
