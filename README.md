
## Watch the Tutorial for docker-compose install:
[https://m.youtube.com/watch?v=A6CjAmJOWvA&t=5s](https://m.youtube.com/watch?v=A6CjAmJOWvA&t=5s)

## Warning
If you are upgrading from Postiz old version, please make sure you update your docker compose, you can read more here:
https://github.com/gitroomhq/postiz-app/releases/tag/v2.12.0

## Docker Compose

This guide assumes that you have docker installed, with a reasonable amount of resources to run Postiz. This Docker Compose setup has been tested with;

- Virtual Machine, Ubuntu 24.04, 2Gb RAM, 2 vCPUs.

<Snippet file="installation-pre-reqs.mdx" />

### Configuration uses environment variables

The docker containers for Postiz are entirely configured with environment variables.

- **Option A** - environment variables in your `docker-compose.yml` file
- **Option B** - environment variables in a `postiz.env` file mounted in `/config` for the Postiz container only
- **Option C** - environment variables in a `.env` file next to your `docker-compose.yml` file (not recommended).

... or a mixture of the above options!

There is a [configuration reference](/configuration/reference) page with a list
of configuration settings.

Setup:
```
git clone https://github.com/gitroomhq/postiz-docker-compose
```

Then run:
```
docker compose up
```

Wait for it to load:

Open your website on https://localhost:4007

---

## Example `docker-compose.yml` file

```yaml
services:
  postiz:
    image: ghcr.io/gitroomhq/postiz-app:v2.12.1
    container_name: postiz
    restart: always
    environment:
      # === Required Settings
      MAIN_URL: 'http://localhost:4007'
      FRONTEND_URL: 'http://localhost:4007'
      NEXT_PUBLIC_BACKEND_URL: 'http://localhost:4007/api'
      JWT_SECRET: 'random string that is unique to every install - just type random characters here!'
      DATABASE_URL: 'postgresql://postiz-user:postiz-password@postiz-postgres:5432/postiz-db-local'
      REDIS_URL: 'redis://postiz-redis:6379'
      BACKEND_INTERNAL_URL: 'http://localhost:3000'
      TEMPORAL_ADDRESS: "temporal:7233"
      IS_GENERAL: 'true'
      DISABLE_REGISTRATION: 'false'

      # === Storage Settings
      STORAGE_PROVIDER: 'local'
      UPLOAD_DIRECTORY: '/uploads'
      NEXT_PUBLIC_UPLOAD_DIRECTORY: '/uploads'

      # === Cloudflare (R2) Settings
      # STORAGE_PROVIDER: 'cloudflare'
      # CLOUDFLARE_ACCOUNT_ID: 'your-account-id'
      # CLOUDFLARE_ACCESS_KEY: 'your-access-key'
      # CLOUDFLARE_SECRET_ACCESS_KEY: 'your-secret-access-key'
      # CLOUDFLARE_BUCKETNAME: 'your-bucket-name'
      # CLOUDFLARE_BUCKET_URL: 'https://your-bucket-url.r2.cloudflarestorage.com/'
      # CLOUDFLARE_REGION: 'auto'

      # === Social Media API Settings
      X_API_KEY: ''
      X_API_SECRET: ''
      LINKEDIN_CLIENT_ID: ''
      LINKEDIN_CLIENT_SECRET: ''
      REDDIT_CLIENT_ID: ''
      REDDIT_CLIENT_SECRET: ''
      GITHUB_CLIENT_ID: ''
      GITHUB_CLIENT_SECRET: ''
      BEEHIIVE_API_KEY: ''
      BEEHIIVE_PUBLICATION_ID: ''
      THREADS_APP_ID: ''
      THREADS_APP_SECRET: ''
      FACEBOOK_APP_ID: ''
      FACEBOOK_APP_SECRET: ''
      YOUTUBE_CLIENT_ID: ''
      YOUTUBE_CLIENT_SECRET: ''
      TIKTOK_CLIENT_ID: ''
      TIKTOK_CLIENT_SECRET: ''
      PINTEREST_CLIENT_ID: ''
      PINTEREST_CLIENT_SECRET: ''
      DRIBBBLE_CLIENT_ID: ''
      DRIBBBLE_CLIENT_SECRET: ''
      DISCORD_CLIENT_ID: ''
      DISCORD_CLIENT_SECRET: ''
      DISCORD_BOT_TOKEN_ID: ''
      SLACK_ID: ''
      SLACK_SECRET: ''
      SLACK_SIGNING_SECRET: ''
      MASTODON_URL: 'https://mastodon.social'
      MASTODON_CLIENT_ID: ''
      MASTODON_CLIENT_SECRET: ''

      # === OAuth & Authentik Settings
      # NEXT_PUBLIC_POSTIZ_OAUTH_DISPLAY_NAME: 'Authentik'
      # NEXT_PUBLIC_POSTIZ_OAUTH_LOGO_URL: 'https://raw.githubusercontent.com/walkxcode/dashboard-icons/master/png/authentik.png'
      # POSTIZ_GENERIC_OAUTH: 'false'
      # POSTIZ_OAUTH_URL: 'https://auth.example.com'
      # POSTIZ_OAUTH_AUTH_URL: 'https://auth.example.com/application/o/authorize'
      # POSTIZ_OAUTH_TOKEN_URL: 'https://auth.example.com/application/o/token'
      # POSTIZ_OAUTH_USERINFO_URL: 'https://authentik.example.com/application/o/userinfo'
      # POSTIZ_OAUTH_CLIENT_ID: ''
      # POSTIZ_OAUTH_CLIENT_SECRET: ''
      # POSTIZ_OAUTH_SCOPE: "openid profile email"  # Optional: uncomment to override default scope

      # === Sentry

      # NEXT_PUBLIC_SENTRY_DSN: 'http://spotlight:8969/stream'
      # SENTRY_SPOTLIGHT: '1'

      # === Misc Settings
      OPENAI_API_KEY: ''
      NEXT_PUBLIC_DISCORD_SUPPORT: ''
      NEXT_PUBLIC_POLOTNO: ''
      API_LIMIT: 30

      # === Payment / Stripe Settings
      FEE_AMOUNT: 0.05
      STRIPE_PUBLISHABLE_KEY: ''
      STRIPE_SECRET_KEY: ''
      STRIPE_SIGNING_KEY: ''
      STRIPE_SIGNING_KEY_CONNECT: ''

      # === Developer Settings
      NX_ADD_PLUGINS: false

      # === Short Link Service Settings (Optional - leave blank if unused)
      # DUB_TOKEN: ""
      # DUB_API_ENDPOINT: "https://api.dub.co"
      # DUB_SHORT_LINK_DOMAIN: "dub.sh"
      # SHORT_IO_SECRET_KEY: ""
      # KUTT_API_KEY: ""
      # KUTT_API_ENDPOINT: "https://kutt.it/api/v2"
      # KUTT_SHORT_LINK_DOMAIN: "kutt.it"
      # LINK_DRIP_API_KEY: ""
      # LINK_DRIP_API_ENDPOINT: "https://api.linkdrip.com/v1/"
      # LINK_DRIP_SHORT_LINK_DOMAIN: "dripl.ink"

    volumes:
      - postiz-config:/config/
      - postiz-uploads:/uploads/
    ports:
      - "4007:5000"
    networks:
      - postiz-network
      - temporal-network
    depends_on:
      postiz-postgres:
        condition: service_healthy
      postiz-redis:
        condition: service_healthy
      temporal:
        condition: service_started

  postiz-postgres:
    image: postgres:17-alpine
    container_name: postiz-postgres
    restart: always
    environment:
      POSTGRES_PASSWORD: postiz-password
      POSTGRES_USER: postiz-user
      POSTGRES_DB: postiz-db-local
    volumes:
      - postgres-volume:/var/lib/postgresql/data
    networks:
      - postiz-network
    healthcheck:
      test: pg_isready -U postiz-user -d postiz-db-local
      interval: 10s
      timeout: 3s
      retries: 3
  postiz-redis:
    image: redis:7.2
    container_name: postiz-redis
    restart: always
    healthcheck:
      test: redis-cli ping
      interval: 10s
      timeout: 3s
      retries: 3
    volumes:
      - postiz-redis-data:/data
    networks:
      - postiz-network

  # -----------------------
  # Temporal Stack (minimal: server + Postgres + UI; no Elasticsearch)
  # -----------------------
  temporal-postgresql:
    container_name: temporal-postgresql
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: temporal
      POSTGRES_USER: temporal
    networks:
      - temporal-network
    expose:
      - 5432
    volumes:
      - temporal-postgres-volume:/var/lib/postgresql/data
    healthcheck:
      test: pg_isready -U temporal
      interval: 10s
      timeout: 3s
      retries: 3

  temporal:
    container_name: temporal
    ports:
      - '7233:7233'
    image: temporalio/auto-setup:1.28.1
    depends_on:
      temporal-postgresql:
        condition: service_healthy
    environment:
      - DB=postgres12
      - DB_PORT=5432
      - POSTGRES_USER=temporal
      - POSTGRES_PWD=temporal
      - POSTGRES_SEEDS=temporal-postgresql
      - DYNAMIC_CONFIG_FILE_PATH=config/dynamicconfig/development-sql.yaml
      - ENABLE_ES=false
      - TEMPORAL_NAMESPACE=default
    networks:
      - temporal-network
    volumes:
      - ./dynamicconfig:/etc/temporal/config/dynamicconfig
    labels:
      kompose.volume.type: configMap

  temporal-ui:
    container_name: temporal-ui
    image: temporalio/ui:2.34.0
    environment:
      - TEMPORAL_ADDRESS=temporal:7233
      - TEMPORAL_CORS_ORIGINS=http://127.0.0.1:3000
    networks:
      - temporal-network
    ports:
      - '8080:8080'
    depends_on:
      - temporal

volumes:
  postgres-volume:
    external: false

  postiz-redis-data:
    external: false

  postiz-config:
    external: false

  postiz-uploads:
    external: false

  temporal-postgres-volume:
    external: false

networks:
  postiz-network:
    external: false
  temporal-network:
    driver: bridge
    name: temporal-network
```

---

## Railway Deployment

This section covers deploying Postiz to Railway.app, including the correct Temporal template to use.

### Prerequisites

- Railway.app account
- GitHub account (for code deployment)

### Step 1: Deploy Temporal (Standalone Template)

**CRITICAL:** Use the standalone **"Temporal"** template, NOT "Temporal Starter Package".

1. Go to Railway → New Project → Deploy a Template
2. Search for `temporal` in the template marketplace
3. Select **"Temporal"** by Six (61+ deploys, 100% success rate)
   - ✅ Description: "Open source durable execution platform (separate services + scaling)"
   - ❌ **DO NOT** use "Temporal Starter Package" (has buggy Elasticsearch startup scripts)

4. The Temporal template will deploy these services:
   - **Temporal Frontend** - Main gRPC endpoint (port 7233)
   - **Temporal History** - Workflow history service
   - **Temporal Worker** - Background worker
   - **Temporal UI** - Web interface for monitoring
   - **Temporal Matching** - Task queue matching
   - **Temporal Basic Auth** - Authentication proxy
   - **Postgres-iBMg** - Dedicated Temporal database
   - **Elasticsearch-lG_T** - Temporal search backend

5. Wait for all Temporal services to deploy successfully (all showing "Online")

### Step 2: Deploy Postiz

1. Fork or deploy the Postiz repository to Railway
2. Configure the following environment variables:

```bash
# === Required Settings
MAIN_URL='https://your-postiz-app.up.railway.app'
FRONTEND_URL='https://your-postiz-app.up.railway.app'
NEXT_PUBLIC_BACKEND_URL='https://your-postiz-app.up.railway.app/api'
JWT_SECRET='generate-a-random-string-here'
DATABASE_URL='${{Postgres.DATABASE_URL}}'
REDIS_URL='${{Redis.REDIS_URL}}'
BACKEND_INTERNAL_URL='http://localhost:3000'

# === CRITICAL: Temporal Configuration
# Point to the Temporal Frontend service (NOT the old Temporal Starter)
TEMPORAL_ADDRESS='temporal-frontend.railway.internal:7233'

IS_GENERAL='true'
DISABLE_REGISTRATION='false'

# === Storage Settings (Railway requires single volume)
STORAGE_PROVIDER='local'
UPLOAD_DIRECTORY='/data/uploads'
NEXT_PUBLIC_UPLOAD_DIRECTORY='/data/uploads'

# === Port Configuration (fixes nginx/backend conflict)
PORT='3000'
BACKEND_PORT='3000'

# === Developer Settings
NX_ADD_PLUGINS='false'
```

### Step 3: Configure Railway Services

#### Database Setup

1. **PostgreSQL** (main Postiz database)
   - Deploy: New Database → PostgreSQL
   - Connect to Postiz via `DATABASE_URL=${{Postgres.DATABASE_URL}}`

2. **Redis**
   - Deploy: New Database → Redis
   - Connect to Postiz via `REDIS_URL=${{Redis.REDIS_URL}}`

#### Volume Configuration

Railway's free/hobby tier allows **one volume per service**. Configure a single volume:

1. Go to Postiz service → Settings → Add Volume
2. **Mount Path:** `/data`
3. **Size:** 1GB (or adjust based on your needs)

The entrypoint script automatically creates subdirectories:
- `/data/uploads` - for uploaded media
- `/data/config` - for configuration files

### Step 4: Verify Deployment

1. **Check Service Status**
   - All services should show "Online" status
   - Temporal services (8 total) should all be running
   - Postiz should be running without 502/503 errors

2. **Access Postiz**
   - Navigate to your Postiz URL: `https://your-postiz-app.up.railway.app`
   - You should see the registration/login page

3. **Verify Temporal Connection**
   - Check Postiz logs for Temporal worker connection messages
   - No "Connection refused" or "Failed to connect" errors
   - Orchestrator should successfully connect to `temporal-frontend.railway.internal:7233`

### Common Issues & Solutions

#### Issue: 502 Bad Gateway

**Cause:** Port conflict between nginx (port 5000) and backend trying to use Railway's default PORT

**Solution:** Explicitly set in environment variables:
```bash
PORT='3000'
BACKEND_PORT='3000'
```

#### Issue: Temporal Connection Refused

**Cause:** Using old Temporal Starter Package or wrong TEMPORAL_ADDRESS

**Solution:**
1. Deploy the standalone "Temporal" template (not Starter Package)
2. Set `TEMPORAL_ADDRESS='temporal-frontend.railway.internal:7233'`
3. Verify Temporal Frontend service is "Online" in Railway dashboard

#### Issue: Database Schema Errors

**Cause:** Temporal database not properly initialized

**Solution:** With the standalone Temporal template, schema initialization is automatic. If issues persist:
1. Check Temporal Frontend logs for initialization errors
2. Verify Postgres-iBMg database is connected and healthy

#### Issue: Volume Mount Issues

**Cause:** Trying to mount multiple volumes (Railway limitation)

**Solution:** Use single volume at `/data` with subdirectories created by entrypoint script

### Railway Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   Railway Project                    │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌─────────────┐    ┌──────────────────────────┐   │
│  │   Postiz    │───▶│  Temporal Frontend       │   │
│  │  (Main App) │    │  :7233 (gRPC endpoint)   │   │
│  └─────┬───────┘    └────────┬─────────────────┘   │
│        │                     │                      │
│        │                     ├─▶ Temporal History   │
│        │                     ├─▶ Temporal Worker    │
│  ┌─────▼──────┐             ├─▶ Temporal Matching  │
│  │ PostgreSQL │             └─▶ Temporal UI         │
│  │  (Main DB) │                                     │
│  └────────────┘         ┌─────────────────────┐    │
│                         │  Postgres-iBMg       │    │
│  ┌────────────┐         │  (Temporal DB)       │    │
│  │   Redis    │         └─────────────────────┘    │
│  └────────────┘                                     │
│                         ┌─────────────────────┐    │
│  ┌────────────┐         │  Elasticsearch-lG_T  │    │
│  │ /data Vol  │         │  (Temporal Search)   │    │
│  │ (1GB)      │         └─────────────────────┘    │
│  └────────────┘                                     │
└─────────────────────────────────────────────────────┘
```

### Key Differences: Railway vs Docker Compose

| Aspect | Docker Compose | Railway |
|--------|----------------|---------|
| **Temporal** | Single `temporal` container | Separate scaled services (Frontend, History, Worker, etc.) |
| **Volumes** | Multiple volumes supported | **One volume per service** - use `/data` with subdirectories |
| **Networking** | Docker networks (`temporal-network`) | Private Railway networking (`.railway.internal`) |
| **Port Management** | Direct port mapping | Automatic proxy - must set `PORT=3000` explicitly |
| **Database** | Self-hosted containers | Managed Railway databases |
| **Scaling** | Manual via `docker-compose scale` | Automatic via Railway |

### Additional Resources

For more detailed Railway deployment information and troubleshooting:
- [RAILWAY_DEPLOY.md](RAILWAY_DEPLOY.md) - Complete Railway deployment guide
- [RAILWAY_NEW_PROJECT_DEPLOY.md](RAILWAY_NEW_PROJECT_DEPLOY.md) - Step-by-step guide for deploying to a **new** Railway project
- Run `./validate-railway-deploy.sh` before deploying to verify services and config
- [RAILWAY_COMPLETE_DEPLOY.md](RAILWAY_COMPLETE_DEPLOY.md) - Step-by-step deployment walkthrough
- [QUICK_RAILWAY_SETUP.md](QUICK_RAILWAY_SETUP.md) - Quick start guide

---

## Pulling upstream changes safely

If you use a fork of [postiz-app](https://github.com/gitroomhq/postiz-app) or deploy to Railway with the image `ghcr.io/gitroomhq/postiz-app:v2.12.1` (or another pinned tag), you can pull upstream changes without breaking your deploy by following these rules.

### 1. Syncing your postiz-app fork with upstream (gitroomhq/postiz-app)

**Safe for the deploy.** Railway (and this docker-compose setup) use the pre-built image; they do not build from your fork. You can update your fork with upstream at any time:

```bash
cd /path/to/postiz-app   # your fork
git fetch upstream
git merge upstream/main   # or: git rebase upstream/main
git push origin main      # (and/or your railway branch)
```

This only updates your fork’s code. It does **not** change what is running until you change how you deploy (e.g. switch to building from that repo).

### 2. When does “upstream” actually affect the running app?

Only when you **rebuild/redeploy** and the image is pulled again. This setup pins to a version tag (e.g. `v2.12.1`), so you control when to upgrade; update the tag in the Dockerfile and docker-compose when you want a new release.

To avoid that, **pin to a version tag** in your Dockerfile or `docker-compose.yml` and update only when you choose:

```dockerfile
  FROM ghcr.io/gitroomhq/postiz-app:v2.12.1
```

Or in `docker-compose.yml`:

```yaml
image: ghcr.io/gitroomhq/postiz-app:v2.12.1
```

Replace `v2.12.1` with the [release tag](https://github.com/gitroomhq/postiz-app/releases) you want. Update the tag when you’re ready to pull in a new upstream version.

### 3. Pulling changes in this repo (postiz-docker-compose)

If you add `upstream` = gitroomhq/postiz-docker-compose and merge, upstream might bring a different Dockerfile (e.g. one that builds from source). **Keep your current Dockerfile** (the one that only does `FROM ... postiz-app:v2.12.1` and creates `/uploads` and `/config`). Either don’t merge files that would overwrite the Dockerfile, or after merging run `git checkout --ours Dockerfile` and re-commit so your working Dockerfile is preserved.

For more detail on Railway deployment and 502 troubleshooting, see [RAILWAY_DEPLOY.md](RAILWAY_DEPLOY.md).
