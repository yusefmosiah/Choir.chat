# Choir: Harmonic Intelligence Platform

VERSION harmonic_system:
invariants: {
"Wave resonance",
"Energy conservation",
"Pattern emergence"
}
assumptions: {
"Apple ecosystem excellence",
"Swift implementation",
"Natural harmonics"
}
docs_version: "0.4.2"

# Deployment Checklist for Frontend and Backend Separation

This checklist outlines the steps necessary to separate the Python backend from the current codebase and redeploy both the frontend and backend using Render. We will ensure that the Next.js frontend and the Python FastAPI backend are deployed independently, enabling better scalability and management.

## Prerequisites

- [x] **Render Account**: Ensure you have a Render account and are logged in.
- [x] **Git Repository**: Your code should be in a Git repository with updated structure.
- [x] **Updated Codebase**: The codebase reflects the separation of frontend and backend.

## (Old) Updated Repository Structure

Referencing **tree.md**, the updated directory structure is as follows:

```
.
├── anchor/             # Solana program code
├── api/                # Python FastAPI backend
├── docs/               # Documentation
├── frontend/           # Next.js frontend application
├── other_files...      # Additional files and directories
```

## Steps to Separate the Backend

1. **Restructure the Repository**:
   - Move the Next.js application into a `frontend/` directory.
   - Move the Python FastAPI backend into an `api/` or `backend/` directory.
   - Update any file paths and imports as necessary.

2. **Update Git Configuration**:
   - Ensure `.gitignore` files are set appropriately in both `frontend/` and `api/` directories.
   - Commit the changes to your Git repository.

3. **Ensure Independent Builds**:
   - Both the frontend and backend should have their own `Dockerfile` or build scripts.
   - Verify that each can be built and run independently.

## Deploying the Frontend (Next.js)

### 1. Create a New Web Service for the Frontend

- **In Render**:
  - Click **New** and select **Web Service**.
  - **Name**: `choir-frontend`.
  - **Root Directory**: Set to `frontend/`.
  - **Environment**: Select **Node.js**.
  - **Build Command**: `cd frontend && pnpm install && pnpm run build`.
  - **Start Command**: `cd frontend && pnpm start`.

### 2. Configure Frontend Service

- **Instance Type**: Choose an appropriate instance type.
- **Branch**: Select the deployment branch (e.g., `main`).
- **Environment Variables**:
  - `NODE_ENV`: `production`
  - `PORT`: `3000` (or the port your app listens on)
  - `NEXT_PUBLIC_API_URL`: URL of the deployed backend (to be set after backend deployment)

### 3. Verify Frontend Deployment

- **Access URL**: Visit the frontend URL provided by Render.
- **Test Application**:
  - Ensure pages load correctly.
  - Look for any missing assets or broken links.
- **Check Logs**: Monitor for any errors during build and runtime.

## Deploying the Backend (Python FastAPI)

### 1. Create a New Web Service for the Backend

- **In Render**:
  - Click **New** and select **Web Service**.
  - **Name**: `choir-backend`.
  - **Root Directory**: Set to `api/`.
  - **Environment**: Select **Python**.

### 2. Configure Backend Service

- **Build Command**:
  - If using `requirements.txt`:
    ```
    pip install -r api/requirements.txt
    ```
  - If using `pyproject.toml`:
    ```
    cd api && pip install .
    ```
- **Start Command**:
  ```
  uvicorn main:app --host 0.0.0.0 --port 8000
  ```
- **Instance Type**: Choose an appropriate instance type.
- **Environment Variables**:
  - `PORT`: `8000` (or the port your app listens on)
  - Other variables as needed (e.g., database URLs, API keys)

### 3. Update Backend Configuration

- **CORS Settings**:
  - Update `api/main.py` to allow requests from the frontend domain.
    ```python
    from fastapi.middleware.cors import CORSMiddleware

    app = FastAPI()

    origins = [
        "https://choir-frontend.onrender.com",
        "http://localhost:3000",
    ]

    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    ```
- **Dependencies**:
  - Ensure all dependencies are listed in `requirements.txt` or `pyproject.toml`.
- **Update Any Hardcoded URLs**:
  - Replace localhost URLs with environment variables or configuration settings.

### 4. Verify Backend Deployment

- **Access URL**: Visit the backend URL provided by Render (e.g., `https://choir-backend.onrender.com/docs`).
- **Test API Endpoints**:
  - Ensure that the `/docs` endpoint loads Swagger documentation.
  - Test API endpoints using the Swagger UI or via HTTP client.

## Updating Frontend to Communicate with Backend

1. **Set API URL in Frontend**:
   - In `frontend/.env` (or Render environment variables), set:
     ```
     NEXT_PUBLIC_API_URL=https://choir-backend.onrender.com
     ```

2. **Update API Calls**:
   - Ensure all API calls in the frontend use `process.env.NEXT_PUBLIC_API_URL` as the base URL.
     ```javascript
     const apiUrl = process.env.NEXT_PUBLIC_API_URL;
     const response = await fetch(`${apiUrl}/api/endpoint`);
     ```

3. **Redeploy Frontend**:
   - Commit changes and push to trigger a redeployment.
   - Alternatively, manually redeploy from the Render dashboard.

## Security & HTTPS

- **HTTPS by Default**:
  - Render automatically provides HTTPS for both services.
- **Ensure Secure Connections**:
  - All frontend-backend communications should use `https://`.
- **Update CORS and Security Middleware**:
  - Confirm that CORS settings are correctly configured in the backend.
  - Implement security best practices in both services.

## Continuous Deployment

- **Enable Auto-Deploy**:
  - For both services, enable auto-deploy on pushes to the main branch.
  - Test by making a small change and pushing to the repository.

## Monitoring and Logging

- **Set Up Logging**:
  - Use Render's built-in logs to monitor application behavior.
- **Configure Alerts**:
  - Set up alerts for deployment failures or runtime errors.
- **Performance Monitoring**:
  - Monitor response times and resource usage.

## Final Verification

- **End-to-End Testing**:
  - Verify that the frontend correctly communicates with the backend.
  - Test all user flows and API interactions.
- **Cross-Origin Issues**:
  - Ensure no CORS errors occur in the browser console.
- **Update Documentation**:
  - Document any changes made during deployment.
  - Ensure `tree.md` reflects the updated directory structure.

## Next Steps

- **Scaling Considerations**:
  - Evaluate if the instance types are sufficient.
  - Consider auto-scaling options if necessary.
- **Database Integration**:
  - If the backend requires a database, set up a managed database service on Render.
  - Update backend configuration with database credentials.
- **Authentication and Security**:
  - Implement authentication mechanisms (e.g., JWT tokens).
  - Secure API endpoints and handle user sessions.
- **CI/CD Pipeline**:
  - Consider setting up a CI/CD pipeline for automated testing and deployments.
- **Domain Setup**:
  - Point custom domains to the frontend and backend if desired.
  - Update SSL certificates if using custom domains.

## Clean Up

- **Remove Unused Services**:
  - Ensure that any old services or deployments are deleted to avoid unnecessary charges.
- **Review Costs**:
  - Monitor usage and costs on Render to optimize resource allocation.

This updated checklist helps you separate the Python backend from the codebase and redeploy both the frontend and backend independently on Render, as per the updated directory structure in **tree.md**.

# API Conversion Checklist

## Convert WebSocket API to REST Endpoints

1. **Core Chorus Cycle Endpoints**
   - [x] `POST /api/chorus/action`
     - Input: User message content
     - Output: Initial response
   - [x] `POST /api/chorus/experience`
     - Input: User message + action response
     - Output: Prior-enriched response
   - [x] `POST /api/chorus/intention`
     - Input: Previous responses
     - Output: Intent analysis
   - [x] `POST /api/chorus/observation`
     - Input: Previous responses
     - Output: Pattern observations
   - [x] `POST /api/chorus/understanding`
     - Input: Previous responses
     - Output: Loop decision
   - [x] `POST /api/chorus/yield`
     - Input: All previous responses
     - Output: Final synthesis

2. **Vector Database Operations**
   - [x] `POST /api/vectors/search`
     - Input: Query vector
     - Output: Similar vectors
   - [x] `POST /api/vectors/store`
     - Input: Content + vector
     - Output: Storage confirmation
   - [x] `GET /api/vectors/{id}`
     - Output: Vector data

3. **Embedding Generation**
   - [x] `POST /api/embeddings/generate`
     - Input: Text content
     - Output: Embedding vector

4. **Thread Management**
   - [x] `POST /api/threads`
     - Create new thread
   - [x] `GET /api/threads/{id}`
     - Get thread details
   - [x] `GET /api/threads/{id}/messages`
     - Get thread messages


## API Implementation Tasks

1. **Update FastAPI Routes**
   - [x] Remove WebSocket handler
   - [x] Create new router files for each domain
   - [x] Implement endpoint handlers
   - [x] Add request/response models

2. **Update Database Layer**
   - [ ] Simplify database client
   - [x] Remove WebSocket-specific code
   - [x] Add direct CRUD operations
   - [ ] Optimize query patterns

3. **Update Chorus Cycle**
   - [x] Convert to stateless operation
   - [x] Remove state management
   - [x] Accept full context in requests
   - [x] Return complete responses

4. **Update Configuration**
   - [x] Remove WebSocket configs
   - [x] Add REST-specific settings
   - [x] Update CORS configuration
   - [ ] Configure rate limiting

5. **Update Dependencies**
   - [x] Remove WebSocket dependencies
   - [x] Add REST-specific packages
   - [x] Update requirements.txt
   - [x] Update Docker configuration

## Testing Updates

1. **Unit Tests**
   - [x] Add endpoint tests
   - [x] Add request validation tests
   - [x] Add response validation tests
   - [x] Add error handling tests

2. **Integration Tests**
   - [x] Add API flow tests
   - [x] Add database operation tests
   - [x] Add embedding tests
   - [x] Add end-to-end tests

## Documentation Updates

1. **API Documentation**
   - [ ] Create OpenAPI specs
   - [ ] Document request/response formats
   - [ ] Add example requests
   - [ ] Document error responses

2. **Deployment Documentation**
   - [ ] Update deployment instructions
   - [ ] Document environment variables
   - [ ] Add monitoring guidelines
   - [ ] Update scaling recommendations

## Frontend Updates
## SWIFT!
1. **Update API Client**
   - [x] Remove WebSocket client
   - [x] Add REST client
   - [x] Update response handling
   - [x] Add error handling

UI and state management require work. up next, once we get this deployed!
2. **Update UI Components**
   - [ ] Update loading states
   - [ ] Add progress indicators
   - [ ] Update error displays
   - [ ] Optimize state management

## Deployment Steps

1. **Prepare New API**
   - [x] Test locally
   - [ ] Update environment variables
   - [ ] Test with production database
   - [ ] Verify all endpoints

2. **Deploy Updates**
   - [ ] Deploy new API version
   - [ ] Monitor for errors
   - [ ] Verify all endpoints
   - [ ] Check performance metrics

3. **Update Frontend**
   - [ ] Deploy frontend changes
   - [ ] Verify integration
   - [ ] Monitor error rates
   - [ ] Check user experience

This checklist outlines the steps needed to convert the current WebSocket-based API to a stateless HTTP API. Each section should be completed sequentially to ensure a smooth transition.
