# Railway Deployment Guide for Postiz

## Run from your fork (tindevelopers/postiz-app)

To run from **your fork** [tindevelopers/postiz-app](https://github.com/tindevelopers/postiz-app) instead of the upstream image:

1. In Railway → your project → **postiz** service (or add a new service).
2. **Settings** → **Source** → **Connect Repo** (not Connect Image).
3. Choose **tindevelopers/postiz-app** and branch **railway**.
4. Railway will build from that repo’s **Dockerfile** (builds from source = your fork’s code) and use its **railway.toml** (Temporal, PORT, etc.).
5. Set variables: `DATABASE_URL`, `REDIS_URL`, `JWT_SECRET`, `MAIN_URL`, `FRONTEND_URL`, `NEXT_PUBLIC_BACKEND_URL`, and if you use Temporal: `TEMPORAL_ADDRESS=temporal.railway.internal:7233`.
6. Deploy. Each push to the **railway** branch triggers a new build and deploy.

The **railway** branch on [tindevelopers/postiz-app](https://github.com/tindevelopers/postiz-app) includes a root **Dockerfile** (build from source) and **railway.toml** with Railway + Temporal settings.

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

4. **Deploy Postiz service from your fork:**
   - Click "+ New" → **GitHub Repo** (not "Connect Image")
   - Select **tindevelopers/postiz-app** and branch **railway**
   - Railway builds from that repo’s **Dockerfile** (your fork’s code) and uses its **railway.toml**
   - Each push to **railway** triggers a new build and deploy

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
# Omit TEMPORAL_ADDRESS if you are NOT using Temporal (avoids 502 on signup)
# If using Temporal: set TEMPORAL_ADDRESS to your Temporal server's private URL (see "With Temporal" below)
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

## With Temporal (minimal services)

If you use Railway's **Temporal Starter** template alongside Postiz, wire Postiz to Temporal and keep only these services:

**Services to keep:**
- **postiz** – your app
- **1 PostgreSQL** for Postiz (`DATABASE_URL`)
- **1 Redis** for Postiz (`REDIS_URL`)
- **Temporal** – workflow server
- **1 PostgreSQL** used by Temporal (do not use for Postiz)
- **Temporal UI** – optional; for viewing workflows
- **Temporal Basic Auth** – if the template added it (for UI auth)
- **Worker** – runs workflows; required for scheduling

**Postiz variables when Temporal is deployed:** set `TEMPORAL_ADDRESS` to the Temporal server's **private** URL so Postiz and Temporal communicate inside Railway (same project). In Railway, use the internal hostname, e.g.:

```bash
TEMPORAL_ADDRESS=temporal.railway.internal:7233
```

Use the exact hostname shown in your Temporal service's **Variables** or **Networking** (e.g. `${{Temporal.TEMPORAL_ADDRESS}}` if the template exposes it). Then redeploy Postiz.

## Important Notes

1. **Temporal on Railway**: The repo's docker-compose uses a minimal Temporal stack (server + Postgres + UI; no Elasticsearch). On Railway you deploy Temporal separately (e.g. [Temporal Starter](https://railway.com/deploy/temporal-starter)), then set Postiz's `TEMPORAL_ADDRESS` to that server. Without Temporal, omit `TEMPORAL_ADDRESS` so signup and auth work; scheduling will no-op until you add Temporal.

2. **Environment Variables**: Railway automatically provides:
   - `DATABASE_URL` for PostgreSQL
   - `REDIS_URL` for Redis
   - `PORT` for the service port
   - `RAILWAY_ENVIRONMENT` for the environment name

3. **Custom Domain**: After deployment, you can add a custom domain in Railway's dashboard.

4. **Volumes**: Railway supports persistent volumes. Make sure to configure volumes for:
   - `/uploads` (user uploads)
   - `/config` (application config)

## Service cleanup (Postiz + Temporal)

If you deployed Postiz and the **Temporal Starter** template, you may end up with extra Postgres and Redis services. The minimal set (matching this repo's docker-compose) is **2 PostgreSQL** and **1 Redis** total: one Postgres for Postiz, one for Temporal, one Redis for Postiz. No Elasticsearch or admin-tools are required.

### What each app needs

| App | PostgreSQL | Redis | Other |
|-----|------------|-------|--------|
| **Postiz** | 1 (app data – set as `DATABASE_URL`) | 1 (sessions/cache – set as `REDIS_URL`) | `TEMPORAL_ADDRESS` pointing at Temporal |
| **Temporal** | 1 (workflow state – used by the Temporal service) | — | Server, UI, Basic Auth, Worker |

Postiz uses **one** `DATABASE_URL` and **one** `REDIS_URL`. It must not be wired to two different Postgres instances.

### Services to keep

- **postiz** – your app (Online).
- **One PostgreSQL** for Postiz – the one you want as Postiz’s main database. In Variables, set `DATABASE_URL=${{ThatPostgresService.DATABASE_URL}}`.
- **One Redis** for Postiz – the one you want for sessions/cache. Set `REDIS_URL=${{ThatRedisService.REDIS_URL}}`.
- **Temporal** – server (Online).
- **Temporal UI** – web UI for workflows (optional but useful).
- **Temporal Basic Auth** – auth for the UI (if the template added it).
- **Worker** – runs Temporal workflows; required for scheduling/post workflows.
- **One PostgreSQL used by Temporal** – the Postgres that the Temporal service connects to (do not use this for Postiz’s `DATABASE_URL`).

### Services to remove (in Railway dashboard)

Remove these in **Railway** → your project → select service → **Settings** → **Remove Service** (or equivalent). Do not remove the single Postgres and single Redis you chose for Postiz, or the Postgres used by Temporal.

1. **Temporal Client** (status “Completed”) – one-off demo; not needed for Postiz. Safe to remove.
2. **Extra PostgreSQL instances** – you should have exactly **2** Postgres total: one for Postiz, one for Temporal. If you have more (e.g. Postgres-gC6p, Postgres-G2qN, or a generic “Postgres” with no connections), remove the extras. Before removing, confirm which one is in Postiz’s `DATABASE_URL` and which one Temporal uses; do not remove those two.
3. **Extra Redis instances** – you need **1** Redis total (for Postiz). If you have 2 or 3 Redis, remove the ones **not** referenced in Postiz’s `REDIS_URL`.

### Wiring Postiz after cleanup

1. In **postiz** → **Variables**:
   - `DATABASE_URL` = `${{YourPostizPostgresService.DATABASE_URL}}` (e.g. `${{Postgres-hS_X.DATABASE_URL}}` – use the **exact** service name from the dashboard).
   - `REDIS_URL` = `${{YourPostizRedisService.REDIS_URL}}`.
   - `TEMPORAL_ADDRESS` = the Temporal server address inside Railway (e.g. `temporal.railway.internal:7233` or the hostname shown in the Temporal service’s **Variables** / **Networking**). Use the **private** URL so Postiz and Temporal are in the same project.
2. Redeploy Postiz after changing variables so the new connections take effect.

### Quick checklist

- [ ] Only 2 PostgreSQL services remain (one for Postiz, one for Temporal).
- [ ] Only 1 Redis service remains (for Postiz).
- [ ] Postiz `DATABASE_URL` points at the Postiz Postgres only.
- [ ] Postiz `REDIS_URL` points at the single Redis.
- [ ] Postiz `TEMPORAL_ADDRESS` points at the Temporal server (private URL).
- [ ] Temporal Client service removed (optional; frees confusion, not cost once completed).

## Pulling upstream changes safely

Your Railway deploy uses this repo’s **Dockerfile**, which uses a pinned image: `FROM ghcr.io/gitroomhq/postiz-app:v2.12.1`. That keeps the deploy stable; update the tag when you want a new release.

**1. Syncing your postiz-app fork with upstream (gitroomhq/postiz-app)**  
- Safe for the deploy. Railway does **not** build from your fork; it uses the pre-built image above.  
- To pull upstream into your fork (e.g. [the-info-network/postiz-app](https://github.com/the-info-network/postiz-app)):

  ```bash
  cd /path/to/postiz-app   # your fork
  git fetch upstream
  git merge upstream/main   # or: git rebase upstream/main
  git push origin main      # (and/or your railway branch)
  ```

- This updates your fork’s code only. It does **not** change what is running on Railway until you change how you deploy (e.g. switch to building from that repo).

**2. When does “upstream” actually affect the running app?**  
- Only when Railway **rebuilds/redeploys** and pulls the image again. The Dockerfile uses a pinned tag (e.g. `v2.12.1`), so you control when you get a new version.  
- If upstream pushes a bad or incompatible release as `:latest`, the next redeploy could break. To reduce that risk, **pin to a version tag** in the Dockerfile and update only when you choose:

  ```dockerfile
  FROM ghcr.io/gitroomhq/postiz-app:v2.12.1
  ```

  Replace `v2.12.1` with the [release tag](https://github.com/gitroomhq/postiz-app/releases) you want. Update the tag when you’re ready to pull in a new upstream version.

**3. Pulling changes in this repo (postiz-docker-compose)**  
- If you add `upstream` = gitroomhq/postiz-docker-compose and merge, upstream might bring a different Dockerfile (e.g. one that builds from source). **Keep your current Dockerfile** (the one that only does `FROM ... postiz-app:v2.12.1` and creates `/uploads` and `/config`).  
- Either don’t merge files that would overwrite the Dockerfile, or after merging run `git checkout --ours Dockerfile` and re-commit so your working Dockerfile is preserved.

## Troubleshooting

### Common Startup Errors

1. **"Cannot connect to Temporal"** - Temporal is NOT included in Railway deployment. **Login and signup do not require Temporal.** Remove `TEMPORAL_ADDRESS` from your Railway variables (leave it unset). The app will start and auth will work; scheduling/post workflows will no-op until you deploy Temporal. If you need full scheduling, deploy Temporal separately and set `TEMPORAL_ADDRESS`.

2. **"Connection refused to PostgreSQL/Redis"** - Make sure you:
   - Added PostgreSQL and Redis services in Railway
   - Used Railway variable references: `${{Postgres.DATABASE_URL}}` and `${{Redis.REDIS_URL}}`

3. **"Port already in use" or health check failures** - Ensure:
   - `PORT=5000` is set
   - No conflicting `startCommand` in railway.toml

4. **Container exits immediately** - Check if:
   - All required environment variables are set (especially `JWT_SECRET`, `DATABASE_URL`, `REDIS_URL`)
   - The URLs are correct (use Railway's provided domain)

### 502 on login (connection refused to backend :3000)

If **login** returns 502 and logs show `connect() failed (111: Connection refused) ... upstream: "http://127.0.0.1:3000/auth/login"`, the backend is not listening on port 3000. Often the cause is **Temporal wiring**:

- The **orchestrator** (Nest) connects to Temporal at `TEMPORAL_ADDRESS` during startup. If that address is wrong (e.g. unset → localhost:7233, or `temporal:7233` which does not resolve on Railway), you get: `TemporalWorkerManagerService Failed to create connection ... 127.0.0.1:7233 Connection refused`. That can prevent the backend from fully starting, so nothing listens on 3000 and login fails.

**Fix when using Temporal on Railway:** Set `TEMPORAL_ADDRESS` to your **Temporal server's private URL** in the same project, e.g. `temporal.railway.internal:7233` (replace `temporal` with your Temporal service name if different). This repo's `railway.toml` sets `TEMPORAL_ADDRESS = "temporal.railway.internal:7233"` so the next deploy uses it. If your Temporal service has another name, set the variable in Railway dashboard (Variables) to `<that-service>.railway.internal:7233` and redeploy.

**Fix when not using Temporal:** Remove `TEMPORAL_ADDRESS` from variables so the app does not try to connect to Temporal; auth and login can then work without a worker.

### Login returns 200 but page stays on (or returns to) login

If the **login API returns 200** with `{"login":true}` (e.g. verified with `curl` or Network tab) but the **browser stays on the login page** or reloads back to it instead of redirecting to the dashboard, the problem is usually **cookies/URLs**, not the backend.

1. **URLs must match exactly (same origin)**  
   The app sets a session cookie for the request origin. If the user visits a different host or scheme than your env vars, the cookie may not be set or may not be sent on the next request.

   - **Fix:** Set `MAIN_URL`, `FRONTEND_URL`, and `NEXT_PUBLIC_BACKEND_URL` to the **exact** URL users use (e.g. `https://your-app.up.railway.app` and `https://your-app.up.railway.app/api`). No trailing slash on the base URL. Use `https` if Railway serves over HTTPS (it does). If you use a custom domain, all three must use that domain.

2. **Rebuild after changing URL env vars**  
   `NEXT_PUBLIC_BACKEND_URL` is baked in at **build** time. Changing it in Railway Variables alone does not update the already-built frontend until you **redeploy** (so a new build runs with the new value).

   - **Fix:** After changing `MAIN_URL`, `FRONTEND_URL`, or `NEXT_PUBLIC_BACKEND_URL`, trigger a new deploy (e.g. `railway up --detach` or push + redeploy).

3. **Check that a session cookie is set**  
   After submitting login, open DevTools → **Application** (Chrome) or **Storage** (Firefox) → **Cookies** → select your Railway domain. Confirm that a session/JWT cookie appears (name depends on Postiz; often something like `token`, `session`, or `connect.sid`). If **no** cookie appears, the backend is not setting it—often because the response is going to a different origin than the page (see point 1). If the cookie **is** there but you’re still sent back to login, the frontend or middleware may be redirecting before reading it (e.g. caching or wrong path).

4. **Same host for page and API**  
   The frontend should call the API at the same host as the page (e.g. both `https://your-app.up.railway.app`). If `NEXT_PUBLIC_BACKEND_URL` points to another domain or an old URL, the cookie set by the API response might not be stored for the page’s origin.

**Quick check:** In the browser Network tab, submit login and inspect the **login response**: confirm status 200 and that the **Response Headers** include a `Set-Cookie` header for your Railway domain. If `Set-Cookie` is missing or has a different domain/path, fix the URL env vars and redeploy.

**Current deployment (from Railway CLI):** For `postiz-production-3ae9.up.railway.app`, `railway variables` shows `MAIN_URL`, `FRONTEND_URL`, and `NEXT_PUBLIC_BACKEND_URL` all set to that URL (and `/api` for the backend). URL consistency is correct. To debug the redirect: (1) Log in with valid credentials at https://postiz-production-3ae9.up.railway.app/auth/login, (2) Open DevTools → Network, (3) Find the request to `/api/auth/login` (or similar), (4) If status is 200, check Response Headers for `Set-Cookie`; if no cookie is set, the issue is backend/session config; if a cookie is set but the page still goes back to login, the issue is frontend redirect or middleware. Run `railway logs` during login to see any server-side errors.

**If login returns 400 with "Cannot read properties of undefined (reading 'getUser')":** The frontend is sending an invalid `provider` value. For email/password login, the frontend **must** send `provider: "LOCAL"` (uppercase). If the frontend sends something else (e.g. `"credentials"`, `"local"`, or any value not in the enum), the backend's `ProvidersFactory` tries to load that provider, returns `undefined` (no default case), then crashes when calling `.getUser()` on undefined. **Fix:** Ensure the login form sends `provider: "LOCAL"` (see `apps/frontend/src/components/auth/login.tsx` line 48). A default case has been added to `providers.factory.ts` in the `postiz-app-railway` repo to throw a clearer error: `Unsupported provider: ${provider}. Use LOCAL for email/password login.` After this fix and redeploying, invalid providers will return a clear 400 error instead of crashing.

### 502 Bad Gateway when creating an account (signup)

A **502 Bad Gateway** on the signup page usually means Railway’s proxy (nginx) did not get a valid response from your app. Common causes:

1. **Temporal not available (most likely)**  
   The app expects a Temporal server at `TEMPORAL_ADDRESS`. On Railway you only run the app, so that host is missing. Signup can trigger workflows that try to connect to Temporal and then hang or fail, and the proxy returns 502.

   **Fix:** If you **are** using Temporal: set `TEMPORAL_ADDRESS` to the Temporal server's **private** URL (e.g. `temporal.railway.internal:7233`). If you are **not** using Temporal: remove `TEMPORAL_ADDRESS` from variables (or leave it unset).

2. **Database or Redis unreachable**  
   Signup and login both use the database. If `DATABASE_URL` or `REDIS_URL` is wrong, missing, or the linked Postgres/Redis service is down, the backend can error or time out and the proxy returns 502.

   **Fix:** Confirm you have PostgreSQL and Redis services in the same project, and that variables use Railway references: `${{Postgres.DATABASE_URL}}` and `${{Redis.REDIS_URL}}`. Check that those services are running and reachable.

3. **Wrong public URLs**  
   If `MAIN_URL`, `FRONTEND_URL`, or `NEXT_PUBLIC_BACKEND_URL` don’t match your real Railway URL (e.g. `https://postiz-production-3ae9.up.railway.app`), auth/signup callbacks and API calls can fail and appear as 502.

   **Fix:** Set all three to your actual Railway URL; set `NEXT_PUBLIC_BACKEND_URL` to `https://your-actual-domain.up.railway.app/api`.

4. **App not listening on port 3000 (inside container)**  
   Railway logs may show: `connect() failed (111: Connection refused) while connecting to upstream ... upstream: "http://127.0.0.1:3000/..."`. The Postiz image runs nginx in front of the app; nginx proxies to `localhost:3000`. If the app (Next.js/Nest) never finishes starting—e.g. the orchestrator blocks on Temporal—nothing listens on 3000 and nginx returns 502.

   **Fix:** Ensure the app can start: set `TEMPORAL_ADDRESS` correctly if you use Temporal, or **remove** `TEMPORAL_ADDRESS` in the Railway dashboard (Variables → delete the variable) so the app starts without Temporal; then redeploy. Keep `PORT=5000` (Railway’s default); the container exposes 5000 and nginx listens there.

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
| `TEMPORAL_ADDRESS` | `temporal.railway.internal:7233` | **Only if** you deployed Temporal; use the Temporal server's private URL. Omit otherwise. |