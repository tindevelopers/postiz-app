# Railway Deployment - Manual Steps Required

## Variables Must Be Set Via Web Dashboard

The Railway CLI doesn't support setting variables directly. All configuration must be done via the web dashboard.

## Complete Setup Instructions

### 1. Add Elasticsearch (CRITICAL - Already Opened)

The browser has opened: https://railway.com/deploy/elasticsearch

1. Click "Deploy Now"  
2. Select project: **postiz-docker-compose**
3. Wait for deployment to complete (~2-3 minutes)

### 2. Add Redis (If Not Present)

1. Go to Railway Dashboard: https://railway.app
2. Open your project: **postiz-docker-compose**
3. Click "+ New" button
4. Select "Database" → "Redis"
5. Click "Add Redis"

### 3. Check/Add Second PostgreSQL

1. In your project dashboard, check if you have 2 PostgreSQL services
2. One should be for Postiz, one for Temporal
3. If only one exists:
   - Click "+ New"
   - Select "Database" → "PostgreSQL"
   - Rename it to "temporal-postgres"

### 4. Configure Postiz Service Variables

Go to: **postiz** service → **Variables** tab

Add or update these:

```
TEMPORAL_ADDRESS=temporal.railway.internal:7233
REDIS_URL=${{Redis.REDIS_URL}}
RUN_CRON=true
STORAGE_PROVIDER=local
UPLOAD_DIRECTORY=/uploads
```

### 5. Configure Temporal Service Variables  

Go to: **Temporal** service → **Variables** tab

Add these NEW variables:

```
ENABLE_ES=true
ES_SEEDS=elasticsearch.railway.internal
ES_VERSION=v7
```

Keep existing Temporal variables as they are.

### 6. Add Persistent Volumes

**For Postiz service:**
1. Go to **postiz** → **Settings** → **Volumes**
2. Click "New Volume"
3. Mount path: `/uploads`
4. Size: 1GB or more
5. Click "Add"

6. Add another volume:
7. Mount path: `/config`
8. Size: 100MB
9. Click "Add"

**For Elasticsearch service:**
1. Go to **elasticsearch** → **Settings** → **Volumes**
2. Click "New Volume"
3. Mount path: `/usr/share/elasticsearch/data`
4. Size: 2GB or more
5. Click "Add"

### 7. Redeploy Services

After adding all variables:

1. Go to **Temporal** service → **Deployments**
2. Click "Redeploy" (to pick up Elasticsearch variables)

3. Go to **postiz** service → **Deployments**
4. Click "Redeploy" (to pick up new variables)

### 8. Verify Deployment

Wait 5-10 minutes for all services to be healthy, then test:

1. **Check Application:**
   - Open: https://postiz-production-3ae9.up.railway.app
   - Should load without 502 errors

2. **Test Registration:**
   - Go to `/auth`
   - Create an account
   - Should work without errors

3. **Check Logs:**
   In Railway Dashboard:
   - **postiz** logs: Look for "Backend is running on: http://localhost:3000"
   - **Temporal** logs: Look for "Connected to Elasticsearch"

4. **Test Temporal Workflows:**
   - Create a scheduled post in Postiz
   - Open Temporal UI (find URL in Temporal UI service)
   - Should see workflows appearing

## Troubleshooting

### If Postiz won't start:
- Check **postiz** logs for errors
- Verify `TEMPORAL_ADDRESS` is set to `temporal.railway.internal:7233`
- Verify `REDIS_URL` references exist (e.g., `${{Redis.REDIS_URL}}`)

### If you get "Search attributes" error:
- Check **Temporal** logs
- Verify Elasticsearch variables are set:
  - `ENABLE_ES=true`
  - `ES_SEEDS=elasticsearch.railway.internal`
  - `ES_VERSION=v7`
- Redeploy Temporal service

### If login doesn't work:
- Verify all URL variables match your Railway domain
- Check that `MAIN_URL`, `FRONTEND_URL`, and `NEXT_PUBLIC_BACKEND_URL` all use `https://postiz-production-3ae9.up.railway.app`

## Quick Reference

**Your Railway Project:** postiz-docker-compose
**Your Domain:** https://postiz-production-3ae9.up.railway.app
**Project Dashboard:** https://railway.app/project/f7c9f463-0550-48de-9405-096684e31278

## Final Service List

After completion, you should have:
- ✅ postiz (main app)
- ✅ Postgres (Postiz data)
- ✅ Postgres (Temporal data) - may be named "postgres-temporal" or similar
- ✅ Redis (caching)
- ✅ Elasticsearch (search - NEW!)
- ✅ Temporal (server)
- ✅ Temporal UI (monitoring)
- ✅ Temporal Basic Auth (UI auth)

Total: 8 services

## Estimated Time
- Add Elasticsearch: 5 minutes
- Add/verify Redis & PostgreSQL: 5 minutes
- Configure variables: 10 minutes
- Add volumes: 5 minutes
- Deploy & verify: 10 minutes

**Total: ~35 minutes**
