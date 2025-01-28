# Choir API Deployment Guide (Docker + Render)

## Current Status

- [x] Basic Docker deployment working
- [x] PySUI integration functional
- [x] CHOIR minting operational
- [x] Balance checking implemented
- [ ] Comprehensive error handling
- [ ] Production-ready monitoring

## Docker Configuration

```dockerfile
# Key components
FROM python:3.12-slim
# Rust toolchain required for pysui
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
# Virtual environment for isolation
ENV VIRTUAL_ENV=/app/venv
# Split pip installs for better caching
RUN pip install --no-cache-dir pysui
RUN pip install --no-cache-dir -r requirements.txt
```

## Render Configuration

```yaml
services:
  - type: web
    name: choir-api
    runtime: docker
    dockerfilePath: Dockerfile
    dockerContext: api
    envVars:
      - key: SUI_PRIVATE_KEY
        sync: false
      # Other env vars...
```

## Environment Variables Required

```env
# Critical Variables
SUI_PRIVATE_KEY=your_deployer_private_key
ALLOWED_ORIGINS=*  # Configure for production

# Optional Services
QDRANT_URL=your_qdrant_url
QDRANT_API_KEY=your_qdrant_key
OPENAI_API_KEY=your_openai_key
```

## Known Issues & Solutions

1. **Long Build Times**

   - First build takes ~5 minutes due to Rust compilation
   - Subsequent builds faster with proper caching

2. **PySUI Integration**

   - Balance checking requires builder pattern
   - Transaction effects need careful validation

3. **Environment Setup**
   - All env vars must be set in Render dashboard
   - Some vars optional depending on features needed

## Deployment Checklist

### Pre-Deploy

- [ ] Test Docker build locally
- [ ] Verify all required env vars
- [ ] Check CORS settings
- [ ] Test PySUI functionality

### Deploy

- [ ] Push to GitHub
- [ ] Create Render web service
- [ ] Set environment variables
- [ ] Monitor build progress

### Post-Deploy

- [ ] Verify `/health` endpoint
- [ ] Test CHOIR minting
- [ ] Check balance queries
- [ ] Monitor error logs

## Monitoring Setup

- [ ] Set up Render logging
- [ ] Configure error alerts
- [ ] Monitor build times
- [ ] Track API response times

## Future Improvements

- [ ] Optimize Docker build time
- [ ] Add comprehensive testing
- [ ] Improve error handling
- [ ] Set up CI/CD pipeline
- [ ] Add staging environment

## Useful Commands

```bash
# Local Testing
docker build -t choir-api -f api/Dockerfile .
docker run -p 8000:8000 choir-api

# Logs
docker logs choir-api
```

## Support Resources

- [Render Dashboard](https://dashboard.render.com)
- [PySUI Issues](https://github.com/FrankC01/pysui/issues)
- [Sui Discord](https://discord.gg/sui)

Remember to update these guides as the deployment process evolves.
