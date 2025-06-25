---
applyTo: 'lib/**/infrastructure/**'
---

# 17 – AI Analysis Service Implementation (Infrastructure/Data)

**Objective**
Create the service class that sends the selected image to Vertex AI for analysis, handles retries, and parses the response into a prompt for editing.

**Context**
- You have `AiConfig` for credentials and settings.
- Use Dart HTTP client or Dio for requests.

**Tasks**
1. Create `AiAnalysisService` with method:
   ```dart
   Future<String> analyzeImage(Uint8List imageBytes)
   ```
2. Implement request flow:
   - Encode image to Base64 or multipart.
   - Send POST to `AiConfig.endpoint` with API key header.
   - Set timeout from config.
   - Retry up to 2 times on network errors.
3. Parse JSON response to extract the analysis prompt string.
4. Throw a custom `AiAnalysisException` on non-200 or empty body.
5. Write a basic unit test using a mock HTTP client.

**Validation Checkpoint**
- `analyzeImage` returns a non-empty prompt for a valid mock response.
- Fails with `AiAnalysisException` on error scenarios.
