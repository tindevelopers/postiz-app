# Deploying Postiz to a New Railway Project

This guide ensures a **successful first-time deployment** when deploying this repo to a new Railway project. The template was modified from the original and has specific requirements.

## Prerequisites

- [Railway CLI](https://docs.railway.app/develop/cli) installed (`npm install -g @railway/cli`)
- Logged into Railway (`railway login`)
- This repo cloned locally

---

## Required Service Names (Critical!)

Railway's `${{ServiceName.VARIABLE}}` syntax requires **exact service names**. This repo's `railway.toml` expects:

| Service   | Expected Name | Template/Action |
|-----------|---------------|-----------------|
| PostgreSQL| **Postgis** (default) or **Postgres** | Postgis template, or Add Database → PostgreSQL |
| Redis     | **Redis**     | Add Database → Redis (default name) |
| Temporal  | **Temporal**  | Deploy [Temporal Light](https://railway.com/template/temporal-light) template |

**Using standard Postgres (not Postgis)?** Override in Railway Dashboard → Postiz Service → Variables:
- `DATABASE_URL = ${{Postgres.DATABASE_URL}}`

**Using Postgis template?** No override needed – railway.toml uses Postgis by default.

---

## Step-by-Step: New Project Setup

### 1. Create Project and Add Services (in order)

**1a. Create new Railway project**
```bash
railway init
# Choose "Empty Project" or "Deploy from GitHub repo"
```

**1b. Deploy Temporal Light first** (Postiz requires Temporal for scheduling)
- Go to [Temporal Light template](https://railway.com/template/temporal-light)
- Click "Deploy Now"
- Select your new project
- Wait for Temporal, Temporal UI, Elasticsearch, Postgres (for Temporal), and Temporal Basic Auth to deploy

**1c. Add PostgreSQL for Postiz**
- Option A (matches railway.toml): Add "Postgis" template → service named "Postgis"
- Option B: Add "Database" → "PostgreSQL" → **Rename to "Postgis"** OR add variable override: `DATABASE_URL = ${{Postgres.DATABASE_URL}}`

**1d. Add Redis**
- "+ New" → "Database" → "Redis"
- Name should be "Redis" (default)

### 2. Deploy Postiz from this repo

**Option A: From GitHub**
- "+ New" → "GitHub Repo"
- Select this repo and branch
- Railway will use `railway.toml` and `Dockerfile` from the repo

**Option B: From CLI**
```bash
cd /path/to/postiz-docker-compose
railway link   # select your new project
railway up
```

### 3. Configure Variables

Railway will auto-resolve `DATABASE_URL` and `REDIS_URL` from service references if names match.

**Set these in Postiz Service → Variables** (or they may be set by railway.toml):

| Variable | Value | Notes |
|----------|-------|-------|
| `PORT` | `5000` | Required – nginx listens here |
| `JWT_SECRET` | (random 32+ chars) | **Required** – generate unique string |
| `MAIN_URL` | `https://YOUR-DOMAIN.up.railway.app` | After generating domain |
| `FRONTEND_URL` | Same as MAIN_URL | |
| `NEXT_PUBLIC_BACKEND_URL` | `https://YOUR-DOMAIN.up.railway.app/api` | |

**Generate domain:** Postiz Service → Settings → Networking → Generate Domain

**Override if using Postgis instead of Postgres:**
- `DATABASE_URL = ${{Postgis.DATABASE_URL}}`

### 4. Add Volume

- Postiz Service → Settings → Volumes
- Add volume: name `postiz-data`, mount path `/data`

### 5. Validate Before Deploy

```bash
./validate-railway-deploy.sh
```

If validation passes, deploy:
```bash
railway up
```

---

## Verification Checklist

- [ ] Temporal Light template deployed (Temporal, Elasticsearch, etc. running)
- [ ] PostgreSQL added and named "Postgres" (or override DATABASE_URL)
- [ ] Redis added and named "Redis"
- [ ] Postiz service deployed from this repo
- [ ] PORT=5000 set
- [ ] JWT_SECRET set (32+ chars)
- [ ] MAIN_URL, FRONTEND_URL, NEXT_PUBLIC_BACKEND_URL match your domain
- [ ] Volume mounted at /data
- [ ] `validate-railway-deploy.sh` passes

---

## Common Failures and Fixes

| Symptom | Cause | Fix |
|---------|-------|-----|
| `DATABASE_URL` empty/unresolved | PostgreSQL service missing or wrong name | Add Postgres, ensure name is "Postgres", or override in Variables |
| `REDIS_URL` empty | Redis service missing | Add Redis |
| Orchestrator "Connection refused" to Temporal | Temporal not deployed | Deploy Temporal Light template first |
| Healthcheck fails / 502 | PORT mismatch | Set PORT=5000 (nginx), not 3000 |
| Backend "EADDRINUSE :5000" | Backend and nginx both on 5000 | Entrypoint fixes this – ensure no override of PORT for backend |
| Login returns 502 | Backend not listening | Check TEMPORAL_ADDRESS, DATABASE_URL, REDIS_URL |

---

## Existing Projects (e.g. mellow-energy)

If your project already uses **Postgis** instead of **Postgres**:
- Add variable override: `DATABASE_URL = ${{Postgis.DATABASE_URL}}`
- railway.toml default uses Postgres; the override takes precedence

---

## Architecture Summary

```
Postiz Service
├── nginx (port 5000) ← Railway healthcheck
├── backend (port 3000)
├── frontend (Next.js)
└── orchestrator (Temporal workers)

Required:
├── Postgres (or Postgis) → DATABASE_URL
├── Redis → REDIS_URL
└── Temporal (from Temporal Light) → TEMPORAL_ADDRESS
```
