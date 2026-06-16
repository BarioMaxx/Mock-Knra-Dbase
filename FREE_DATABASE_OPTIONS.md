# Free Database Options for Vercel Deployment

**Problem**: PlanetScale billing despite "free tier"  
**Solution**: Multiple truly free alternatives

---

## 🆓 Completely Free Options

### Option 1: Railway (RECOMMENDED - Easiest)
**Cost**: Free tier covers most small projects, pay-as-you-go if exceeds  
**Uptime**: 99.9%  
**Speed**: Fast  
**Setup Time**: 5 minutes

```bash
# 1. Go to https://railway.app
# 2. Sign up with GitHub
# 3. Create new project → MySQL
# 4. Railway generates credentials automatically
# 5. Load schema:
mysql -h <host> -u <user> -p<password> knra_licensing_db < 01_MySQL_Schema_Creation.sql

# 6. Get connection string from Railway dashboard
# 7. Add to Vercel env vars
```

**Free Tier**: Generous for learning/small projects (~$5/month credit)

---

### Option 2: Render (VERY RELIABLE)
**Cost**: Free tier with 90 days free for new users, then ~$7/month for MySQL  
**Uptime**: 99.99%  
**Speed**: Very fast  
**Setup Time**: 5 minutes

```bash
# 1. Go to https://render.com
# 2. Sign up
# 3. New → MySQL Database
# 4. Wait for creation (~2 min)
# 5. Use connection string from dashboard
# 6. Load schema via command line
```

**Note**: After 90 days, will cost ~$7/month but extremely reliable

---

### Option 3: TiDB Cloud (FREE - SQL Compatible)
**Cost**: Completely free tier  
**Uptime**: 99.99%  
**Speed**: Good  
**Setup Time**: 5 minutes

```bash
# 1. Go to https://tidbcloud.com
# 2. Sign up with GitHub
# 3. Create cluster (free tier)
# 4. Get MySQL connection details
# 5. Load schema - should work with MySQL clients
```

**Advantage**: Truly free, no billing surprises

---

### Option 4: SQLite on Vercel (SIMPLEST - NO DB SERVER)
**Cost**: Free  
**Uptime**: 100% (file-based)  
**Setup Time**: 10 minutes (code changes needed)  
**Limitation**: Can't access SQLite DB between Vercel rebuilds

```python
# app.py modification - switch from MySQL to SQLite

import sqlite3
from contextlib import contextmanager

@contextmanager
def get_db_connection():
    conn = sqlite3.connect('knra.db')
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()
```

**When to use**: Development/testing only, not production

---

## 🚀 My Recommendation

**BEST OPTION**: **Railway**

Why:
✅ Completely free tier (covers most projects)  
✅ Easiest setup (5 minutes)  
✅ Most reliable  
✅ Good performance  
✅ No surprise billing  
✅ Auto-scales if needed  

---

## 📋 Step-by-Step: Railway Setup

### Step 1: Create Railway Account
```
1. Go to https://railway.app
2. Click "Sign up with GitHub"
3. Authorize Railway
```

### Step 2: Create MySQL Database
```
1. Click "New Project"
2. Select "MySQL"
3. Wait ~1 minute for creation
4. Click on MySQL service
5. Copy connection details:
   - Host: something.railway.internal (or external)
   - User: root
   - Password: (generated)
   - Database: railway
```

### Step 3: Load Schema
```bash
# From your local machine:
mysql -h <RAILWAY_HOST> -u root -p<PASSWORD> railway < 01_MySQL_Schema_Creation.sql
mysql -h <RAILWAY_HOST> -u root -p<PASSWORD> railway < 02_MySQL_Sample_Data.sql

# Verify:
mysql -h <RAILWAY_HOST> -u root -p<PASSWORD> railway -e "SHOW TABLES;"
```

### Step 4: Update Vercel Environment Variables
```
Go to Vercel → Settings → Environment Variables

Add:
DB_HOST = <RAILWAY_HOST>
DB_USER = root
DB_PASSWORD = <RAILWAY_PASSWORD>
DB_NAME = railway
FLASK_ENV = production
```

### Step 5: Redeploy
```
Vercel → Deployments → Redeploy latest
```

### Step 6: Test
```bash
curl https://your-api.vercel.app/health
```

---

## 💰 Cost Comparison

| Provider | Free Tier | After Free | Recommendation |
|----------|-----------|-----------|-----------------|
| **Railway** | Yes (~$5 credit) | ~$0 for small usage | ✅ BEST |
| **Render** | 90 days free | ~$7/month | Good, but not free |
| **TiDB** | Yes, unlimited | No charges | ✅ TRULY FREE |
| **PlanetScale** | ❌ Expensive | Billing issues | ❌ AVOID |
| **SQLite** | Yes (local only) | Free | ✅ Dev/test only |

---

## ⚠️ Warning Signs of Billing

**PlanetScale charges if:**
- ❌ Database >1GB size
- ❌ >10 billion read queries/month
- ❌ >10 billion write queries/month
- ❌ Using production branch (not free)

**Railroad/Railway free tier limits:**
- ✅ $5/month free credit (covers most projects)
- ✅ Auto-pauses after 7 days inactivity
- ✅ No surprise billing

---

## 🔄 Quick Migration Path

**If you already have PlanetScale:**

```bash
# Step 1: Export from PlanetScale
mysqldump -h <ps_host> -u <user> -p<pass> knra_licensing_db > backup.sql

# Step 2: Create Railway database
# (via Railway dashboard)

# Step 3: Import to Railway
mysql -h <railway_host> -u root -p<pass> railway < backup.sql

# Step 4: Update Vercel env vars
# (Vercel → Settings → Environment Variables)

# Step 5: Test
curl https://your-api.vercel.app/health
```

---

## ✅ Verification Checklist

- [ ] Railway account created
- [ ] MySQL database created
- [ ] Schema loaded successfully
- [ ] Sample data loaded
- [ ] Tables verified (SHOW TABLES = 12 tables)
- [ ] Vercel env vars updated
- [ ] Project redeployed
- [ ] Health check responding
- [ ] No billing warnings

---

## 🎯 Final Recommendation

**Use Railway** - Best balance of:
- ✅ Free or very cheap
- ✅ Easy setup
- ✅ No billing surprises  
- ✅ Production ready
- ✅ Fast performance
- ✅ Good support

**Setup time**: 10-15 minutes total

---

**Next Step**: Set up Railway instead of PlanetScale

Would you like me to help with Railway setup?
