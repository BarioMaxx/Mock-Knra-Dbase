# KNRA API - Vercel Deployment Checklist

## Quick Start (15-20 minutes)

### Phase 1: Cloud Database Setup (5 min)

**Choose your database provider:**
- [ ] PlanetScale (https://planetscale.com) - Easiest ⭐
- [ ] AWS RDS (https://aws.amazon.com)
- [ ] Railway.app (https://railway.app) - Fast ⭐
- [ ] Google Cloud SQL (https://cloud.google.com/sql)

**Steps:**
- [ ] Create cloud database account
- [ ] Create new database: `knra_licensing_db`
- [ ] Generate connection credentials
- [ ] Copy: Host, Username, Password

**Upload Schema:**
```bash
mysql -h <cloud-host> -u <username> -p <database> < 01_MySQL_Schema_Creation.sql
mysql -h <cloud-host> -u <username> -p <database> < 02_MySQL_Sample_Data.sql
```
- [ ] Schema uploaded successfully
- [ ] Sample data loaded

---

### Phase 2: GitHub Setup (5 min)

**Create Repository:**
- [ ] Go to https://github.com/new
- [ ] Create repo: `knra-api`
- [ ] Clone locally
- [ ] Copy all files from Mock Dbase folder

**Commit & Push:**
```bash
git add .
git commit -m "Initial KNRA API deployment"
git push origin main
```
- [ ] Code pushed to GitHub
- [ ] All files committed

---

### Phase 3: Vercel Deployment (5-10 min)

**Connect to Vercel:**
- [ ] Go to https://vercel.com
- [ ] Sign in with GitHub
- [ ] Click "Import Project"
- [ ] Select `knra-api` repository
- [ ] Click "Import"

**Configure Project:**
- [ ] Framework: **Other**
- [ ] Build command: **(leave empty)**
- [ ] Output directory: **(leave empty)**
- [ ] Click "Deploy"

**Wait for deployment to complete:**
- [ ] Deployment status: **Ready**
- [ ] Copy your Vercel URL: `https://your-project.vercel.app`

---

### Phase 4: Environment Variables (3 min)

**Add to Vercel:**
1. Go to project Settings
2. Click "Environment Variables"
3. Add each variable:

```
DB_HOST         = your-cloud-host.com
DB_USER         = your_username
DB_PASSWORD     = your_password
DB_NAME         = knra_licensing_db
FLASK_ENV       = production
```

- [ ] All variables added
- [ ] Click "Save"
- [ ] Redeploy project

---

### Phase 5: Testing (2 min)

**Test Health Check:**
```bash
curl https://your-project.vercel.app/health
```
Expected: `{"status":"healthy","database":"connected"}`
- [ ] ✅ Health check passing

**Test API Endpoints:**
```bash
curl https://your-project.vercel.app/api/facilities
curl https://your-project.vercel.app/api/licenses
curl https://your-project.vercel.app/api/equipment
curl https://your-project.vercel.app/api/reports/kpis
```
- [ ] ✅ All endpoints responding
- [ ] ✅ No database errors
- [ ] ✅ Response times acceptable

---

## Post-Deployment Tasks

### Verify Deployment
- [ ] API is accessible from browser
- [ ] All 25+ endpoints working
- [ ] Database queries executing
- [ ] No error logs in Vercel dashboard
- [ ] Response time < 500ms average

### Documentation
- [ ] Update README with live API URL
- [ ] Share Vercel link with team
- [ ] Document database connection method
- [ ] Add deployment process to wiki

### Monitoring
- [ ] Check Vercel Analytics dashboard
- [ ] Review error logs
- [ ] Monitor database performance
- [ ] Set up alerts (optional)

### Security (Before Production)
- [ ] Change database password
- [ ] Add JWT authentication
- [ ] Enable CORS restrictions
- [ ] Add rate limiting
- [ ] Review security settings

---

## Files Created/Modified

✅ **New Files:**
- `vercel.json` - Vercel configuration
- `api.py` - Serverless function wrapper
- `VERCEL_DEPLOYMENT_GUIDE.md` - Detailed guide

✅ **Modified Files:**
- `requirements.txt` - Added gunicorn & Werkzeug
- `app.py` - Added production mode support

✅ **Existing Files (Ready to Deploy):**
- `app.py` - Flask REST API (25+ endpoints)
- `01_MySQL_Schema_Creation.sql` - Database schema
- `02_MySQL_Sample_Data.sql` - Sample data
- `03_MySQL_Queries_Reporting.sql` - Query examples
- All documentation files

---

## Database Connection Matrix

| Provider | Setup Time | Cost | Free Tier | Recommended |
|----------|-----------|------|-----------|-------------|
| **PlanetScale** | 2 min | $39/mo | YES ⭐ | YES |
| **Railway.app** | 5 min | $5/mo | YES | YES |
| **AWS RDS** | 10 min | $15/mo | YES (12mo) | NO |
| **Google Cloud** | 10 min | $5/mo | YES | MAYBE |

---

## Common Commands

### Deploy to Vercel
```bash
cd knra-api
git add .
git commit -m "Deploy updates"
git push
# Vercel auto-deploys on push!
```

### Test Live API
```bash
# Health check
curl https://your-project.vercel.app/health

# Get facilities
curl https://your-project.vercel.app/api/facilities

# Get licenses
curl https://your-project.vercel.app/api/licenses

# Get KPIs
curl https://your-project.vercel.app/api/reports/kpis
```

### View Logs
```
Vercel Dashboard → Deployments → Logs
```

### Rollback Deployment
```
Vercel Dashboard → Deployments → Click previous version
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| **Database Connection Error** | Check credentials in Vercel env vars |
| **Timeout on Vercel** | Database may be slow, upgrade cloud tier |
| **Module Not Found** | Add to requirements.txt, redeploy |
| **CORS Error** | Update CORS_ORIGINS in app.py |
| **No logs showing** | Check Vercel Logs, not local logs |
| **API slow** | Check database response time |

---

## Success Criteria

Your deployment is successful when:

✅ Vercel shows "Ready" status
✅ Live URL is accessible
✅ Health check returns 200 OK
✅ All 25+ endpoints respond
✅ Database queries execute
✅ No error logs in Vercel
✅ Response time < 500ms
✅ Team can access API
✅ Data is persistent

---

## Next Steps

**Immediate:**
1. Share live URL with team
2. Update API documentation
3. Test all workflows

**This Week:**
1. Add JWT authentication
2. Set up rate limiting
3. Monitor performance

**This Month:**
1. Create web dashboard
2. Build mobile app
3. Migrate production data

**This Quarter:**
1. Add caching layer
2. Scale database
3. Deploy to multiple regions

---

## Support

- **Vercel Docs**: https://vercel.com/docs
- **PlanetScale Docs**: https://planetscale.com/docs
- **Flask Docs**: https://flask.palletsprojects.com/
- **MySQL Docs**: https://dev.mysql.com/doc/

---

## Live API Example

Once deployed, your API will be live at:

```
https://your-project-name.vercel.app

Examples:
- GET  https://your-project-name.vercel.app/health
- GET  https://your-project-name.vercel.app/api/facilities
- GET  https://your-project-name.vercel.app/api/licenses
- GET  https://your-project-name.vercel.app/api/equipment
- GET  https://your-project-name.vercel.app/api/inspections
- GET  https://your-project-name.vercel.app/api/reports/kpis
- POST https://your-project-name.vercel.app/api/facilities
```

---

**Ready to Deploy?** Follow the phases above in order. Estimated total time: 15-20 minutes.

**Stuck?** Check VERCEL_DEPLOYMENT_GUIDE.md for detailed instructions.
