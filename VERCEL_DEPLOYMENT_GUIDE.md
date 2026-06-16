# KNRA API - Vercel Deployment Guide

**Status**: Ready for cloud deployment  
**Platform**: Vercel (serverless)  
**Database**: Cloud MySQL required  
**Estimated Setup Time**: 15-20 minutes

---

## ⚠️ Important Prerequisites

### Cloud MySQL Database Required

Vercel cannot connect to localhost MySQL. You need a **cloud-hosted MySQL** instance. Choose one:

#### Option 1: **PlanetScale** (Recommended - FREE tier available)
- URL: https://planetscale.com
- Free tier: Good for development/testing
- Setup: 2 minutes
- Cost: Free (with limitations)

#### Option 2: **AWS RDS**
- Free tier: 12 months free for t2.micro
- Cost: Free first year, then ~$15-30/month
- Setup: 10-15 minutes

#### Option 3: **Google Cloud SQL**
- Free tier: $6.50 credit/month
- Setup: 10-15 minutes

#### Option 4: **Railway.app**
- Free tier: $5 credit/month (enough for testing)
- Setup: 5 minutes
- URL: https://railway.app

---

## 📋 Step 1: Set Up Cloud MySQL Database

### Using PlanetScale (Easiest - Recommended)

1. Go to https://planetscale.com
2. Sign up (free)
3. Create a new database named `knra_licensing_db`
4. Go to **Settings** → **Passwords** → Create a new password
5. Copy the connection string:
   ```
   Host: xxxx.mysql.planetscale.com
   Username: xxxx
   Password: pscale_xxxx
   Database: knra_licensing_db
   Port: 3306
   ```
6. Connect to your cloud database:
   ```bash
   mysql -h xxxx.mysql.planetscale.com -u xxxx -p
   ```
7. Load the schema and data:
   ```bash
   mysql -h xxxx.mysql.planetscale.com -u xxxx -p knra_licensing_db < 01_MySQL_Schema_Creation.sql
   mysql -h xxxx.mysql.planetscale.com -u xxxx -p knra_licensing_db < 02_MySQL_Sample_Data.sql
   ```

---

## 📋 Step 2: Push Code to GitHub

### Create a GitHub Repository

1. Go to https://github.com/new
2. Create repository: `knra-api`
3. Clone it locally:
   ```bash
   git clone https://github.com/yourusername/knra-api.git
   cd knra-api
   ```
4. Copy all files from `Mock Dbase` folder:
   ```bash
   # Copy all .sql, .md, .py, .txt, .json files
   ```
5. Create `.gitignore`:
   ```
   .env
   .env.local
   *.pyc
   __pycache__/
   .DS_Store
   node_modules/
   .venv/
   venv/
   ```
6. Commit and push:
   ```bash
   git add .
   git commit -m "Initial KNRA API deployment to Vercel"
   git push origin main
   ```

---

## 📋 Step 3: Deploy to Vercel

### Connect GitHub to Vercel

1. Go to https://vercel.com
2. Sign up (free with GitHub)
3. Click **Import Project**
4. Select your `knra-api` repository
5. Click **Import**
6. Configure project settings:
   - Framework: Other
   - Build command: (leave empty)
   - Output directory: (leave empty)

### Add Environment Variables

1. On Vercel project page, go to **Settings** → **Environment Variables**
2. Add these variables:
   ```
   DB_HOST = your-mysql-host.com
   DB_USER = your_username
   DB_PASSWORD = your_password
   DB_NAME = knra_licensing_db
   FLASK_ENV = production
   ```
3. Click **Save**
4. Redeploy to apply variables

---

## 📋 Step 4: Test the Deployment

Once deployment completes:

```bash
# Test health check
curl https://your-project.vercel.app/health

# Test facilities endpoint
curl https://your-project.vercel.app/api/facilities

# Test API
curl https://your-project.vercel.app/api/reports/kpis
```

---

## 🔧 Configuration Files Created

### `vercel.json`
- Tells Vercel how to build and run the Flask app
- Routes all requests to Flask
- Sets environment variables

### `api.py`
- Wrapper for Vercel serverless deployment
- Exports the Flask app

### Updated `requirements.txt`
- Added gunicorn (production server)
- Added Werkzeug (WSGI middleware)

---

## 📊 Deployment Architecture

```
┌─────────────────────────────────────────┐
│         User's Browser/App              │
│      (Web, Mobile, Desktop)             │
└──────────────┬──────────────────────────┘
               │ HTTPS Request
               ▼
┌─────────────────────────────────────────┐
│    Vercel Edge Network (Cached)         │
└──────────────┬──────────────────────────┘
               │ Route to Function
               ▼
┌─────────────────────────────────────────┐
│  Flask API (Serverless Function)        │
│  - app.py (350+ lines)                  │
│  - 25+ REST Endpoints                   │
└──────────────┬──────────────────────────┘
               │ Query/Insert
               ▼
┌─────────────────────────────────────────┐
│  Cloud MySQL Database                   │
│  - PlanetScale / AWS RDS / etc.         │
│  - knra_licensing_db                    │
│  - 12 Tables, 3 Views                   │
└─────────────────────────────────────────┘
```

---

## 🚀 Complete Deployment Steps

### 1. Set up Cloud MySQL (5 min)
```bash
# Example: Using PlanetScale
1. Create account at planetscale.com
2. Create database "knra_licensing_db"
3. Create password
4. Copy connection string
```

### 2. Upload Schema (2 min)
```bash
mysql -h <host> -u <user> -p<password> knra_licensing_db < 01_MySQL_Schema_Creation.sql
mysql -h <host> -u <user> -p<password> knra_licensing_db < 02_MySQL_Sample_Data.sql
```

### 3. Push to GitHub (3 min)
```bash
git clone https://github.com/yourusername/knra-api.git
cd knra-api
# Copy all files here
git add .
git commit -m "Initial commit"
git push
```

### 4. Deploy to Vercel (3 min)
```
1. Go to vercel.com
2. Import GitHub repo
3. Add environment variables
4. Deploy
```

### 5. Test (2 min)
```bash
curl https://your-api.vercel.app/health
```

---

## 📈 Performance & Costs

### Vercel (Free Tier)
- **Functions**: 100 executions/day (free tier)
- **Bandwidth**: 100 GB/month
- **Price**: Free for testing, $20/month for production

### PlanetScale (Free Tier)
- **Storage**: 5 GB
- **Connections**: Sufficient for development
- **Price**: Free for testing, $39/month for production

### Total Monthly Cost
- **Development**: FREE
- **Small Production**: ~$20-40/month

---

## 🔐 Security Considerations

### Before Production

1. **Change Database Password**
   ```bash
   ALTER USER 'username'@'%' IDENTIFIED BY 'strong_password';
   ```

2. **Add Authentication to API**
   ```python
   pip install Flask-JWT-Extended
   # Add JWT token validation to app.py
   ```

3. **Enable HTTPS** (Automatic on Vercel)

4. **Set Secure CORS**
   ```python
   CORS(app, resources={
       r"/api/*": {
           "origins": ["https://your-domain.com"],
           "methods": ["GET", "POST", "PUT", "DELETE"]
       }
   })
   ```

5. **Add Rate Limiting**
   ```python
   pip install Flask-Limiter
   ```

6. **SSL Certificate** (Automatic on Vercel)

---

## 🐛 Troubleshooting

### "Database Connection Error"
```
✓ Check cloud MySQL credentials in .env
✓ Verify host, user, password are correct
✓ Ensure database exists
✓ Check firewall allows your IP
```

### "Timeout Error"
```
✓ Cloud MySQL may be slow (upgrade tier)
✓ Vercel function timeout: 60 seconds
✓ Increase timeout in vercel.json:
  "maxDuration": 60
```

### "Module Not Found"
```
✓ Check requirements.txt has all dependencies
✓ Verify Vercel build logs
✓ Clear Vercel cache and redeploy
```

### "No Environment Variables"
```
✓ Verify in Vercel Settings > Environment Variables
✓ Redeploy after adding variables
✓ Check variable names match app.py
```

---

## 📚 Environment Variables

Create `.env.example` in your repository:

```
DB_HOST=your-mysql-host.com
DB_USER=your_username
DB_PASSWORD=your_password
DB_NAME=knra_licensing_db
FLASK_ENV=production
```

**Never commit real `.env` file to GitHub!**

---

## 🎯 Monitoring & Logs

### View Logs on Vercel
1. Go to your Vercel project
2. Click **Deployments**
3. Click **Logs**
4. See real-time API logs

### Monitor Performance
1. Go to **Analytics**
2. View response times
3. Check error rates
4. Monitor bandwidth usage

---

## 🚀 Custom Domain (Optional)

1. On Vercel project, go to **Settings** → **Domains**
2. Add your domain: `api.your-company.com`
3. Update DNS records (follow Vercel instructions)
4. API will be available at: `https://api.your-company.com`

---

## 📋 Deployment Checklist

- [ ] Cloud MySQL database created
- [ ] Schema uploaded to cloud
- [ ] Sample data loaded
- [ ] GitHub repository created
- [ ] Code pushed to GitHub
- [ ] Vercel project linked
- [ ] Environment variables added
- [ ] Deployment completed
- [ ] Health check passing
- [ ] All endpoints tested
- [ ] Documentation updated with live URL
- [ ] Team notified of new URL

---

## 💡 Next Steps

### Immediate (After Deployment)
1. Test all 25+ endpoints
2. Verify database connectivity
3. Check performance metrics
4. Monitor error logs

### Short Term
1. Add JWT authentication
2. Set up rate limiting
3. Create API keys for clients
4. Document deployment process

### Medium Term
1. Set up CI/CD pipeline
2. Create staging environment
3. Add monitoring & alerting
4. Set up automated backups
5. Scale database if needed

### Long Term
1. Add caching (Redis)
2. Optimize slow queries
3. Scale API horizontally
4. Global CDN distribution
5. Advanced analytics

---

## 📞 Support Resources

- **Vercel Docs**: https://vercel.com/docs
- **Flask Docs**: https://flask.palletsprojects.com/
- **PlanetScale Docs**: https://planetscale.com/docs
- **MySQL Docs**: https://dev.mysql.com/doc/

---

## 🎉 Success Indicators

After deployment, you should see:
- ✅ Live API URL on Vercel dashboard
- ✅ Health check responding
- ✅ All 25+ endpoints accessible
- ✅ Database queries working
- ✅ API latency < 500ms (average)
- ✅ 0 errors in logs

---

## 📊 Live API URLs

Once deployed:

```
Health Check:
https://your-api.vercel.app/health

API Base:
https://your-api.vercel.app/api

Examples:
https://your-api.vercel.app/api/facilities
https://your-api.vercel.app/api/licenses
https://your-api.vercel.app/api/equipment
https://your-api.vercel.app/api/reports/kpis
```

---

**Deployment Guide Complete!** 🚀

Your KNRA API is ready for production deployment on Vercel with a cloud MySQL database.

For specific questions, refer to the respective documentation:
- Vercel: https://vercel.com/docs
- Your Cloud Provider (PlanetScale/AWS/etc.)
- Flask documentation

---

**Last Updated**: June 15, 2026  
**Status**: Ready for Production Deployment
