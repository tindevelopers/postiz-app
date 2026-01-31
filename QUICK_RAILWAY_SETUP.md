# Quick Railway Setup - 5 Minute Guide

## Current Status
Your Railway project: `postiz-docker-compose` is partially configured.

## What We Need to Add

### 1. Elasticsearch (CRITICAL!)
Without Elasticsearch, you'll get the same error we fixed locally: 
`Unable to create search attributes: cannot have more than 3`

**Add it now:**
1. Go to: https://railway.com/deploy/elasticsearch
2. Click "Deploy Now"
3. Select your project: **postiz-docker-compose**
4. Deploy

### 2. Redis (For Caching)
1. In Railway Dashboard → Your Project
2. Click "+ New" → Database → Redis
3. Deploy

### 3. Second PostgreSQL (For Temporal)
If you don't have a separate PostgreSQL for Temporal:
1. Click "+ New" → Database → PostgreSQL
2. Rename it to: `temporal-postgres`
3. Deploy

## Environment Variables to Update

### In Postiz Service:

```bash
# Add these via Railway Dashboard → postiz → Variables:
TEMPORAL_ADDRESS=temporal.railway.internal:7233
REDIS_URL=${{Redis.REDIS_URL}}
STORAGE_PROVIDER=local
UPLOAD_DIRECTORY=/uploads
RUN_CRON=true
```

### In Temporal Service:

```bash
# Add these via Railway Dashboard → Temporal → Variables:
ENABLE_ES=true
ES_SEEDS=elasticsearch.railway.internal
ES_VERSION=v7
DB=postgres12
POSTGRES_SEEDS=temporal-postgres.railway.internal
```

## Quick Commands

```bash
# Check current variables
railway variables

# Update Postiz variables
railway variables set TEMPORAL_ADDRESS="temporal.railway.internal:7233"
railway variables set REDIS_URL='${{Redis.REDIS_URL}}'
railway variables set RUN_CRON="true"

# Redeploy
railway up --detach

# Watch logs
railway logs --follow
```

## Verification Steps

1. **Check Services Running:**
   ```bash
   railway status
   ```

2. **Test Application:**
   - Open: https://postiz-production-3ae9.up.railway.app
   - Register an account
   - Should work without 502 errors

3. **Test Temporal Integration:**
   - Create a scheduled post
   - Check Temporal UI for workflows
   - Should see 2 workflows running

4. **Verify Elasticsearch Connection:**
   ```bash
   railway logs --service Temporal | grep -i elasticsearch
   ```
   Should show: "Connected to Elasticsearch"

## Troubleshooting

### If you get "Backend failed to start"
```bash
railway logs | grep ERROR
# Common fix: Ensure TEMPORAL_ADDRESS is set correctly
```

### If you get "Search attributes error"
```bash
# Elasticsearch not connected properly
# Check Temporal variables include:
# - ENABLE_ES=true
# - ES_SEEDS=elasticsearch.railway.internal
```

### If login doesn't work
```bash
# Check URLs match:
railway variables | grep URL
# All should use: https://postiz-production-3ae9.up.railway.app
```

## Complete Architecture

After setup, you'll have:
```
Railway Project: postiz-docker-compose
├── postiz (main app)
├── Postgres (Postiz data)
├── temporal-postgres (Temporal data)
├── Redis (cache)
├── Elasticsearch (search)
├── Temporal (server)
├── Temporal UI
└── Temporal Basic Auth
```

## Time Estimate
- Add services: 5-10 minutes
- Configure variables: 5 minutes
- Deploy & verify: 10 minutes
**Total: ~20-30 minutes**

## Cost Estimate
- Postiz: $5-10/month
- PostgreSQL (2x): $10-15/month  
- Redis: $5/month
- Elasticsearch: $10-15/month
- Temporal: $5-10/month
**Total: ~$35-60/month**

_(Railway includes $5/month free credits)_
