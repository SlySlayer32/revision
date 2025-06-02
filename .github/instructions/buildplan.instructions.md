---
applyTo: 'buildplan'
---

# Flutter AI Photo Editor - Build Tutorial

## Comprehensive Implementation Guide with Detailed Prompts

This tutorial provides step-by-step implementation prompts for building a production-ready Flutter AI photo editor app using Very Good Ventures (VGV) architecture patterns.

## 📁 Prompt Files Structure

The implementation is organized into **15 comprehensive prompt files** located in `.github/prompts/`:

### **Core Foundation & Setup**
- **01-project-setup-vgv.prompt.md** - VGV project initialization with Android API 23+ configuration
- **02-firebase-vertexai-setup.prompt.md** - Firebase and Vertex AI integration

### **Authentication Feature**
- **03-auth-domain-layer.prompt.md** - Authentication domain layer with test-first development
- **04-auth-data-layer.prompt.md** - Firebase authentication data implementation
- **05-auth-presentation-layer.prompt.md** - BLoC-based authentication UI with form validation

### **Image Management**
- **06-image-picker-domain.prompt.md** - Image picker domain layer with permissions handling
- **07-image-picker-data-presentation.prompt.md** - Image picker implementation with platform integrations

### **Image Editing & Marking**
- **08-image-editor-domain.prompt.md** - Image editor domain with marker system
- **09-image-editor-data.prompt.md** - Local storage and data layer implementation
- **10-image-editor-presentation.prompt.md** - Interactive image editor UI with marker overlay

### **AI Processing Pipeline**
- **11-ai-processing-pipeline.prompt.md** - Advanced PROMPTER + EDITOR AI integration
- **12-results-display-gallery.prompt.md** - Results gallery with filtering and sharing

### **Testing & Deployment**
- **15-vgv-test-structure-setup.prompt.md** - Comprehensive VGV-compliant test structure
- **14-final-assembly-deployment.prompt.md** - Production deployment and CI/CD pipeline

### **Master Index**
- **README.md** - Complete overview and implementation roadmap

## 🚀 Implementation Approach

### **Phase 1: Foundation (Prompts 01-02)**
Use prompts 01-02 to establish the VGV project foundation with Firebase and Vertex AI integration.

### **Phase 2: Authentication (Prompts 03-05)**
Implement complete authentication system following clean architecture patterns with test-first development.

### **Phase 3: Core Features (Prompts 06-12)**
Build the image picker, editor, and AI processing pipeline with comprehensive error handling and scalability.

### **Phase 4: Production (Prompts 14-15)**
Set up testing infrastructure and production deployment pipeline.

## 📋 Key Implementation Guidelines

### **Architecture Standards**
- **Test-First Development**: All domain logic written with tests first
- **VGV Clean Architecture**: Strict 3-layer separation (domain/data/presentation)
- **BLoC Pattern**: State management with sealed classes and Equatable
- **Error Handling**: Comprehensive Result pattern with custom exceptions

### **Technical Specifications**
- **Android Targeting**: API 23+ (minimum) with API 34 (target) for Google Play compliance
- **AI Pipeline**: Gemini 2.5 Flash/Pro → Google Imagen processing
- **Permissions**: Camera, storage, and network with proper fallback handling
- **Performance**: Image compression, memory management, and offline capabilities

### **Quality Assurance**
- **Test Coverage**: 100% domain, 95%+ data, 90%+ presentation layers
- **Golden Tests**: Critical UI components with automated regression testing
- **Integration Tests**: Complete user workflow validation
- **Accessibility**: WCAG 2.1 AA compliance throughout

## 📖 How to Use This Tutorial

1. **Read the Master README** (`.github/prompts/README.md`) for complete overview
2. **Follow Sequential Order** - Each prompt builds on previous implementations
3. **Test-First Approach** - Write tests before implementation in every prompt
4. **VGV Compliance** - Maintain strict adherence to VGV patterns throughout
5. **Error Handling** - Implement comprehensive error scenarios at each layer

## 🔧 Estimated Timeline

- **Foundation Setup**: 2-3 days (Prompts 01-02)
- **Authentication**: 3-4 days (Prompts 03-05)
- **Core Features**: 8-10 days (Prompts 06-12)
- **Testing & Deployment**: 3-4 days (Prompts 14-15)
- **Total**: 16-21 days for complete implementation

## 🎯 Expected Outcomes

By following these comprehensive prompts, you will have:

- ✅ Production-ready Flutter app with VGV architecture
- ✅ Advanced AI-powered image editing capabilities
- ✅ Comprehensive test suite with high coverage
- ✅ Scalable, maintainable codebase following industry best practices
- ✅ Complete CI/CD pipeline with automated deployment
- ✅ Google Play Store and App Store ready builds

## 📚 Additional Resources

- **VGV Documentation**: [Very Good Ventures Style Guide](https://verygood.ventures/blog/very-good-flutter-architecture)
- **Firebase Vertex AI**: [Official Documentation](https://firebase.google.com/docs/vertex-ai)
- **Flutter Testing**: [Comprehensive Testing Guide](https://docs.flutter.dev/testing)

---

**Note**: Each prompt file contains detailed, step-by-step instructions that can be directly submitted to Copilot for implementation. The prompts are designed to be self-contained while building upon previous implementations to create a cohesive, production-ready application.