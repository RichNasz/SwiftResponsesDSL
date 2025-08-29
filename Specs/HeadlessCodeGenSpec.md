# Swift Headless Code Generation Specification

This specification outlines patterns and requirements for generating high-quality Swift code for headless applications in Swift 6.1+. It emphasizes type-safe APIs, concurrency with async/await and actors, JSON serialization via Codable, and extensibility. The guidelines are general-purpose, applicable to various domains (e.g., API clients, configuration, data processing). Use only Foundation; no external dependencies except for optional performance benchmarks (detailed below). Minimum platforms: macOS 12.0, iOS 15.0, and Swift 6.0+ toolchain on Linux (e.g., Ubuntu 22.04+ for server-side compatibility).

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

## Concurrency Requirements

* **Asynchronous Operations**: Use async/await for I/O-bound tasks (e.g., networking). Mark methods as async throws where appropriate, leveraging async inference for trailing closures.

* **Thread Safety**: Employ actors to manage shared state (e.g., clients with sessions). Use nonisolated for methods that don't access isolated state, improving usability. Explicitly document isolated vs. nonisolated: e.g., mark actor methods as isolated if they mutate state, nonisolated for pure computations. For types with mutable state intended for concurrent access, wrap mutable state in an actor or use @MainActor if UI-bound.

* **Sendable Conformance**: Ensure all types crossing concurrency domains conform to Sendable (Swift 6 strict concurrency). Explicitly avoid capturing non-Sendable types in closures; simulate compiler diagnostics by checking for common pitfalls like capturing mutable vars. For custom types, mark properties as @unchecked Sendable if necessary (e.g., for legacy interop), with justification in doc comments (e.g., "/// @unchecked Sendable: Type is thread-safe via internal locking."). All error types and enums with associated values must explicitly conform to Sendable and Equatable. Use String or custom Equatable types in associated values (e.g., case taskFailed(String) or case customError(MyEquatableError)).

* **Streaming**: Support streaming responses with AsyncStream for incremental processing, handling errors via continuation.finish(throwing:). Include notes on buffering (e.g., use AsyncBufferedByteIterator for large streams), backpressure (via await on next()), combining increments (e.g., a reduce function to merge partial data into a full response), and cancellation (e.g., check Task.isCancelled in loops).

* **Networking**: Use URLSession for HTTP requests, with configurable sessions. Handle authentication, headers, and errors asynchronously. Support timeouts and retries via URLSessionConfiguration. Explicitly support GET/POST; for advanced needs like multipart, use Data and URLRequest; exclude WebSockets unless specified in functional spec.

* **Swift 6 Concurrency Considerations**:
  - Resolve naming conflicts, e.g., use typealias ConcurrencyTask = _Concurrency.Task if defining a custom Task protocol.
  - In actor isolation, avoid capturing self directly in closures to prevent data races; use [self] capture lists or static methods.
  - For generic parameter inference, Swift 6 requires explicit generic parameters in many contexts; all code examples should include explicit generics (e.g., Edge<NodeType, EventType>.simple(...)).
  - Use async let for independent tasks; minimize unnecessary await to reduce actor hopping.
  - Prefer structured concurrency (e.g., TaskGroup) exclusively; no Dispatch.

  | Rule | Example | Rationale |
  |------|---------|-----------|
  | Use async let | async let result1 = task1(); async let result2 = task2(); let combined = await (result1, result2) | Run independent tasks concurrently to minimize suspension points |
  | Explicit generics | func process<T: Sendable>(item: T) async | Swift 6 limits inference in async contexts |
  | Avoid self capture | actor MyActor { func run() { Task { [weak self] in await self?.mutate() } } } | Prevent data races in closures |
  | TaskGroup for parallelism | try await withThrowingTaskGroup(of: Result.self) { group in ... } | Structured over unstructured Tasks |

## Enums

* ```swift
  enum CustomError: Error, LocalizedError, Equatable, Sendable { 
    case invalidURL, encodingFailed(String), networkError(String), decodingFailed(String), serverError(statusCode: Int, message: String?), rateLimit, invalidResponse, invalidValue(String), missingRequiredField 

    var errorDescription: String? { 
      switch self { 
        /* Provide descriptive strings, e.g., case .invalidValue(let msg): return "Invalid value: \(msg)" */ 
      } 
    } 
  }
  ```
  * Example: Handles domain-specific errors with descriptive strings for equatability and localization. For complex associated values, ensure they conform to Equatable (e.g., via custom structs).

## Protocols

* ```swift
  public protocol LoggerProtocol: Sendable { 
    func log(level: LogLevel, message: String) 
  }
  ```
  * Example: For customizable logging. Default implementation uses os_log on Apple platforms or console on Linux. Injectable for testing/server customization.

* ```swift
  public enum LogLevel: String, Sendable, CaseIterable { case debug = "DEBUG", info = "INFO", warning = "WARNING", error = "ERROR" } 
  ```

## Implementation Details

* Mark public APIs as public; internals private.

* Use Swift 6.1+ features: trailing commas, nonisolated, async inference.

* Package.swift: Define target with min platforms. Set swift-tools-version: 6.0 to enable Swift 6 features and concurrency checks. Enable strict concurrency with compiler flags: .unsafeFlags(["-strict-concurrency=complete"], .when(configuration: .debug)).

* Add doc comments to public APIs, including usage examples and preconditions. Follow Apple's standards: Use triple-slash (///) comments structured with Markdown sections (e.g., Summary, Discussion, Parameters, Returns, Throws).

* Avoid force-unwraps; use optionals and guards.

* Add inline comments and docstrings for clarity.

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

* Include unit test patterns using Swift Testing: e.g., @Test for initializers with #expect(try config() doesn't throw) for valid configs, #expect(throws: CustomError.self) { try invalidConfig() } for invalids; async tests using #expect(await try perform(request) == expected); mock URLSession for networking via a testable URLSessionConfiguration; property-based testing for validations by generating test data manually (e.g., via parameterized @Test functions with ranges), as Swift Testing supports traits like .bug for known issues and .enabled(if:) for conditional tests.

* All test types must have explicit generic parameters for Swift 6 compatibility.

* Error testing requires Equatable conformance on error types.

* Cover error handling, async scenarios, and platform-specific tests (e.g., Linux for server validation).

* If generating tests, mock contexts and tasks for isolation.

## Integration with Functional Specification

Map functional requirements to this spec: e.g., identify protocols for extensible features first, then actors for concurrent parts. Prioritize must-haves (type safety, Sendable, validation) over nice-to-haves (benchmarks, full DocC). Validate generated code by simulating builds (e.g., check for strict concurrency warnings mentally) and ensuring Linux compatibility.

## Long-Term Maintenance

* Use semantic versioning in Package.swift (e.g., major for breaking changes). Include CHANGELOG.md with migration guides for major/minor releases.

* Mark experimental features as @available(Swift 6.0, message: 'Beta: Feature may change'). Use semantic versioning for breaking changes; deprecate with @available(deprecated, message: "...").
