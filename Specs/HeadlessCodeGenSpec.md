# Swift Headless Code Generation Specification

This specification outlines patterns and requirements for generating high-quality Swift code for headless applications in Swift 6.2+. It emphasizes type-safe APIs, concurrency with async/await and actors, JSON serialization via Codable, and extensibility. The guidelines are general-purpose, applicable to various domains (e.g., API clients, configuration, data processing). Use only Foundation; no external dependencies except for optional performance benchmarks (detailed below). Minimum platforms: macOS 12.0, iOS 15.0, and Swift 6.2+ toolchain on Linux (e.g., Ubuntu 22.04+ for server-side compatibility).

## General Requirements

* **Type Safety**: Use protocols to define extensible interfaces. Enums for fixed options (e.g., states). Structs for value types to ensure immutability and performance. Avoid classes unless necessary for reference semantics.

* **Configuration and Initialization**: Support multiple initializers: one with defaults for simple setup (with throws for validation), another with explicit parameters for flexibility. Rethrow errors from initializers to propagate validation failures.

* **Validation**: Throw custom errors during initialization for invalid values (e.g., range checks, required fields). Use a descriptive error enum conforming to LocalizedError for user-friendly descriptions. Define standard validation ranges where applicable, and chain validations, throwing on first failure.

* **Extensibility**: Allow custom conformances to protocols. Support future additions via flexible encoding. Provide diverse examples: e.g., for data processing domains, extend protocols for structured queries; for configurations, add custom types for logging levels or timeouts.

* **JSON Compatibility**: Align with common formats using Codable. Use CodingKeys for key mapping (e.g., snake_case). Handle existential types (e.g., any Protocol) with custom encoding: implement a type-erased wrapper (e.g., AnyEncodable) for heterogeneous arrays, using a switch on concrete types in encode(to:) or decode(from:). For arrays, use a nestedUnkeyedContainer and encode/decode each element's properties manually to avoid type erasure issues. Example for decoding:
  ```swift
  init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    while !container.isAtEnd {
      let elementDecoder = try container.superDecoder()
      // Switch on type discriminator or attempt decoding concrete types
      if let concrete = try? ConcreteType(from: elementDecoder) {
        // Append concrete
      } else {
        throw DecodingError.typeMismatch(...)
      }
    }
  }
  ```

* **Performance**: Favor value types (structs/enums) and compile-time features (@inlinable) to minimize runtime overhead. Use async inference where possible to reduce boilerplate in async methods. For performance benchmarks, use manual timing with DispatchTime or CFAbsoluteTimeGetCurrent in core code; optionally, in a separate Benchmarks target, integrate the swift-benchmark package (add as a dependency in Package.swift for that target only) with examples like Benchmark.main().

* **Headless Compatibility**: Ensure code is usable in headless server environments (e.g., REST servers). Avoid dependencies on UI frameworks (e.g., UIKit, AppKit, SwiftUI). Make features like @Observable optional via conditional compilation (e.g., #if canImport(Observation)). The code must compile and run on Linux for server-side deployment; validate via swift build --platform linux.

## Code Organization and Modularization

* **Modular Architecture**: Generate code using a modular file structure rather than monolithic files. Break down functionality into focused modules based on responsibility and coupling. This improves maintainability, testing, and developer experience.

* **Module Organization**:
  - **Core Module**: Basic types, protocols, and foundational utilities (e.g., Core.swift)
  - **Domain Modules**: Feature-specific modules (e.g., Messages.swift, Configuration.swift, API.swift)
  - **Infrastructure Modules**: Networking, persistence, or external integrations (e.g., Client.swift)
  - **Utility Modules**: Builders, helpers, and convenience functions (e.g., Builders.swift, Convenience.swift)
  - **Main Module**: Entry point with documentation and module coordination (e.g., PackageName.swift)

* **File Naming Conventions**:
  - Use PascalCase for file names matching the primary type they contain
  - Prefer descriptive names over abbreviations (e.g., `ConfigurationParameters.swift` over `ConfigParams.swift`)
  - Use plural names for collections (e.g., `Messages.swift` for message types)
  - Reserve main file name for the package entry point (e.g., `SwiftResponsesDSL.swift`)

* **Import/Export Strategy**:
  - Avoid explicit imports within the same module - leverage automatic availability
  - Use `_exported import` sparingly for public API surface management
  - Document module dependencies clearly in comments
  - Ensure no circular dependencies between modules

* **Cross-Module Dependencies**:
  - Define protocols in core modules, implementations in domain modules
  - Use dependency injection for external services
  - Prefer composition over inheritance for module interactions
  - Document public API contracts between modules

* **Testing Considerations**:
  - Create test files mirroring module structure (e.g., `CoreTests.swift`, `MessagesTests.swift`)
  - Test modules in isolation when possible
  - Use protocol mocks for cross-module dependencies
  - Include integration tests for module interactions

* **Documentation Standards**:
  - Include module-level documentation in the main file
  - Document module responsibilities and dependencies
  - Provide usage examples for each module's primary functionality
  - Use consistent comment styles across all modules

* **Generated Code Standards**:
  - Include standard header comments in every generated file
  - Document generation metadata (version, date, spec reference)
  - Include modification policy and history sections
  - Reference the generating specification and version

* **Modern Swift Features**: Leverage Swift 6.2+ capabilities:
  - **Macros**: Use for code generation and compile-time validation (e.g., @attached(member) macros for builder patterns)
  - **Improved Generics**: Utilize enhanced generic parameter inference and variadic generics where appropriate
  - **Type-level Programming**: Use phantom types and type-level computations for enhanced type safety
  - **Compile-time Evaluation**: Employ consteval and build-time checks for validation
  - **Ownership and Borrowing**: Use Swift's ownership model for performance-critical code
  - **C++ Interoperability**: Enable C++ interop when interfacing with C++ libraries (Swift 6.2+)

## Concurrency Requirements

* **Asynchronous Operations**: Use async/await for I/O-bound tasks (e.g., networking). Mark methods as async throws where appropriate, leveraging async inference for trailing closures.

* **Thread Safety**: Employ actors to manage shared state (e.g., clients with sessions). Use nonisolated for methods that don't access isolated state, improving usability. Explicitly document isolated vs. nonisolated: e.g., mark actor methods as isolated if they mutate state, nonisolated for pure computations. For types with mutable state intended for concurrent access, wrap mutable state in an actor or use @MainActor if UI-bound.

* **Sendable Conformance**: Ensure all types crossing concurrency domains conform to Sendable (Swift 6 strict concurrency). Explicitly avoid capturing non-Sendable types in closures; simulate compiler diagnostics by checking for common pitfalls like capturing mutable vars. For custom types, mark properties as @unchecked Sendable if necessary (e.g., for legacy interop), with justification in doc comments (e.g., "/// @unchecked Sendable: Type is thread-safe via internal locking."). All error types and enums with associated values must explicitly conform to Sendable and Equatable. Use String or custom Equatable types in associated values (e.g., case taskFailed(String) or case customError(MyEquatableError)).

* **Streaming**: Support streaming responses with AsyncStream for incremental processing, handling errors via continuation.finish(throwing:). Include notes on buffering (e.g., use AsyncBufferedByteIterator for large streams), backpressure (via await on next()), combining increments (e.g., a reduce function to merge partial data into a full response), and cancellation (e.g., check Task.isCancelled in loops).

* **Networking**: Use URLSession for HTTP requests, with configurable sessions. Handle authentication, headers, and errors asynchronously. Support timeouts and retries via URLSessionConfiguration. Explicitly support GET/POST; for advanced needs like multipart, use Data and URLRequest; exclude WebSockets unless specified in functional spec.

* **Swift 6.2+ Concurrency Considerations**:
  - **Region-based Isolation**: Use @isolated(any) parameters for cross-actor calls and improved composability
  - **Noncopyable Types**: Leverage ~Copyable for performance-critical resources that shouldn't be copied
  - **Clock and Time**: Use Swift's Clock protocol for testable time-based operations
  - **AsyncIteratorProtocol**: Prefer AsyncSequence for streaming operations with proper backpressure
  - **Custom Executors**: Implement custom executors for specialized threading requirements
  - **Distributed Actors**: Use for distributed computing scenarios across process boundaries
  - **Task Local Values**: Leverage TaskLocal for context propagation in async operations
  - Resolve naming conflicts, e.g., use typealias ConcurrencyTask = _Concurrency.Task if defining a custom Task protocol.
  - In actor isolation, avoid capturing self directly in closures to prevent data races; use [self] capture lists or static methods.
  - For generic parameter inference, Swift 6.1 has improved inference but still requires explicit generics in complex contexts
  - Use async let for independent tasks; minimize unnecessary await to reduce actor hopping.
  - Prefer structured concurrency (e.g., TaskGroup) exclusively; no Dispatch.

  | Rule | Example | Rationale |
  |------|---------|-----------|
  | Use async let | async let result1 = task1(); async let result2 = task2(); let combined = await (result1, result2) | Run independent tasks concurrently to minimize suspension points |
  | Explicit generics | func process<T: Sendable>(item: T) async | Swift 6.1 has improved inference but explicit generics ensure clarity |
  | Avoid self capture | actor MyActor { func run() { Task { [weak self] in await self?.mutate() } } } | Prevent data races in closures |
  | TaskGroup for parallelism | try await withThrowingTaskGroup(of: Result.self) { group in ... } | Structured over unstructured Tasks |
  | Region-based isolation | func process(@isolated(any) actor: isolated Actor) | Improved cross-actor composability |
  | Noncopyable resources | struct FileHandle: ~Copyable | Prevent unnecessary copying of resources |

## Enums

* ```swift
  enum CustomError: Error, LocalizedError, Equatable, Sendable {
    case invalidURL, encodingFailed(String), networkError(String), decodingFailed(String), serverError(statusCode: Int, message: String?), rateLimit, invalidResponse, invalidValue(String), missingRequiredField
    case timeout(after: Duration), cancellation, resourceExhausted, preconditionFailed(String)
    case securityViolation(String), dataCorruption(String), incompatibleVersion(String)

    var errorDescription: String? {
      switch self {
        case .invalidURL: return "The provided URL is invalid"
        case .encodingFailed(let msg): return "Failed to encode data: \(msg)"
        case .networkError(let msg): return "Network operation failed: \(msg)"
        case .decodingFailed(let msg): return "Failed to decode data: \(msg)"
        case .serverError(let code, let msg): return "Server error (\(code)): \(msg ?? "Unknown error")"
        case .rateLimit: return "Rate limit exceeded"
        case .invalidResponse: return "Received invalid response"
        case .invalidValue(let msg): return "Invalid value: \(msg)"
        case .missingRequiredField: return "Required field is missing"
        case .timeout(let duration): return "Operation timed out after \(duration)"
        case .cancellation: return "Operation was cancelled"
        case .resourceExhausted: return "System resources exhausted"
        case .preconditionFailed(let msg): return "Precondition failed: \(msg)"
        case .securityViolation(let msg): return "Security violation: \(msg)"
        case .dataCorruption(let msg): return "Data corruption detected: \(msg)"
        case .incompatibleVersion(let msg): return "Version incompatibility: \(msg)"
      }
    }

    var recoverySuggestion: String? {
      switch self {
        case .rateLimit: return "Please wait before retrying the request"
        case .timeout: return "Check network connectivity and try again"
        case .networkError: return "Verify network settings and try again"
        default: return nil
      }
    }
  }
  ```
  * Example: Modern error handling with comprehensive cases, localized descriptions, and recovery suggestions. Uses Swift 6.1 Duration for timeout representation and includes security/data integrity error cases.

## Protocols

* ```swift
  public protocol LoggerProtocol: Sendable { 
    func log(level: LogLevel, message: String) 
  }
  ```
  * Example: For customizable logging. Default implementation uses os_log on Apple platforms or console on Linux. Injectable for testing/server customization.

* ```swift
  public enum LogLevel: String, Sendable, CaseIterable {
    case debug = "DEBUG", info = "INFO", warning = "WARNING", error = "ERROR", critical = "CRITICAL"

    var priority: Int {
      switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        case .critical: return 4
      }
    }
  }
  ```

## Security Best Practices

* **Input Validation**: Use Swift's type system and runtime checks to validate all inputs
* **Secure Coding**: Avoid unsafe APIs, use safe alternatives for string operations
* **Memory Safety**: Leverage Swift's memory safety features, avoid unsafe pointers
* **Cryptography**: Use CryptoKit for cryptographic operations (Swift 6.2+)
* **Authentication**: Implement secure authentication patterns with proper token handling
* **Data Protection**: Use appropriate data protection classes for sensitive information

## Observability & Monitoring

* **Logging**: Implement structured logging with context propagation
* **Metrics**: Use modern observability patterns for performance monitoring
* **Tracing**: Implement distributed tracing for request flow visibility
* **Health Checks**: Provide health check endpoints for service monitoring
* **Diagnostics**: Include diagnostic information for troubleshooting

## Modern Swift 6.2+ Language Features

### Macros and Code Generation
```swift
// Example macro usage for builder patterns
@attached(member, names: named(init), named(build))
@attached(conformance)
public macro Builder() = #externalMacro(module: "BuilderMacros", type: "BuilderMacro")
```

### Advanced Generics
```swift
// Variadic generics for flexible parameter handling
func processValues<each Value: Sendable>(
  values: repeat each Value
) async throws -> (repeat each Value) {
  // Process each value concurrently
  async let results = (repeat await processValue(each values))
  return (repeat each results)
}
```

### Noncopyable Types
```swift
// File handle that cannot be copied
struct FileHandle: ~Copyable, Sendable {
  private let descriptor: Int32

  consuming func close() throws {
    // Close and invalidate the file descriptor
  }
}
```

### Custom Executors
```swift
// Custom executor for specialized threading
public final class NetworkExecutor: SerialExecutor {
  public func enqueue(_ job: consuming ExecutorJob)
  public func asUnownedSerialExecutor() -> UnownedSerialExecutor
}
```

## Implementation Details

* Mark public APIs as public; internals private.

* **Generated Code Standards**: Every generated Swift code file must include a comprehensive header comment following Apple's Swift conventions and modern practices. The header must accommodate both initial generation and future modifications:

```swift
//
//  [FileName].swift
//  SwiftResponsesDSL
//
//  Generated by AI-assisted code generation.
//  Created by Richard Naszcyniec on [Date].
//  Copyright © [Year] Richard Naszcyniec. All rights reserved.
//
//  This file is part of SwiftResponsesDSL.
//  License: [SPDX-License-Identifier: MIT] or see LICENSE file.
//
//  === CODE GENERATION INFO ===
//  Generated with: [Generator Name] [Version]
//  Specification: [Spec Version] ([Spec Date])
//  Generation ID: [Unique ID for tracking]
//
//  === MODIFICATION POLICY ===
//  This file was automatically generated. While modifications are allowed
//  for debugging, customization, or extension purposes, please:
//
//  1. Update the modification history below
//  2. Preserve the original generation metadata
//  3. Consider regenerating from source when possible
//  4. Document significant changes in comments
//
//  === MODIFICATION HISTORY ===
//  [Date] - [Modifier] - [Change Description]
//  - Example: 2024-01-15 - John Doe - Added custom validation logic
//  - Example: 2024-02-01 - Jane Smith - Fixed threading issue in async method
//
//  Last Modified: [Date]
//  Modified By: [Name/Role]
//
```

**Alternative Modern Format (SPDX-Only):**
```swift
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftResponsesDSL open source project
//
// Copyright (c) [Year] Richard Naszcyniec
// Licensed under MIT License
//
// See https://github.com/RichNasz/SwiftResponsesDSL/blob/main/LICENSE for license information
// See https://github.com/RichNasz/SwiftResponsesDSL for project repository
//
// === IMPORTANT NOTICE FOR MAINTAINERS ===
// This file was automatically generated. Modifications are permitted but:
//
// - Always update the modification history below
// - Preserve original generation metadata
// - Consider if changes should be made to the source specification instead
// - Document breaking changes clearly
//
// Generated by AI-assisted code generation
// Generator: [Generator Name] [Version]
// Specification: [Spec Version] ([Spec Date])
// Generation ID: [Unique ID for tracking]
//
// === MODIFICATION HISTORY ===
// [Date] - [Modifier] - [Change Type] - [Description]
// - 2024-01-15 - Richard Naszcyniec - Initial Generation - AI-generated from spec v1.0
// - 2024-02-01 - Developer Name - Bug Fix - Fixed async/await issue
// - 2024-02-15 - Developer Name - Enhancement - Added custom validation
//
// Last Modified: [Date]
// Modified By: [Name/Role]
// Modification Count: [Number]
//
//===----------------------------------------------------------------------===//
```

**Header Comment Requirements:**
- ✅ **File Reference**: Include file name and target name (standard Apple format)
- ✅ **Copyright Notice**: Include copyright with year and creator name
- ✅ **License Information**: Use SPDX license identifier or LICENSE file reference
- ✅ **AI Attribution**: Clearly credit AI-assisted generation
- ✅ **Generation Metadata**: Include generator version and specification details
- ✅ **Repository Links**: Reference GitHub repository for context
- ✅ **Consistent Formatting**: Follow Apple's comment style guidelines
- ✅ **Modification Policy**: Clear guidelines for when/how to modify generated code
- ✅ **Modification History**: Structured tracking of all changes
- ✅ **Generation ID**: Unique identifier for tracking generations

**Modification Guidelines:**

1. **When to Modify Generated Code:**
   - **Debugging**: Fix runtime issues or add logging
   - **Customization**: Add project-specific functionality
   - **Optimization**: Performance improvements for specific use cases
   - **Integration**: Adapt to specific framework or library requirements
   - **Extensions**: Add features not covered by the specification

2. **When to Regenerate Instead:**
   - **Specification Changes**: Update spec and regenerate
   - **Bug Fixes in Generator**: Fix issues at the source
   - **Major Feature Additions**: Consider if it belongs in spec
   - **API Changes**: Regenerate to maintain consistency

3. **Modification Best Practices:**
   - **Preserve Structure**: Keep generated structure intact when possible
   - **Document Changes**: Add clear comments explaining modifications
   - **Test Thoroughly**: Ensure modifications don't break existing functionality
   - **Consider Impact**: Evaluate if changes should be upstreamed to specification
   - **Version Control**: Use clear commit messages for generated file modifications

**License Compliance Options:**
1. **SPDX Identifier**: `// SPDX-License-Identifier: MIT`
2. **Copyright + License File**: Traditional copyright notice + LICENSE reference
3. **Hybrid Approach**: SPDX + repository links for transparency

**Modification History Format:**
```swift
// Standard format for tracking changes:
[Date] - [Modifier] - [Change Type] - [Description]
// Examples:
// 2024-01-15 - Richard Naszcyniec - Initial Generation - AI-generated from spec v1.0
// 2024-02-01 - John Doe - Bug Fix - Fixed async/await deadlock
// 2024-02-15 - Jane Smith - Enhancement - Added custom validation logic
// 2024-03-01 - Dev Team - Performance - Optimized memory usage
```

**Modern Swift Community Alignment:**
- ✅ Follows Apple's standard header format
- ✅ Includes SPDX license identifiers (modern practice)
- ✅ Provides repository context for generated code
- ✅ Clear attribution for AI assistance
- ✅ Comprehensive generation metadata
- ✅ Copyright compliance for legal protection
- ✅ **NEW**: Modification tracking for maintainability
- ✅ **NEW**: Clear policies for when/how to modify generated code

* **Swift 6.2+ Language Features**:
  - Use macros for compile-time code generation and validation
  - Leverage improved type inference and variadic generics
  - Implement noncopyable types for resource management
  - Use region-based isolation for actor communication
  - Apply ownership and borrowing for performance optimization
  - Enable C++ interoperability when needed
  - Utilize enhanced concurrency diagnostics and performance improvements
  - Leverage improved macro system with better error messages
  - Take advantage of refined Sendable checking for better actor safety
  - Use enhanced type system features for more expressive DSLs

* **Package Configuration**:
  ```swift
  // Package.swift with modern Swift 6.2+ features
  let package = Package(
      name: "MyLibrary",
      platforms: [
          .macOS(.v12),
          .iOS(.v15)
      ],
      products: [...],
      targets: [
          .target(
              name: "MyLibrary",
              swiftSettings: [
                  .enableExperimentalFeature("StrictConcurrency"),
                  .enableExperimentalFeature("Macros"),
                  .unsafeFlags(["-Xfrontend", "-warn-concurrency"]),
                  .enableUpcomingFeature("ConciseMagicFile"),
                  .enableUpcomingFeature("ForwardTrailingClosures"),
                  // Swift 6.2+ specific settings
                  .enableUpcomingFeature("ExistentialAny"),
                  .enableUpcomingFeature("ImplicitOpenExistentials")
              ]
          )
      ]
  )
  ```

* **Documentation Standards**: Use comprehensive triple-slash (///) comments with modern DocC features including:
  - @MainActor and concurrency annotations
  - @available for platform/version requirements
  - @preconcurrency for backward compatibility
  - Performance characteristics documentation
  - Migration guides and deprecation notices

* **Code Quality**:
  - Use SwiftLint for consistent code style
  - Implement SwiftFormat for automated formatting
  - Add static analysis with SonarQube or similar tools
  - Use swift-health-check for runtime diagnostics

* **Security**: Avoid hard-coded secrets; use keychain or environment variables for sensitive data. Sanitize inputs to prevent injection (e.g., in URLs).

* **Internationalization**: Use NSLocalizedString for strings in LocalizedError; load from bundles for multi-language support.

## DocC Documentation

Documentation must be generated using DocC. Create a DocC catalog in the target source directory (e.g., Sources/TargetName/TargetName.docc/). The catalog must include markdown articles and resources. Prioritize public APIs; generate full catalog for complex modules.

### DocC Catalog Structure
```
TargetName/                           ← Package root
├── Package.swift
├── Sources/
│   └── TargetName/                   ← Target source directory
│       ├── TargetName.docc/         ← DocC catalog here (within target)
│       │   ├── TargetName.md        ← Main documentation file (target-named, includes introduction)
│       │   ├── Architecture.md           ← Article (standard Markdown format)
│       │   ├── Usage.md                  ← Article (standard Markdown format)
│       │   └── Resources/                ← Images, diagrams, assets
│       ├── MainFile.swift                    ← Source files
│       └── ...                           ← Other source files
├── Tests/
└── Examples/
```

**Required Documentation Articles**:
- **TargetName.md**: Main target documentation with introduction, key benefits, getting started, "Learn More About" section (after intro, before Topics), Topics section for APIs, See Also section.
- **Architecture.md**: Detailed technical explanations using standard Markdown.
- **Usage.md**: Practical examples and code snippets for all experience levels using standard Markdown.

**Generation Command**: Document generation with swift package generate-documentation --target TargetName.

## Testing Guidance

* **Modern Swift Testing Patterns**:
  - Use @Test for test functions with modern async/await support
  - Leverage @Suite for organizing related tests
  - Implement parameterized tests with @Test(arguments:)
  - Use #expect and #require for assertions and preconditions
  - Apply traits like .bug, .enabled, .tags for test organization
  - Implement @MainActor tests for UI-related code
  - Use Clock.testing for time-dependent test logic

* **Advanced Testing Features**:
  ```swift
  @Suite("Network Client Tests", .serialized)
  struct NetworkClientTests {
      @Test("Successful request", arguments: [
          TestData.validRequest,
          TestData.validResponse
      ])
      func testSuccessfulRequest(request: Request, expected: Response) async throws {
          let client = try makeTestClient()
          let response = try await client.send(request)
          #expect(response == expected)
      }

      @Test("Error handling", .tags(.errorHandling))
      func testErrorHandling() async throws {
          let client = try makeTestClient()
          #expect(throws: NetworkError.self) {
              try await client.send(invalidRequest)
          }
      }
  }
  ```

* **Test Infrastructure**:
  - Use dependency injection for testable code
  - Implement protocol-based mocking for external dependencies
  - Create test utilities for common setup/teardown patterns
  - Use TestClock for time-dependent logic testing
  - Implement test data factories for complex test scenarios

* **Concurrency Testing**:
  - Test actor isolation and cross-actor communication
  - Verify Sendable conformance with runtime checks
  - Test async sequence handling and cancellation
  - Validate deadlock prevention in concurrent operations

* **Cross-Platform Testing**:
  - Test Linux compatibility with CI pipelines
  - Verify platform-specific behavior with conditional compilation
  - Test different Swift versions for compatibility
  - Validate performance characteristics across platforms

## Performance Optimization

* **Swift 6.2+ Performance Features**:
  - **Compile-time Performance**: Use consteval for build-time computation
  - **Memory Layout Optimization**: Leverage fixed-size arrays and inline storage
  - **ARC Optimization**: Use consuming parameters and borrowing for zero-cost abstractions
  - **Generic Specialization**: Enable generic specialization for better code generation
  - **Dead Code Elimination**: Structure code to enable better DCE by the compiler

* **Modern Benchmarking**:
  ```swift
  import Benchmark

  let benchmarks = {
      Benchmark("Network Request") { benchmark in
          for _ in benchmark.scaledIterations {
              let client = makeClient()
              await benchmark.measure {
                  _ = try await client.send(request)
              }
          }
      }
  }
  ```

* **Performance Monitoring**:
  - Use signposts for Instruments integration
  - Implement performance counters with Swift metrics
  - Add memory profiling with leaks detection
  - Monitor actor queue depths and scheduling

## Cross-Platform Compatibility

* **Swift 6.2+ Platform Features**:
  - **Darwin Platforms**: Leverage Grand Central Dispatch optimizations
  - **Linux**: Use epoll-based event loops for networking
  - **Windows**: Support Windows-specific concurrency patterns
  - **WebAssembly**: Enable WebAssembly compilation for browser deployment

* **Conditional Compilation**:
  ```swift
  #if os(macOS)
  // macOS-specific optimizations
  #elseif os(Linux)
  // Linux-specific implementations
  #elseif os(Windows)
  // Windows-specific code
  #endif
  ```

## Integration with Functional Specification

Map functional requirements to this spec: e.g., identify protocols for extensible features first, then actors for concurrent parts. Prioritize must-haves (type safety, Sendable, validation) over nice-to-haves (benchmarks, full DocC). Validate generated code by simulating builds (e.g., check for strict concurrency warnings mentally) and ensuring Linux compatibility.

**Code Generation Validation**: When generating code from this specification, ensure:
- All generated files include the standard header comment format
- AI assistance is properly credited in file headers
- License references are accurate and current
- Generation metadata includes timestamps and specification versions
- File naming conventions are consistent with the target structure

## Long-Term Maintenance

* **Version Management**:
  - Use semantic versioning in Package.swift (e.g., major for breaking changes)
  - Implement automated version bumping with conventional commits
  - Maintain version compatibility matrices

* **Deprecation Strategy**:
  ```swift
  @available(*, deprecated, message: "Use async version instead", renamed: "processAsync")
  func process() throws -> Result

  @available(macOS 13.0, iOS 16.0, *, message: "Requires newer OS version")
  func newFeature() async throws
  ```

* **Migration Support**:
  - Provide migration guides for major version changes
  - Implement compatibility layers for gradual migration
  - Use feature flags for experimental features
