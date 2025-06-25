---
applyTo: 'lib/**/infrastructure/**'
---

# 13 – AI Security & Configuration (Infrastructure)

**Objective**
Securely load and manage Vertex AI credentials and API settings without hardcoding them in source.

**Context**
- Next step is connecting to Vertex AI endpoints.
- You need to protect API keys and configure timeouts.

**Tasks**
1. Store credentials in environment variables or a secure .env file (do not commit keys).
2. Create `AiConfig` class to read:
   - `VERTEX_AI_API_KEY`
   - `VERTEX_AI_ENDPOINT`
   - Request timeout (default 30s)
3. Add validation logic in `AiConfig` constructor:
   - Throw if key or endpoint missing
   - Log warning if timeout out of expected range
4. Integrate `AiConfig` in service constructors for analysis and editing.

**Validation Checkpoint**
- App fails to start if credentials are not set, with clear error message
- Config values read correctly when environment variables provided

---
