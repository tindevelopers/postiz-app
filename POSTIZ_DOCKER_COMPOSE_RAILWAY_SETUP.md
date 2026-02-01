# postiz-docker-compose Railway Project Setup

This project (social.tin.info) uses a **different architecture** than mellow-energy:

| Setting | mellow-energy | postiz-docker-compose |
|---------|---------------|----------------------|
| Database | Postgis | Postgres |
| Temporal | Temporal Light (single service) | Full Temporal (Frontend, History, Matching, Worker) |
| TEMPORAL_ADDRESS | temporal.railway.internal:7233 | temporal-frontend.railway.internal:7233 |

## Required Variable Overrides (Railway Dashboard)

For postiz-docker-compose to work, ensure these are set in **Postiz Service → Variables**:

| Variable | Value |
|----------|-------|
| PORT | 5000 |
| BACKEND_PORT | 3000 |
| DATABASE_URL | `${{Postgres.DATABASE_URL}}` |
| TEMPORAL_ADDRESS | temporal-frontend.railway.internal:7233 |
| REDIS_URL | `${{Redis.REDIS_URL}}` |
| JWT_SECRET | (your secret) |
| MAIN_URL | https://social.tin.info |
| FRONTEND_URL | https://social.tin.info |
| NEXT_PUBLIC_BACKEND_URL | https://social.tin.info/api |

## Build Source

Ensure the project deploys from **this repo** (with the entrypoint fix), not an older GitHub source. The entrypoint.sh must include:
```bash
exec env PORT=3000 BACKEND_PORT=3000 docker-entrypoint.sh "$@"
```

## Deploy from This Repo

```bash
cd /path/to/postiz-docker-compose
railway link -p f7c9f463-0550-48de-9405-096684e31278 -s postiz
railway up
```

## Verification

After deploy completes:
1. https://social.tin.info/ → 200 OK
2. https://social.tin.info/auth → 200 OK  
3. Create account → Should succeed (no 502)
4. Sign in → Should succeed
