# Security Considerations for Choir (Qdrant-Sui MVP)

VERSION security_considerations: 8.0 (Qdrant-Sui MVP Focus)

## Introduction

This document outlines the security considerations for Choir's Qdrant-Sui Minimum Viable Product (MVP) architecture. This architecture centralizes AI workflow execution, data management (Qdrant), and blockchain interactions (Sui via `sui_service.py`) within a single Python API backend. Security focuses on protecting this central API, its data interactions, and the user's keys on the client side.

## Threat Model

The system addresses the following potential threats:

1.  **Blockchain Key Compromise**: Theft or unauthorized use of the API backend's private key used for Sui blockchain operations.
2.  **Contract Manipulation**: Unauthorized modification of the basic CHIP token contract parameters or execution (less likely with MVP's simple contract).
3.  **Token Theft**: Unauthorized triggering of reward distributions or transfers via the API.
4.  **Data Exfiltration**: Unauthorized access to or extraction of sensitive user or conversation data stored in Qdrant.
5.  **System Manipulation**: Unauthorized alterations to the API's behavior, PostChain workflow logic, or state stored in Qdrant.
6.  **Model Attacks**: Prompt injection, jailbreaking, or other attacks targeting the LLMs used within the PostChain workflow.
7.  **Resource Exhaustion**: Denial of service against the API backend or Qdrant through excessive requests.
8.  **Identity Spoofing**: Impersonation of legitimate users via compromised Sui keys or authentication bypass.
9.  **Infrastructure Compromise**: Attacks on the underlying infrastructure hosting the API backend and Qdrant (e.g., Render).

## Secure Blockchain Operations (MVP Context)

### Core Blockchain Security Goals

1.  **Secure Key Management**: Securely store and manage the private key used by the API backend's `sui_service.py` for Sui blockchain operations.
2.  **Protected Contract Interaction**: Ensure interactions with the Sui smart contract (basic CHIP token) are executed correctly.
3.  **Tamper-Proof Token Management**: Handle CHIP token reward distributions (simplified for MVP) in a way that prevents unauthorized manipulation.
4.  **Transaction Integrity**: Ensure that blockchain transactions initiated by the API are properly authorized and accurately reflect the intended action.

### Security Architecture (Centralized API Service)

1.  **API Backend Key Management:** The Sui private key used by `sui_service.py` is the most critical secret. It **must** be managed securely:
    *   **No Hardcoding:** Never hardcode the private key in the source code.
    *   **Environment Variables/Secrets:** Store the key securely using environment variables injected during deployment (e.g., Render's secret management).
    *   **Limited Access:** Restrict access to the production environment and secret management tools.
2.  **Controlled Interaction:** All blockchain interactions are funneled through the `sui_service.py` module within the API backend. This centralizes the logic and reduces the points where the key is directly used.
3.  **Input Validation:** The API must rigorously validate all parameters (recipient addresses, amounts) passed to `sui_service.py` functions before constructing blockchain transactions.

## Data Security Measures (Qdrant & API)

1.  **Data Classification:** Identify sensitive data stored in Qdrant (e.g., `intention_memory` content, user-Sui address mappings in `users`).
2.  **Encryption Architecture:**
    *   **Transit:** Use HTTPS for all communication between the client, API, and Qdrant (if Qdrant is hosted externally).
    *   **At Rest (Qdrant):** Rely on Qdrant's underlying storage mechanisms and the hosting provider's infrastructure for at-rest encryption. Consider Qdrant's specific encryption features if available and necessary.
    *   **At Rest (API Secrets):** Ensure the Sui private key and any other API secrets are stored encrypted at rest by the deployment platform (e.g., Render).
3.  **Qdrant Access Control:**
    *   Use API keys or other authentication mechanisms provided by Qdrant to restrict access to authorized services (only the Python API backend).
    *   Implement logical access control within the API backend to ensure, for example, that `intention_memory` is only queried for the currently authenticated user.

## Docker Container Security (API Backend)

1.  **Minimal Images:** Use minimal base images (like `python:3.12-slim`) for the API backend container to reduce the attack surface.
2.  **No Privileged Containers:** Run containers without unnecessary privileges.
3.  **Immutable Infrastructure:** Treat containers as immutable; rebuild and redeploy rather than modifying running containers.
4.  **Vulnerability Scanning:** Integrate vulnerability scanning into the CI/CD pipeline for the Docker image.
5.  **Secret Management:** Inject secrets (like the Sui private key, Qdrant API key) securely into the container environment at runtime, not during the build process.

## Model Security (PostChain Workflow)

1.  **Input Validation/Sanitization:** Sanitize user input passed to the PostChain workflow and subsequently to LLMs to mitigate prompt injection risks.
2.  **Output Filtering:** Filter or sanitize outputs from LLMs, especially if they might be displayed directly or used in sensitive contexts (though less critical if outputs primarily feed other phases or are stored).
3.  **Prompt Security:** Be mindful of prompt engineering techniques to make models less susceptible to jailbreaking or instruction hijacking, particularly for phases that might execute tools based on LLM output (deferred post-MVP).
4.  **Rate Limiting:** Implement rate limiting at the API gateway or within FastAPI to prevent abuse of LLM resources.
5.  **Model Usage Monitoring:** Monitor LLM usage for anomalies that might indicate attacks or misuse.

## Security Logging and Monitoring

1.  **Comprehensive Logging:** Log key security events within the API backend: authentication attempts (success/failure), significant state changes, calls to `sui_service.py`, errors, and potential security anomalies.
2.  **Qdrant Auditing:** If Qdrant provides audit logging features, enable them to monitor database access and operations.
3.  **Infrastructure Monitoring:** Utilize monitoring tools provided by the hosting platform (e.g., Render) to track resource usage, network traffic, and potential infrastructure-level threats.
4.  **Anomaly Detection:** Implement basic anomaly detection rules based on logs and metrics (e.g., sudden spike in failed authentications, unusual Qdrant query patterns, high rate of reward triggers).
5.  **Incident Response Plan:** Have a basic plan for responding to security incidents, including identifying the issue, containing the impact, remediating the vulnerability, and communicating appropriately.

## Future Security Enhancements (Post-MVP)

While the MVP focuses on core security, future enhancements could include:

1.  **Formal Verification:** For critical smart contracts (like a more complex FQAHO or governance contract).
2.  **Quantum-Resistant Cryptography:** For long-term key and signature security (relevant if Sui adopts it).
3.  **Web Application Firewall (WAF):** Protect the API endpoint from common web attacks.
4.  **Enhanced Authentication:** Implement more robust authentication mechanisms beyond simple signature verification if needed.
5.  **Dedicated Secrets Management:** Integrate a dedicated secrets management solution (e.g., HashiCorp Vault) instead of relying solely on platform environment variables.

## Conclusion (MVP Focus)

Securing the Choir Qdrant-Sui MVP relies heavily on securing the central Python API backend and its interactions. Key priorities include: **secure management of the API's Sui private key**, robust input validation for both API endpoints and LLM prompts, proper access control for Qdrant collections, and standard web application security practices for the API itself. While simpler than a distributed TEE-based architecture, this centralized model requires diligent protection of the API backend as the primary trusted component for data access and blockchain interactions in the MVP.
