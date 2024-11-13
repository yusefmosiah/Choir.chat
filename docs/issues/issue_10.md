# Deploy to Render and TestFlight

## Parent Issue
[Core Message System Implementation](issue_0.md)

## Related Issues
- Depends on: All implementation issues
- Related to: [Development Environment Setup](issue_-1.md)

## Description
Deploy the Python API service to Render and submit the iOS app to TestFlight for testing, ensuring proper configuration and monitoring.

## Tasks
1. Render Deployment
   - [ ] Configure Render service
     - [ ] Set environment variables
     - [ ] Configure Qdrant connection
     - [ ] Set up logging
   - [ ] Deploy API
     - [ ] Test endpoints
     - [ ] Monitor performance
     - [ ] Check error reporting

2. TestFlight Submission
   - [ ] App Store Connect setup
     - [ ] Configure app details
     - [ ] Add test information
     - [ ] Set up TestFlight users
   - [ ] Build preparation
     - [ ] Update bundle ID
     - [ ] Configure signing
     - [ ] Set version/build numbers
   - [ ] Submit build
     - [ ] Run archive
     - [ ] Upload to App Store Connect
     - [ ] Submit for review

## Code Examples
```yaml
# render.yaml
services:
  - type: web
    name: choir-api
    env: python
    buildCommand: pip install -r requirements.txt
    startCommand: uvicorn app.main:app --host 0.0.0.0 --port $PORT
    envVars:
      - key: QDRANT_URL
        sync: false
      - key: QDRANT_API_KEY
        sync: false
      - key: OPENAI_API_KEY
        sync: false
```

```swift
// Configuration.swift
enum Configuration {
    #if DEBUG
    static let apiBaseURL = "http://localhost:8000"
    #else
    static let apiBaseURL = "https://choir-api.onrender.com"
    #endif
}
```

## Testing Requirements
1. API Deployment
   - Endpoint accessibility
   - Error handling
   - Performance metrics
   - Security headers

2. TestFlight Build
   - App functionality
   - Network connectivity
   - Error reporting
   - Analytics integration

## Success Criteria
1. API Service
   - Successfully deployed
   - All endpoints working
   - Proper error handling
   - Good performance

2. iOS App
   - Approved for TestFlight
   - Working with deployed API
   - Clean error handling
   - Analytics reporting

## Notes
- Keep development database for now
- Monitor API performance
- Track error rates
- Collect usage metrics
