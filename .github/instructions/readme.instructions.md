---
applyTo: '**'
---
# GitHub Copilot Instructions - Ampcode Style Production Development

## Core Philosophy
- Write production-ready code from the start, not prototypes
- Prioritize maintainability, scalability, and performance
- Follow enterprise-grade patterns and practices
- Implement comprehensive error handling and logging
- Write self-documenting code with clear intent

## Code Quality Standards

### Architecture & Design Patterns
- Use SOLID principles and clean architecture
- Implement dependency injection and inversion of control
- Apply appropriate design patterns (Factory, Strategy, Observer, etc.)
- Separate concerns with clear boundaries between layers
- Use composition over inheritance

### Error Handling & Resilience
- Implement comprehensive error handling with specific exception types
- Add retry logic with exponential backoff for external calls
- Include circuit breaker patterns for service dependencies
- Log errors with correlation IDs and structured logging
- Validate all inputs and sanitize outputs

### Performance & Scalability
- Write async/await code where appropriate
- Implement proper connection pooling and resource management
- Use caching strategies (Redis, in-memory) with TTL
- Optimize database queries with proper indexing considerations
- Implement pagination for large datasets

### Security Best Practices
- Validate and sanitize all user inputs
- Use parameterized queries to prevent SQL injection
- Implement proper authentication and authorization
- Hash passwords with salt using bcrypt or similar
- Use HTTPS and secure headers
- Implement rate limiting and request throttling

## Code Structure Requirements

### Functions & Methods
- Keep functions small and focused (single responsibility)
- Use descriptive names that explain intent
- Include comprehensive JSDoc/docstring comments
- Add input validation and type checking
- Return consistent response formats

### Classes & Modules
- Use TypeScript interfaces and types for all data structures
- Implement proper encapsulation with private/protected members
- Add constructor validation and initialization
- Include static factory methods where appropriate
- Export only necessary public APIs

### Database & Data Access
- Use repository pattern for data access
- Implement database transactions for multi-step operations
- Add connection pooling and timeout configurations
- Include database migration scripts
- Use ORM/ODM with proper entity relationships

## Testing Requirements
- Write unit tests for all business logic
- Include integration tests for API endpoints
- Add end-to-end tests for critical user flows
- Mock external dependencies properly
- Achieve minimum 80% code coverage

## Documentation Standards
- Include README with setup, usage, and deployment instructions
- Document API endpoints with OpenAPI/Swagger specs
- Add inline comments for complex business logic
- Include architecture diagrams and decision records
- Document environment variables and configuration

## Technology-Specific Guidelines

### Node.js/TypeScript
- Use strict TypeScript configuration
- Implement proper middleware chain for Express
- Use environment-based configuration with validation
- Include health check endpoints
- Implement graceful shutdown handling

### React/Frontend
- Use functional components with hooks
- Implement proper state management (Redux/Zustand)
- Add loading states and error boundaries
- Use TypeScript for all components and props
- Implement proper form validation

### Python
- Follow PEP 8 style guidelines
- Use type hints for all functions and classes
- Implement proper virtual environment setup
- Use dataclasses or Pydantic for data models
- Include proper logging configuration

### Database
- Use migrations for schema changes
- Implement proper indexing strategies
- Add foreign key constraints and relationships
- Use connection pooling
- Include backup and recovery procedures

## Deployment & DevOps
- Include Dockerfile with multi-stage builds
- Add docker-compose for local development
- Include CI/CD pipeline configuration
- Add environment-specific configuration files
- Implement health checks and monitoring

## Code Examples Format
When providing code examples:
1. Include complete, runnable implementations
2. Add comprehensive error handling
3. Include relevant imports and dependencies
4. Add configuration and setup code
5. Include test examples
6. Add deployment configurations

## Response Structure
For each code suggestion:
1. Explain the architectural approach
2. Provide the complete implementation
3. Include error handling and edge cases
4. Add relevant tests
5. Suggest monitoring and logging
6. Include deployment considerations

## Quality Checklist
Before suggesting code, ensure:
- [ ] Follows SOLID principles
- [ ] Includes comprehensive error handling
- [ ] Has proper input validation
- [ ] Uses appropriate design patterns
- [ ] Includes logging and monitoring
- [ ] Has security considerations
- [ ] Is properly typed/documented
- [ ] Includes relevant tests
- [ ] Considers performance implications
- [ ] Follows project conventions

## Ampcode-Specific Behaviors
- Always think in terms of production systems
- Consider scalability from day one
- Implement monitoring and observability
- Use infrastructure as code approaches
- Design for failure and recovery
- Prioritize developer experience and maintainability
- Include comprehensive documentation
- Think about the entire software lifecycle
- Use version control and branching strategies