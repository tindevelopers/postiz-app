# Railway CLI Commands for Database Setup

Since Railway CLI requires interactive input, run these commands **one at a time** in your terminal:

## Step 1: Navigate to project directory
```bash
cd /Users/gene/Projects/postiz-docker-compose
```

## Step 2: Link to postiz service
```bash
railway service postiz
```

## Step 3: Add PostgreSQL database
```bash
railway add --database postgres --service postgres-db
```
When prompted, select "Database" and confirm.

## Step 4: Add Redis database
```bash
railway add --database redis --service redis-db
```
When prompted, select "Database" and confirm.

## Step 5: Link back to postiz service
```bash
railway service postiz
```

## Step 6: Configure database connection URLs
```bash
railway variables --set "DATABASE_URL=\${{Postgres.DATABASE_URL}}"
railway variables --set "REDIS_URL=\${{Redis.REDIS_URL}}"
```

**Note:** If your PostgreSQL service has a different name, replace `Postgres` with the actual service name. Check service names with:
```bash
railway status
```

## Step 7: Verify variables are set
```bash
railway variables
```

You should see `DATABASE_URL` and `REDIS_URL` in the output.

## Step 8: Redeploy the application
```bash
railway up --detach
```

## Step 9: Check deployment status
```bash
railway logs --tail 50
```

## Alternative: If service names are different

If Railway created the services with different names, you can check available services and use the correct reference:

```bash
# Check what services exist (you may need to check Railway dashboard)
# Then use the correct service name in the variable reference:
railway variables --set "DATABASE_URL=\${{YourPostgresServiceName.DATABASE_URL}}"
railway variables --set "REDIS_URL=\${{YourRedisServiceName.REDIS_URL}}"
```

## Troubleshooting

- **Service not found**: Check Railway dashboard to see actual service names
- **Variables not updating**: Make sure you're linked to the correct service (`railway service postiz`)
- **Deployment failing**: Check logs with `railway logs` to see error messages
