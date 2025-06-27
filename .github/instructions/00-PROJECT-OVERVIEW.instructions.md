---
applyTo: '**'
---

# 📱 Aura: AI-Powered Photo Editor - Complete Project Overview

## 🎯 Project Vision & Mission

**Aura** is a production-grade AI-powered photo editor that enables users to seamlessly remove objects from images and regenerate content using advanced AI. This application must work flawlessly across iOS, Android, and web platforms.

## 🚫 ABSOLUTE ZERO TOLERANCE POLICIES

### No Mock Implementations
- All features MUST connect to real Firebase services
- All AI features MUST use actual Vertex AI/Gemini APIs
- No placeholder functions or simulated endpoints in production code
- Every service call must be to a live, working API

### No Hardcoded Credentials
- ALL API keys must use `--dart-define` environment variables
- NEVER commit secrets to version control
- Use Firebase Remote Config for non-sensitive configuration
- All sensitive data through secure environment management

### No Demo-Grade Code
- Every feature must be production-ready from day one
- Implement robust error handling for ALL scenarios
- Performance optimization is mandatory, not optional
- Security measures must be comprehensive

### No Architecture Bypassing
- STRICT adherence to VGV Clean Architecture
- Every feature must follow 3-layer separation
- Domain layer must never depend on Flutter or external frameworks
- Repository pattern is mandatory for all data access

## 🏗️ Technical Architecture Foundation

### 3-Layer Clean Architecture (MANDATORY)
```
🎨 Presentation Layer (UI)
├── Pages (Route-level screens)
├── Widgets (Reusable UI components)
├── BLoCs (State management)
└── View Models (UI logic)

🧠 Domain Layer (Business Logic)
├── Entities (Core business objects)
├── Use Cases (Business operations)
├── Repository Interfaces (Data contracts)
└── Domain Services (Business rules)

💾 Data Layer (External World)
├── Repository Implementations
├── Data Sources (APIs, databases)
├── Models (Data transfer objects)
└── Mappers (Data transformation)
```

### Dependency Injection (GetIt)
- ALL dependencies must be registered in service locator
- Feature-specific dependencies in separate modules
- Interface-based dependency injection throughout
- Singleton pattern for shared services

### State Management (BLoC Pattern)
- flutter_bloc for ALL state management
- Events for user interactions
- States for UI rendering
- BLoCs never directly call external services

### Error Handling (Either Pattern)
- dartz package for functional error handling
- Either<Failure, Success> for all operations
- Custom failure types for different error categories
- Never throw exceptions in business logic

## 🔥 Core Features & User Journey

### 1. Authentication System
- Email/password authentication via Firebase Auth
- Google Sign-In integration
- Secure session management
- Password reset functionality

### 2. Image Processing Pipeline
- Image selection from gallery or camera
- Real-time mask drawing on images
- Object detection and selection assistance
- AI-powered prompt generation

### 3. AI Integration (Vertex AI)
- Image analysis using Gemini Vision models
- Natural language prompt generation
- Image regeneration with inpainting
- Content-aware object removal

### 4. Data Management
- Firebase Storage for image files
- Firestore for metadata and user data
- Offline capability with sync
- Data privacy and security compliance

### 5. User Experience
- Intuitive drawing tools for object selection
- Real-time preview of AI suggestions
- Gallery of edited images
- Sharing and export capabilities

## 📚 Technology Stack & Dependencies

### Core Framework
- **Flutter SDK**: Latest stable (3.24.0+)
- **Dart SDK**: Compatible version
- **Platform Support**: iOS, Android, Web

### Firebase Services
- **firebase_core**: Firebase initialization
- **firebase_auth**: User authentication
- **cloud_firestore**: NoSQL database
- **firebase_storage**: File storage
- **firebase_analytics**: Usage analytics
- **cloud_functions**: Backend processing

### AI & Machine Learning
- **google_generative_ai**: Gemini API access
- **Vertex AI**: Google's ML platform
- **Image processing**: Custom algorithms

### State Management & Architecture
- **flutter_bloc**: BLoC pattern implementation
- **equatable**: Value equality for states
- **dartz**: Functional programming utilities
- **get_it**: Dependency injection

### Image Handling
- **image_picker**: Camera/gallery access
- **image**: Image manipulation
- **flutter_painting**: Custom drawing tools
- **image_gallery_saver**: Save to device

### UI & User Experience
- **Material Design 3**: Modern UI components
- **Custom painters**: Drawing interfaces
- **Animation**: Smooth transitions
- **Responsive design**: Multi-platform support

### Development & Testing
- **very_good_analysis**: Linting rules
- **bloc_test**: BLoC testing utilities
- **mocktail**: Mocking framework
- **integration_test**: End-to-end testing

## 🔐 Security & Privacy Requirements

### Data Protection
- End-to-end encryption for sensitive data
- Secure API key management
- User data anonymization options
- GDPR/CCPA compliance measures

### Authentication Security
- Multi-factor authentication support
- Secure session tokens
- Automatic logout on inactivity
- Device-specific security measures

### AI Privacy
- On-device processing where possible
- Minimal data retention policies
- User consent for AI processing
- Transparent data usage policies

## 🚀 Performance Requirements

### Application Performance
- Cold start time < 3 seconds
- Image processing < 10 seconds
- Smooth 60fps UI animations
- Memory usage optimization

### Network Efficiency
- Automatic retry mechanisms
- Intelligent caching strategies
- Bandwidth optimization
- Offline functionality

### Scalability
- Support for 100K+ concurrent users
- Auto-scaling backend services
- CDN for global content delivery
- Database optimization

## 🧪 Quality Assurance Standards

### Testing Coverage
- **Domain Layer**: 100% test coverage
- **Data Layer**: 95%+ test coverage
- **Presentation Layer**: 90%+ test coverage
- **Integration Tests**: All critical user flows

### Code Quality
- Static analysis with very_good_analysis
- Code review process for all changes
- Documentation for all public APIs
- Performance profiling and optimization

### Deployment Pipeline
- Automated testing in CI/CD
- Staged deployment (dev → staging → production)
- Feature flags for gradual rollouts
- Monitoring and alerting systems

## 🌍 Internationalization & Accessibility

### Multi-language Support
- English (primary)
- Spanish, French, German, Japanese
- RTL language support
- Cultural adaptation

### Accessibility Features
- Screen reader compatibility
- High contrast mode support
- Keyboard navigation
- Voice control integration

## 📈 Analytics & Monitoring

### User Analytics
- Feature usage tracking
- Performance metrics
- Error reporting and crash analytics
- User journey analysis

### Business Metrics
- Conversion rates
- Retention metrics
- Feature adoption rates
- Revenue tracking (if applicable)

## 🔄 Development Workflow

### Version Control
- Git with conventional commits
- Feature branch workflow
- Pull request reviews
- Automated quality checks

### Release Management
- Semantic versioning
- Release notes generation
- Staged rollouts
- Rollback procedures

### Documentation
- Code documentation (dartdoc)
- API documentation
- User guides
- Developer onboarding

## 🎯 Success Criteria

### Technical Metrics
- 99.9% uptime
- < 3 second load times
- Zero critical security vulnerabilities
- 95%+ user satisfaction rating

### Business Goals
- 10K+ monthly active users in first quarter
- 4.5+ app store rating
- < 5% churn rate
- Successful AI feature adoption

This document serves as the foundation for all development decisions. Every line of code, every architectural choice, and every feature implementation must align with these principles and requirements.
