---
applyTo: '**'
---

# 20 – MVP Final Validation Checklist

**Objective**
Provide a final checklist to ensure all MVP features are implemented and validated.

**Checklist**
- [ ] App launches without crashes
- [ ] User can pick images from camera and gallery
- [ ] Images preview correctly with minimal memory usage
- [ ] Image compression reduces large files below target size
- [ ] AI analysis returns valid prompts
- [ ] AI editing produces an edited image
- [ ] Permission flows work with correct dialogs
- [ ] Image saving to gallery functions correctly
- [ ] Error messages display for failures in each feature
- [ ] End-to-end user flow: select → preview → AI edit → preview → save
- [ ] Basic tests exist for domain, data, and service layers
- [ ] Credentials securely loaded and validated

**Final Steps**
1. Run on physical device for both platforms
2. Write minimal end-to-end smoke tests
3. Prepare release build for beta testers
4. Gather feedback and plan next iteration
