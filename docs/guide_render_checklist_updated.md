# Choir API Deployment Checklist (Docker + Render)

## Overview
- Backend: FastAPI + PySUI + Docker
- Frontend: Swift iOS app
- Database: Qdrant Cloud
- Blockchain: Sui Devnet

## Prerequisites
- [x] Working Docker setup locally
- [x] GitHub repository connected to Render
- [x] Qdrant Cloud instance running
- [x] CHOIR coin deployed on Sui devnet

## Environment Variables Required
```env
# Sui Configuration
SUI_PRIVATE_KEY=your_deployer_private_key

# CORS Settings (iOS app)
ALLOWED_ORIGINS=*  # Configure appropriately for production

# Qdrant Configuration
QDRANT_HOST=your-qdrant-instance.cloud.qdrant.io
QDRANT_API_KEY=your_qdrant_api_key
```

## Local Testing Checklist
- [x] Docker build succeeds
```bash
docker build -t choir-api .
```
- [x] Docker Compose runs
```bash
docker-compose up
```
- [x] API endpoints accessible
- [x] CHOIR minting works
- [x] Qdrant connection works

## Render Deployment Steps

1. **Create Web Service**
   - Select "Docker" as environment
   - Connect GitHub repository
   - Select branch (e.g., `main`)

2. **Configure Environment**
   - Add all environment variables from `.env`
   - Set `PORT=8000`
   - Mark sensitive variables as secret:
     - `SUI_PRIVATE_KEY`
     - `QDRANT_API_KEY`

3. **Build Settings**
   - Root Directory: `./api`
   - Docker Command: (leave empty, uses Dockerfile)
   - Instance Type: Starter (upgrade as needed)

4. **Health Check**
   - Path: `/health`
   - Already configured in Dockerfile

## Post-Deployment Verification

1. **API Health**
   - [ ] Check `/health` endpoint
   - [ ] Verify logs in Render dashboard

2. **Core Functionality**
   - [ ] Test CHOIR minting
   - [ ] Verify Qdrant connections
   - [ ] Check CORS with iOS app

3. **iOS App Integration**
   - [ ] Update API URL in iOS app
   - [ ] Test all endpoints from iOS
   - [ ] Verify error handling

## Monitoring Setup

1. **Render Monitoring**
   - [ ] Set up usage alerts
   - [ ] Configure error notifications
   - [ ] Enable log streaming

2. **Custom Metrics**
   - [ ] CHOIR minting success rate
   - [ ] API response times
   - [ ] Error rates

## Rollback Plan
1. Keep previous deployment URL
2. Test new deployment thoroughly
3. Switch iOS app to new URL only after verification

## Security Checklist
- [ ] No sensitive data in Docker image
- [ ] Environment variables properly secured
- [ ] CORS properly configured for iOS
- [ ] Rate limiting configured
- [ ] TLS/SSL enabled (automatic with Render)

## Documentation Updates
- [ ] Update API documentation
- [ ] Document deployment process
- [ ] Update environment variable guide
- [ ] Add troubleshooting guide

## Cost Considerations
- Render Starter instance: Free
- Additional instances: Based on usage
- Qdrant Cloud: Based on usage
- Monitor usage and scale as needed

## Future Improvements
- [ ] Set up CI/CD with GitHub Actions
- [ ] Implement automated testing
- [ ] Add staging environment
- [ ] Configure auto-scaling rules
- [ ] Set up backup strategy

## Useful Commands
```bash
# Local Development
docker-compose up
docker-compose down

# Logs
docker-compose logs -f

# Render CLI (if needed)
render whoami
render list
```

## Important URLs
- Render Dashboard: https://dashboard.render.com
- API Documentation: https://your-api.onrender.com/docs
- Health Check: https://your-api.onrender.com/health

## Support Contacts
- Render Support: https://render.com/docs
- Qdrant Support: https://qdrant.tech/support
- Sui Support: https://docs.sui.io/support

Remember to keep this checklist updated as the deployment process evolves.
