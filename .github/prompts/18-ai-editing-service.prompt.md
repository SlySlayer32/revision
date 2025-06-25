---
applyTo: 'lib/**/infrastructure/**'
---

# 18 – AI Editing Service Implementation (Infrastructure/Data)

**Objective**
Implement the service class that forwards the analysis prompt and original image to the Vertex AI Imagen model to generate the edited image.

**Context**
- You have `AiAnalysisService` and `AiConfig`.

**Tasks**
1. Create `AiEditingService` with method:
   ```dart
   Future<Uint8List> editImage(Uint8List imageBytes, String prompt)
   ```
2. Request flow:
   - Multipart request with image file and prompt field.
   - Send to `AiConfig.editEndpoint`.
   - Show progress via returned stream or callback.
   - Timeout and retry as with analysis.
3. Parse binary response as `Uint8List`.
4. On error, throw `AiEditingException` with details.
5. Write a basic unit test mocking the HTTP client.

**Validation Checkpoint**
- `editImage` returns non-empty bytes for valid mock response.
- Error scenarios surface as `AiEditingException`.
