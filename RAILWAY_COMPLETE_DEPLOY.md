# Complete Railway Deployment Guide - Full Functionality

This guide ensures ALL features working locally will work on Railway, including:
- ✅ 2 PostgreSQL databases (Postiz + Temporal)
- ✅ Elasticsearch (for unlimited Temporal search attributes)
- ✅ Redis (for Postiz caching)
- ✅ Temporal workflows (for post scheduling)
- ✅ All 28+ social media integrations

## Architecture Overview

```
Railway Project
├── Postiz (main app)
├── PostgreSQL #1 (Postiz data)
├── PostgreSQL #2 (Temporal data)
├── Redis (Postiz cache)
├── Elasticsearch (Temporal search)
├── Temporal Server
├── Temporal UI
└── Temporal Worker
```

## Step-by-Step Deployment

### Step 1: Create Railway Project

```bash
railway login
railway init
# Name your project: postiz-full-stack
```

### Step 2: Deploy Elasticsearch First

1. Go to https://railway.com/deploy/elasticsearch
2. Click "Deploy Now"
3. Select your project: `postiz-full-stack`
4. Wait for deployment to complete
5. Note the internal service name (e.g., `elasticsearch`)

**OR via CLI:**

```bash
# Add Elasticsearch template
railway add --template elasticsearch
```

### Step 3: Deploy Temporal with PostgreSQL

1. Go to https://railway.com/deploy/temporal-starter
2. Click "Deploy Now"
3. Select your project: `postiz-full-stack`
4. This adds:
   - Temporal Server
   - Temporal UI
   - PostgreSQL (for Temporal)
   - Worker

**Important:** After Temporal deploys, you need to connect it to Elasticsearch.

### Step 4: Add PostgreSQL for Postiz

```bash
# Add a separate PostgreSQL for Postiz
railway add postgresql
# Rename this service to "postiz-postgres" in the dashboard
```

### Step 5: Add Redis

```bash
railway add redis
```

### Step 6: Configure Temporal to Use Elasticsearch

In Railway Dashboard → Temporal service → Variables, add:

```bash
ENABLE_ES=true
ES_SEEDS=elasticsearch.railway.internal
ES_VERSION=v7
```

Redeploy Temporal after adding these variables.

### Step 7: Deploy Postiz

**Option A: From This Repository**

```bash
# In your postiz-docker-compose directory
railway up
```

**Option B: From Railway Dashboard**

1. Click "+ New" → GitHub Repo
2. Connect your repository
3. Select branch with your configuration

### Step 8: Configure Postiz Environment Variables

Set these in Railway Dashboard → Postiz service → Variables:

```bash
# === URLs (Update after Railway gives you a domain) ===
MAIN_URL=https://your-app.up.railway.app
FRONTEND_URL=https://your-app.up.railway.app
NEXT_PUBLIC_BACKEND_URL=https://your-app.up.railway.app/api

# === Security ===
JWT_SECRET=$(openssl rand -hex 32)

# === Database & Cache (Use Railway references) ===
DATABASE_URL=${{postiz-postgres.DATABASE_URL}}
REDIS_URL=${{Redis.REDIS_URL}}

# === Temporal Connection ===
TEMPORAL_ADDRESS=temporal.railway.internal:7233

# === Core Settings ===
BACKEND_INTERNAL_URL=http://localhost:3000
IS_GENERAL=true
DISABLE_REGISTRATION=false
RUN_CRON=true

# === Storage ===
STORAGE_PROVIDER=local
UPLOAD_DIRECTORY=/uploads
NEXT_PUBLIC_UPLOAD_DIRECTORY=/uploads

# === Port ===
PORT=5000

# === Optional: Social Media API Keys ===
# Add your API keys here as needed
X_API_KEY=
LINKEDIN_CLIENT_ID=
# ... etc
```

### Step 9: Configure Temporal Database Connection

In Railway Dashboard → Temporal service → Variables, ensure:

```bash
DB=postgres12
DB_PORT=5432
POSTGRES_USER=${{Postgres-Temporal.POSTGRES_USER}}
POSTGRES_PWD=${{Postgres-Temporal.POSTGRES_PASSWORD}}
POSTGRES_SEEDS=postgres-temporal.railway.internal
DYNAMIC_CONFIG_FILE_PATH=config/dynamicconfig/development-sql.yaml
ENABLE_ES=true
ES_SEEDS=elasticsearch.railway.internal
ES_VERSION=v7
TEMPORAL_NAMESPACE=default
```

### Step 10: Add Persistent Volumes

For each service that needs persistent storage:

**Postiz:**
- `/uploads` - user uploaded media
- `/config` - application configuration

**Elasticsearch:**
- `/usr/share/elasticsearch/data` - search index data

**PostgreSQL services:**
- Automatically handled by Railway

In Railway Dashboard:
1. Go to each service
2. Click "Settings" → "Volumes"
3. Add volume with mount path

### Step 11: Generate Public Domain

```bash
railway domain
# Or in dashboard: Settings → Networking → Generate Domain
```

Update your environment variables with the new domain.

### Step 12: Verify Deployment

```bash
# Check all services are running
railway status

# View logs
railway logs --service postiz
railway logs --service temporal

# Test the application
curl https://your-app.up.railway.app/
```

## Service Dependencies

Ensure proper startup order by setting these in Railway Dashboard:

```
Postiz depends on:
  - postiz-postgres (healthy)
  - Redis (healthy)
  - Temporal (started)

Temporal depends on:
  - postgres-temporal (healthy)
  - Elasticsearch (started)
```

## Environment Variables Summary

| Service | Key Variables |
|---------|--------------|
| **Postiz** | DATABASE_URL, REDIS_URL, TEMPORAL_ADDRESS, JWT_SECRET, MAIN_URL |
| **Temporal** | POSTGRES_SEEDS, ENABLE_ES=true, ES_SEEDS, ES_VERSION=v7 |
| **Elasticsearch** | (Auto-configured by Railway template) |
| **PostgreSQL (Postiz)** | (Auto-configured) |
| **PostgreSQL (Temporal)** | (Auto-configured) |
| **Redis** | (Auto-configured) |

## Cost Optimization

Railway pricing is based on resource usage. Approximate monthly costs:

- Postiz: ~$5-10
- PostgreSQL x2: ~$10-15
- Redis: ~$5
- Elasticsearch: ~$10-15
- Temporal: ~$5-10
- **Total: ~$35-60/month**

To reduce costs:
- Use Railway's $5 free tier
- Scale down Elasticsearch memory (set ES_JAVA_OPTS=-Xms256m -Xmx256m)
- Use smaller PostgreSQL instances for development

## Monitoring & Maintenance

### Check Service Health

```bash
# View all services
railway status

# Check specific service logs
railway logs --service postiz
railway logs --service temporal
railway logs --service elasticsearch

# Monitor workflows
# Visit: https://temporal-ui.up.railway.app
```

### View Users (Admin Script)

Since Railway doesn't have direct database access like Docker, use Railway CLI:

```bash
# Connect to Postiz database
railway run --service postiz-postgres psql $DATABASE_URL

# Then run SQL:
SELECT email, "isSuperAdmin", activated FROM "User";
```

### Backup Strategy

1. **Database Backups:**
   - Railway provides automatic backups for PostgreSQL
   - Configure backup schedule in Railway Dashboard

2. **Volume Backups:**
   - Use Railway's volume snapshot feature
   - Export critical data periodically

## Troubleshooting

### Temporal Search Attributes Error

If you see: `Unable to create search attributes: cannot have more than 3`

**Solution:** Ensure Elasticsearch is properly connected:

```bash
# Check Temporal variables include:
ENABLE_ES=true
ES_SEEDS=elasticsearch.railway.internal
ES_VERSION=v7

# Redeploy Temporal
railway redeploy --service temporal
```

### Database Connection Issues

```bash
# Check PostgreSQL services are healthy
railway status

# Verify DATABASE_URL format
railway variables --service postiz | grep DATABASE_URL

# Test connection
railway run --service postiz pg_isready -d $DATABASE_URL
```

### Elasticsearch Not Reachable

```bash
# Check Elasticsearch logs
railway logs --service elasticsearch

# Verify internal networking
railway run --service temporal curl http://elasticsearch.railway.internal:9200
```

### Backend 502 Errors

Common causes:
1. Temporal not connected - Check TEMPORAL_ADDRESS
2. Database not ready - Check postiz-postgres health
3. Wrong URLs - Ensure MAIN_URL matches your Railway domain

```bash
# View real-time logs while testing
railway logs --service postiz --follow
```

## Migration from Local to Railway

If you have existing data from local development:

### Export Local Data

```bash
# Export Postiz database
docker exec postiz-postgres pg_dump -U postiz-user postiz-db-local > postiz_backup.sql

# Export uploaded files
docker cp postiz:/uploads ./uploads_backup
```

### Import to Railway

```bash
# Import database
railway run --service postiz-postgres psql $DATABASE_URL < postiz_backup.sql

# Upload files (requires volume mounted)
# Option 1: Use Railway's file upload in dashboard
# Option 2: Deploy with files in repository
```

## Scaling & Performance

As your usage grows:

1. **Upgrade Database Plans:**
   - Railway Dashboard → PostgreSQL → Settings → Plan
   - Choose larger instance size

2. **Add Redis Memory:**
   - Increase Redis memory allocation
   - Configure eviction policies

3. **Scale Elasticsearch:**
   - Increase ES_JAVA_OPTS heap size
   - Add more Elasticsearch nodes (cluster mode)

4. **Enable Caching:**
   - Configure CDN for static assets
   - Add Redis caching layers

## Security Best Practices

1. **Rotate Secrets Regularly:**
   ```bash
   railway variables set JWT_SECRET=$(openssl rand -hex 32)
   ```

2. **Restrict Access:**
   - Set DISABLE_REGISTRATION=true after initial setup
   - Use environment-specific URLs
   - Enable Railway's IP allowlist

3. **Monitor Logs:**
   - Set up log alerts in Railway
   - Review error logs weekly
   - Monitor failed login attempts

## Complete Deployment Checklist

- [ ] Elasticsearch deployed and healthy
- [ ] Temporal + PostgreSQL deployed
- [ ] Temporal configured with Elasticsearch (ENABLE_ES=true)
- [ ] Postiz PostgreSQL created
- [ ] Redis added
- [ ] Postiz deployed with all env vars
- [ ] Public domain generated
- [ ] URLs updated in Postiz env vars
- [ ] Volumes configured for persistent storage
- [ ] Health checks passing for all services
- [ ] Test user registration works
- [ ] Test Temporal workflows (create a scheduled post)
- [ ] Test social media connections
- [ ] Verify 2 Temporal workflows running (check Temporal UI)
- [ ] Backup strategy configured

## Next Steps After Deployment

1. **Test Complete Flow:**
   - Register an account
   - Connect a social media account
   - Schedule a post
   - Verify it appears in Temporal UI
   - Check database for stored data

2. **Configure Social Media APIs:**
   - Add API keys for platforms you'll use
   - Test OAuth flows

3. **Set Up Monitoring:**
   - Enable Railway notifications
   - Configure uptime monitoring
   - Set up error alerting

4. **Document Your Setup:**
   - Note all service names
   - Save environment variable values (encrypted)
   - Document custom configurations

## Support & Resources

- Railway Docs: https://docs.railway.app
- Postiz Docs: https://docs.postiz.com
- Temporal Docs: https://docs.temporal.io
- Railway Discord: https://discord.gg/railway
- Postiz Discord: https://discord.postiz.com
