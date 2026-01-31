# Railway Deployment Guide for Postiz

## Prerequisites
- Railway CLI installed (`railway --version`)
- Logged into Railway (`railway whoami`)
- Git repository (optional, but recommended)

## Deployment Steps

### Option 1: Deploy via Railway Web UI (Recommended)

1. **Create a new project on Railway:**
   - Go to https://railway.app
   - Click "New Project"
   - Select "Deploy from GitHub repo" (if you have a repo) or "Empty Project"

2. **Add PostgreSQL service:**
   - In your Railway project, click "+ New"
   - Select "Database" → "PostgreSQL"
   - Railway will automatically create a `DATABASE_URL` environment variable

3. **Add Redis service:**
   - Click "+ New" again
   - Select "Database" → "Redis"
   - Railway will automatically create a `REDIS_URL` environment variable

4. **Deploy Postiz service:**
   - Click "+ New" → "GitHub Repo" (or "Empty Service")
   - If using GitHub, select your repository
   - Railway will detect the Dockerfile and deploy automatically

5. **Configure Environment Variables:**
   - Go to your Postiz service → Variables
   - Add the following required variables:

```bash
# Required Settings (update with your Railway URLs)
MAIN_URL=https://your-app-name.up.railway.app
FRONTEND_URL=https://your-app-name.up.railway.app
NEXT_PUBLIC_BACKEND_URL=https://your-app-name.up.railway.app/api
JWT_SECRET=<generate-a-random-secret-string>
DATABASE_URL=${{Postgres.DATABASE_URL}}  # Reference Railway's PostgreSQL service
REDIS_URL=${{Redis.REDIS_URL}}  # Reference Railway's Redis service
BACKEND_INTERNAL_URL=http://localhost:3000
# Do NOT set TEMPORAL_ADDRESS on Railway (no Temporal server) - omit it to avoid 502 on signup
IS_GENERAL=true
DISABLE_REGISTRATION=false
RUN_CRON=true

# Storage Settings
STORAGE_PROVIDER=local
UPLOAD_DIRECTORY=/uploads
NEXT_PUBLIC_UPLOAD_DIRECTORY=/uploads

# Port (Railway sets this automatically)
PORT=5000
```

### Option 2: Deploy via Railway CLI

Run these commands in your terminal:

```bash
# 1. Create a new project (interactive)
railway init

# 2. Add PostgreSQL service
railway add postgresql

# 3. Add Redis service  
railway add redis

# 4. Link environment variables
railway variables set MAIN_URL=https://your-app-name.up.railway.app
railway variables set FRONTEND_URL=https://your-app-name.up.railway.app
railway variables set NEXT_PUBLIC_BACKEND_URL=https://your-app-name.up.railway.app/api
railway variables set JWT_SECRET=$(openssl rand -hex 32)
railway variables set DATABASE_URL=${{Postgres.DATABASE_URL}}
railway variables set REDIS_URL=${{Redis.REDIS_URL}}
railway variables set BACKEND_INTERNAL_URL=http://localhost:3000
# Do not set TEMPORAL_ADDRESS on Railway
railway variables set IS_GENERAL=true
railway variables set DISABLE_REGISTRATION=false
railway variables set RUN_CRON=true
railway variables set STORAGE_PROVIDER=local
railway variables set UPLOAD_DIRECTORY=/uploads
railway variables set NEXT_PUBLIC_UPLOAD_DIRECTORY=/uploads
railway variables set PORT=5000

# 5. Deploy
railway up
```

## Important Notes

1. **Temporal Services**: The current docker-compose.yaml includes Temporal workflow engine services. Railway doesn't support multi-container Docker Compose deployments easily. You may need to:
   - Deploy Temporal separately, OR
   - Use Railway's Docker Compose plugin (if available), OR
   - Simplify the deployment to just Postiz + PostgreSQL + Redis

2. **Environment Variables**: Railway automatically provides:
   - `DATABASE_URL` for PostgreSQL
   - `REDIS_URL` for Redis
   - `PORT` for the service port
   - `RAILWAY_ENVIRONMENT` for the environment name

3. **Custom Domain**: After deployment, you can add a custom domain in Railway's dashboard.

4. **Volumes**: Railway supports persistent volumes. Make sure to configure volumes for:
   - `/uploads` (user uploads)
   - `/config` (application config)

## Troubleshooting

### Common Startup Errors

1. **"Cannot connect to Temporal"** - Temporal is NOT included in Railway deployment. Either:
   - Remove `TEMPORAL_ADDRESS` from environment variables, OR
   - Deploy Temporal separately on Railway and set the correct address

2. **"Connection refused to PostgreSQL/Redis"** - Make sure you:
   - Added PostgreSQL and Redis services in Railway
   - Used Railway variable references: `${{Postgres.DATABASE_URL}}` and `${{Redis.REDIS_URL}}`

3. **"Port already in use" or health check failures** - Ensure:
   - `PORT=5000` is set
   - No conflicting `startCommand` in railway.toml

4. **Container exits immediately** - Check if:
   - All required environment variables are set (especially `JWT_SECRET`, `DATABASE_URL`, `REDIS_URL`)
   - The URLs are correct (use Railway's provided domain)

### 502 Bad Gateway when creating an account (signup)

A **502 Bad Gateway** on the signup page usually means Railway’s proxy (nginx) did not get a valid response from your app. Common causes:

1. **Temporal not available (most likely)**  
   The app expects a Temporal server at `TEMPORAL_ADDRESS`. On Railway you only run the app, so that host is missing. Signup can trigger workflows that try to connect to Temporal and then hang or fail, and the proxy returns 502.

   **Fix:** In the Railway dashboard → your Postiz service → **Variables**, **remove** `TEMPORAL_ADDRESS` entirely (or leave it unset). Do not set it to `temporal:7233` unless you have Temporal deployed elsewhere and set the real URL.

2. **Database or Redis unreachable**  
   Signup and login both use the database. If `DATABASE_URL` or `REDIS_URL` is wrong, missing, or the linked Postgres/Redis service is down, the backend can error or time out and the proxy returns 502.

   **Fix:** Confirm you have PostgreSQL and Redis services in the same project, and that variables use Railway references: `${{Postgres.DATABASE_URL}}` and `${{Redis.REDIS_URL}}`. Check that those services are running and reachable.

3. **Wrong public URLs**  
   If `MAIN_URL`, `FRONTEND_URL`, or `NEXT_PUBLIC_BACKEND_URL` don’t match your real Railway URL (e.g. `https://postiz-production-3ae9.up.railway.app`), auth/signup callbacks and API calls can fail and appear as 502.

   **Fix:** Set all three to your actual Railway URL; set `NEXT_PUBLIC_BACKEND_URL` to `https://your-actual-domain.up.railway.app/api`.

**Next step:** Reproduce the 502 while watching logs: run `railway logs` (or use the Logs tab in the dashboard), then submit the signup form. Look for connection errors (e.g. Temporal, Postgres, Redis) or stack traces right when the 502 occurs.

### Debugging Commands

```bash
# Check logs
railway logs

# View service status
railway status

# Open dashboard
railway dashboard

# Check environment variables
railway variables

# Redeploy after changes
railway up --detach
```

### Required Environment Variables Checklist

Make sure ALL of these are set in Railway:

| Variable | Example Value | Notes |
|----------|---------------|-------|
| `MAIN_URL` | `https://your-app.up.railway.app` | Your Railway public URL |
| `FRONTEND_URL` | `https://your-app.up.railway.app` | Same as MAIN_URL |
| `NEXT_PUBLIC_BACKEND_URL` | `https://your-app.up.railway.app/api` | Add `/api` suffix |
| `JWT_SECRET` | `<random-32-char-string>` | Generate with `openssl rand -hex 32` |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` | Railway reference syntax |
| `REDIS_URL` | `${{Redis.REDIS_URL}}` | Railway reference syntax |
| `PORT` | `5000` | Required for Railway |
