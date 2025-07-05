# Copilot Instructions Quick Reference Checklist

## ✅ Essential Principles

### Structure
- [ ] Use clear Markdown headers to organize sections
- [ ] Separate distinct instructions with whitespace
- [ ] Group related instructions together logically
- [ ] Use bullet points or numbered lists for clarity

### Language Patterns
- [ ] Write instructions in imperative voice ("Use X", "Create Y", "Implement Z")
- [ ] Be specific and concrete rather than vague or abstract
- [ ] Avoid external references (no "follow the style guide at...")
- [ ] Use positive directives instead of negative prohibitions

### Content Guidelines
- [ ] Make each instruction self-contained and actionable
- [ ] Provide context and purpose when needed
- [ ] Include specific technical requirements
- [ ] Break complex instructions into simple steps

## ❌ Common Pitfalls to Avoid

### Language Anti-Patterns
- [ ] ❌ Don't use: "Don't do X", "Avoid Y", "Never Z"
- [ ] ❌ Don't reference: External documentation or style guides
- [ ] ❌ Don't be vague: "Follow best practices", "Write clean code"
- [ ] ❌ Don't assume: Context that isn't explicitly provided

### Structural Issues
- [ ] ❌ Overly long instructions that combine multiple concepts
- [ ] ❌ Instructions that require interpretation or guesswork
- [ ] ❌ Inconsistent formatting or organization
- [ ] ❌ Missing context for technical requirements

## 🎯 Effective Instruction Examples

### ✅ Good: Specific and Actionable
```
Use TypeScript interfaces for all component props.
Implement loading states for async operations.
Create reusable components in the components/ directory.
```

### ❌ Poor: Vague and Unhelpful
```
Follow TypeScript best practices.
Handle async operations properly.
Organize components appropriately.
```

## 📝 Quick Templates

### For Code Generation
```
When creating [COMPONENT_TYPE]:
- Use [SPECIFIC_PATTERN] for implementation
- Include [REQUIRED_FEATURES] in the structure
- Add [TESTING_REQUIREMENTS] for validation
```

### For Project Structure
```
Follow [ARCHITECTURE_PATTERN] organization:
- Place [FILE_TYPE] in [DIRECTORY_PATH]
- Use [NAMING_CONVENTION] for file names
- Group [RELATED_ITEMS] together
```

### For Technical Requirements
```
For [TECHNOLOGY/FEATURE]:
- Implement [SPECIFIC_APPROACH] pattern
- Include [REQUIRED_DEPENDENCIES] setup
- Add [ERROR_HANDLING] mechanisms
```

## 🔍 Testing Your Instructions

### Clarity Test
- [ ] Can a new developer understand without additional context?
- [ ] Are all technical terms and patterns clearly defined?
- [ ] Is the expected outcome obvious from the instruction?

### Specificity Test
- [ ] Does each instruction provide enough detail to be actionable?
- [ ] Are there concrete examples where helpful?
- [ ] Are technical requirements measurable?

### Completeness Test
- [ ] Do instructions cover common development scenarios?
- [ ] Are error cases and edge cases addressed?
- [ ] Is the instruction set comprehensive but not overwhelming?

## 💡 Pro Tips

### Optimize for AI Processing
- Use consistent terminology throughout all instructions
- Structure instructions hierarchically from general to specific
- Include examples for complex patterns when possible
- Keep individual instructions focused on single concepts

### Maintain and Iterate
- Monitor AI-generated code for adherence to instructions
- Gather team feedback on instruction effectiveness
- Update instructions based on common issues or gaps
- Version control instruction changes for tracking impact

### Context-Aware Instructions
- Consider the development workflow and team practices
- Align instructions with project architecture and conventions
- Include technology-specific best practices
- Address both beginner and advanced use cases appropriately
