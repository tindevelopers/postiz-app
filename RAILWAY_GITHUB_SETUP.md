# Railway Deployment Setup

## Overview
Since Railway's GitHub integration might not be available in the current interface, we'll use alternative deployment methods.

## Deployment Options

### Option 1: Manual Deployment (Recommended)

Use the provided deployment script:

```bash
# Make sure you're logged in to Railway
railway login

# Run the deployment script
./deploy.sh
```

### Option 2: Railway CLI Direct Deployment

```bash
# Deploy directly using Railway CLI
railway up --detach
```

### Option 3: Check for GitHub Integration

If you want to try the GitHub integration:

1. Go to [Railway Dashboard](https://railway.app/dashboard)
2. Navigate to your `postiz-app` project
3. Click on the **Settings** tab
4. Look for **Source Repositories** or **Integrations** section
5. If available, connect your GitHub repository: `tindevelopers/postiz-app`

### 2. Configure Auto-Deploy

1. In the Railway project settings, ensure **Auto-Deploy** is enabled
2. Set the deployment branch to `main`
3. Railway will automatically deploy whenever you push to the main branch

### 3. Environment Variables

Railway will automatically provide these environment variables:
- `DATABASE_URL` (from PostgreSQL service)
- `REDIS_URL` (from Redis service)
- `RAILWAY_*` variables (automatically set)

### 4. Manual Environment Variables

You may need to set these manually in Railway dashboard:
- `MAIN_URL=https://postiz-app.railway.app`
- `NEXT_PUBLIC_API_URL=https://postiz-app.railway.app/api`
- `NEXT_PUBLIC_VERSION=1.0.0`
- `NODE_ENV=production`
- `PORT=5000`

## Benefits of Railway GitHub Integration

✅ **Automatic Deployments**: Deploys on every push to main branch
✅ **No Authentication Issues**: No need for tokens or CLI setup
✅ **Better Error Handling**: Railway handles the deployment process
✅ **Environment Variables**: Automatically connected to your databases
✅ **Build Logs**: View build and deployment logs in Railway dashboard

## Current Status

- ✅ **GitHub Repository**: `tindevelopers/postiz-app`
- ✅ **Railway Project**: `postiz-app`
- ✅ **Database & Redis**: Connected and running
- ✅ **Build Process**: Fixed (Prisma schema issue resolved)
- ⏳ **Next Step**: Connect GitHub repository in Railway dashboard

## Testing the Setup

Once connected:
1. Make a small change to your code
2. Push to the `main` branch
3. Railway will automatically detect the change and deploy
4. Check the Railway dashboard for deployment status
5. Visit `https://postiz-app.railway.app` to see your application

## Troubleshooting

If deployment fails:
1. Check Railway dashboard logs
2. Verify environment variables are set
3. Ensure database and Redis services are running
4. Check that the Dockerfile is in the root directory
