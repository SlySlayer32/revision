---
applyTo: "**/*.dart"
---
# Dart-Specific Coding Guidelines

## Syntax & Language Features

- Use Dart's cascade notation (`..`) when performing multiple operations on the same object
- Use the spread operator (`...`) for combining collections
- Utilize collection-if and collection-for for conditional and repetitive collection elements
- Prefer using `final` for local variables that are not reassigned
- Use `const` constructors and literals whenever possible
- Leverage late initialization when appropriate (e.g., for non-nullable instance fields initialized in `initState` or by a dependency injection mechanism before first access), but be careful of `LateInitializationError`s

## Null Safety

- Design APIs to be null-safe by default
- Use nullable types (`Type?`) only when null is a meaningful value
- Avoid using `!` operator unless absolutely necessary
- Provide meaningful default values using `??` operator
- Use conditional property access (`?.`) for potentially null objects

## Asynchronous Programming

- Use `async`/`await` for cleaner asynchronous code instead of raw futures
- Handle exceptions in async code with try/catch blocks
- Use `Future.wait` for parallel operations
- Consider using `Stream` for values that change over time
- Close `StreamController` instances when they're no longer needed

## Code Documentation

- Document public APIs with dartdoc comments (`///`).
- Use `///` for documentation comments.
- Include examples in documentation for complex functionality.
- Document parameters, return values, and thrown exceptions (`/// @param`, `/// @returns`, `/// @throws [ExceptionType]`).
- Use the `required` keyword for named parameters that are mandatory in null-safe Dart. Avoid using the legacy `@required` annotation.

## Package Structure

- Follow the official package layout conventions
- Keep the main library file clean and focused on exports
- Place implementation files in 'src' directory
- Explicitly export public APIs from the main library file
- Use part/part of sparingly and only when appropriate

## Flutter-Specific Dart Guidelines

- Prefer named parameters in widget constructors for clarity
- Use key parameters appropriately for widget identification
- Override `operator ==` and `hashCode` for value equality in model classes
- Implement copyWith methods for immutable model classes
- Use the `BuildContext` extension methods when available
