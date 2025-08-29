# Swift Language Specification for DSLs

This specification outlines patterns and requirements for building embedded domain-specific languages (DSLs) in Swift 6.2+. It emphasizes declarative, type-safe APIs using result builders, concurrency with async/await and actors, JSON serialization via Codable, and extensibility. The guidelines are general-purpose, applicable to various domains (e.g., API requests, configuration, data processing). Specific examples draw from a chat completions context but can be adapted. Use only Foundation; no external dependencies. Minimum platforms: macOS 12.0, iOS 15.0.

## DSL Fundamentals

### What is a DSL?
A Domain-Specific Language (DSL) is a specialized programming language designed for a specific application domain. In Swift, embedded DSLs leverage the language's type system, generics, and result builders to create expressive, type-safe APIs that feel like natural language for specific domains.

### DSL Design Principles
- **Expressiveness**: DSL should read like natural language for the domain
- **Type Safety**: Compile-time guarantees prevent runtime errors
- **Composability**: Easy to combine DSL elements for complex operations
- **Extensibility**: Easy to add new features without breaking existing code
- **Performance**: Minimal runtime overhead through compile-time optimizations

## General DSL Requirements

* **Declarative Syntax**: Leverage result builders (@resultBuilder) to enable concise, readable code blocks that support control flow (e.g., if, for, switch). Builders compose arrays of elements (e.g., parameters, messages) from expressions, optionals, and arrays. Ensure builders handle partial failures by rethrowing errors from component initializers.

* **Type Safety**: Use protocols to define extensible interfaces (e.g., for parameters or data elements). Enums for fixed options (e.g., roles, states). Structs for value types to ensure immutability and performance. Avoid classes unless necessary for reference semantics.

* **Configuration and Initialization**: Provide builders for optional parameters, applying them via protocols to mutable structs. Support multiple initializers: one with builders for declarative setup (with throws for validation), another with direct arrays for pre-built data. In builder-based inits, rethrow errors from the builder closures to propagate validation failures.

* **Validation**: Throw custom errors during initialization for invalid values (e.g., range checks, required fields). Use a descriptive error enum conforming to LocalizedError for user-friendly descriptions. For parameters, define standard validation ranges where applicable (e.g., Temperature: 0.0...2.0, MaxLimit: 1...Int.max), and chain validations by applying parameters in sequence, throwing on first failure.

* **Extensibility**: Allow custom conformances to protocols (e.g., new parameter types or data elements). Support future additions like multimodal content via flexible encoding. Provide diverse examples: e.g., for data processing domains, extend DataElement for structured queries; for configurations, add custom ConfigParameters for logging levels or timeouts.

* **JSON Compatibility**: Align with common formats using Codable. Use CodingKeys for key mapping (e.g., snake_case). Handle existential types (e.g., any Protocol) with custom encoding: implement a type-erased wrapper (e.g., AnyEncodable) for heterogeneous arrays, using a switch on concrete types in encode(to:) or decode(from:). For arrays like [any DataElement], use a nestedUnkeyedContainer and encode each element's properties manually to avoid type erasure issues.

* **Performance**: Favor value types (structs/enums) and compile-time features (result builders, @inlinable) to minimize runtime overhead. Use async inference where possible to reduce boilerplate in async methods.

## DSL Implementation Architecture

### Modular Organization for DSLs

* **Modular File Structure**: Implement DSLs using a modular architecture rather than monolithic files. This improves maintainability, testing, and developer experience by separating concerns logically.

* **Recommended Module Structure**:
  - **Core Module**: Fundamental types, protocols, and base utilities
  - **Domain Modules**: DSL-specific types (e.g., message types, configuration parameters)
  - **Builder Modules**: Result builders and DSL syntax components
  - **Client/Infrastructure Modules**: Networking, execution, and external integrations
  - **Utility Modules**: Helper functions, convenience methods, and extensions
  - **Main Module**: Entry point with comprehensive documentation

* **Module Naming Conventions**:
  - Use descriptive, domain-specific names (e.g., `Messages.swift`, `Configuration.swift`)
  - Follow Swift naming conventions (PascalCase for files)
  - Group related functionality together
  - Keep files focused on single responsibilities

* **Cross-Module Dependencies**:
  - Define protocols in core modules, implementations in domain modules
  - Use dependency injection for external services
  - Minimize coupling between modules
  - Document module interfaces clearly

* **DSL-Specific Testing**:
  - Test each module independently
  - Include builder pattern tests
  - Validate DSL syntax and error handling
  - Test cross-module integrations
  - Use DSL examples as documentation tests

* **Documentation Strategy**:
  - Include DSL usage examples in main module
  - Document each module's responsibility
  - Provide migration guides for DSL evolution
  - Include performance characteristics

### DSL Evolution and Maintenance

* **Versioning Strategy**: Use semantic versioning for DSL APIs. Increment major version for breaking changes, minor for new features, patch for bug fixes.

* **Migration Support**: Provide migration guides and compatibility layers when evolving DSL syntax or structure.

* **Extensibility Guidelines**: Design DSL components to be easily extensible without breaking existing code.

* **Performance Monitoring**: Include performance benchmarks for DSL operations and provide optimization guidelines.

## Macro Opportunities for Boilerplate Reduction

### Parameter Configuration Macros

**@ParameterConfig Macro** - Automatically generates parameter structs with validation:

```swift
// Instead of manually writing:
struct Temperature: ResponseConfigParameter {
    let value: Double
    init(_ value: Double) throws {
        guard (0.0...2.0).contains(value) else {
            throw LLMError.invalidValue("Temperature must be between 0.0 and 2.0")
        }
        self.value = value
    }
    func apply(to request: inout ResponseRequest) throws {
        request.temperature = value
    }
}

// Developer writes:
@ParameterConfig(name: "Temperature", type: Double.self, range: 0.0...2.0, property: "temperature")
struct Temperature {}
```

**Benefits:**
- Reduces ~15 lines of boilerplate to 1 line
- Automatic validation generation
- Consistent error messages
- Type-safe property assignment

### Result Builder Generation Macros

**@DSLBuilder Macro** - Generates complete result builders with all required methods:

```swift
// Instead of manually implementing:
@resultBuilder
struct RequestConfigBuilder {
    static func buildBlock(_ components: (any RequestParameter)...) -> [any RequestParameter] {
        Array(components)
    }
    static func buildOptional(_ component: [any RequestParameter]?) -> [any RequestParameter] {
        component ?? []
    }
    // ... 8+ more methods
}

// Developer writes:
@DSLBuilder(for: RequestParameter.self)
struct RequestConfigBuilder {}
```

**Benefits:**
- Eliminates ~50 lines of repetitive builder code
- Guarantees all required methods are implemented
- Consistent error handling across builders
- Automatic array handling

### Message Type Generation Macros

**@MessageType Macro** - Generates message types with standard conformances:

```swift
// Instead of manually writing:
struct SystemMessage: ResponseMessage {
    let role: Role = .system
    let content: [ContentPart]

    init(text: String) {
        self.content = [.text(text)]
    }

    init(content: [ContentPart]) {
        self.content = content
    }
}

// Developer writes:
@MessageType(role: .system, name: "SystemMessage")
struct SystemMessage {}
```

**Benefits:**
- Standardizes message type implementation
- Automatic ContentPart handling
- Consistent initialization patterns
- Type-safe content management

### Protocol Conformance Macros

**@DSLConformance Macro** - Automatically adds DSL-related protocol conformances:

```swift
// Instead of manual conformances:
extension CustomParameter: RequestParameter {
    func apply(to request: inout Request) throws {
        // Custom logic
    }
}

// Developer writes:
@DSLConformance(RequestParameter.self, applyLogic: "request.customProperty = value")
struct CustomParameter {
    let value: String
}
```

**Benefits:**
- Automatic protocol implementation
- Customizable application logic
- Reduced boilerplate for extensions
- Consistent conformance patterns

### Error Handling Macros

**@DSLError Macro** - Generates error enums with proper conformances and descriptions:

```swift
// Instead of manual error enum:
enum ValidationError: Error, LocalizedError, Equatable {
    case invalidRange(String, Double, ClosedRange<Double>)
    case missingRequired(String)

    var errorDescription: String? {
        switch self {
        case .invalidRange(let param, let value, let range):
            return "\(param) value \(value) is outside valid range \(range)"
        case .missingRequired(let param):
            return "\(param) is required but not provided"
        }
    }
}

// Developer writes:
@DSLError
enum ValidationError {
    case invalidRange(String, Double, ClosedRange<Double>)
    case missingRequired(String)
}
```

**Benefits:**
- Automatic LocalizedError conformance
- Consistent error message formatting
- Equatable conformance for testing
- Standardized error handling patterns

### Validation Logic Macros

**@ValidateProperty Macro** - Adds compile-time validation to properties:

```swift
struct RequestConfig {
    @ValidateProperty(range: 0.0...2.0, errorMessage: "Temperature must be between 0.0 and 2.0")
    var temperature: Double?

    @ValidateProperty(minValue: 1, maxValue: 4000)
    var maxTokens: Int?

    @ValidateProperty(allowedValues: ["none", "auto", "required"])
    var toolChoice: String?
}
```

**Benefits:**
- Compile-time validation guarantees
- Automatic error generation
- Consistent validation patterns
- Reduced runtime validation code

### Builder Pattern Macros

**@BuilderPattern Macro** - Implements common builder patterns:

```swift
@BuilderPattern
struct RequestBuilder<State> {
    // Macro generates:
    // - State tracking types
    // - Builder methods
    // - Validation logic
    // - Build() method with state checking
}

let request = RequestBuilder<Empty>()
    .withModel("gpt-4")        // Returns RequestBuilder<ModelSet>
    .withMessages([...])       // Returns RequestBuilder<MessagesSet>
    .build()                   // Compile-time validation
```

**Benefits:**
- Type-safe builder pattern implementation
- Compile-time state validation
- Automatic method generation
- Consistent builder patterns

### Implementation Strategy

**Macro Package Structure:**
```
Sources/
├── SwiftResponsesMacros/
│   ├── ParameterConfigMacro.swift
│   ├── DSLBuilderMacro.swift
│   ├── MessageTypeMacro.swift
│   ├── DSLConformanceMacro.swift
│   ├── DSLErrorMacro.swift
│   ├── ValidatePropertyMacro.swift
│   └── BuilderPatternMacro.swift
└── SwiftResponsesDSL/
    ├── Macros.swift (exports all macros)
    └── ... (main DSL implementation)
```

**Usage in Package.swift:**
```swift
let package = Package(
    name: "SwiftResponsesDSL",
    products: [
        .library(name: "SwiftResponsesDSL", targets: ["SwiftResponsesDSL"]),
        .library(name: "SwiftResponsesMacros", targets: ["SwiftResponsesMacros"])
    ],
    targets: [
        .macro(name: "SwiftResponsesMacros"),
        .target(name: "SwiftResponsesDSL", dependencies: ["SwiftResponsesMacros"])
    ]
)
```

**Developer Usage:**
```swift
// In user's Package.swift
dependencies: [
    .package(url: "https://github.com/RichNasz/SwiftResponsesDSL", from: "1.0.0")
]

// In user's code
import SwiftResponsesMacros
import SwiftResponsesDSL

@ParameterConfig(name: "Temperature", type: Double.self, range: 0.0...2.0, property: "temperature")
struct Temperature {}

@DSLBuilder(for: RequestParameter.self)
struct RequestConfigBuilder {}
```

## DSL Design Patterns

### Builder Pattern with Result Builders
```swift
// Modern DSL using result builders
let request = try Request(model: "gpt-4") {
    Temperature(0.7)
    MaxTokens(1000)
} messages: {
    system("You are a helpful assistant")
    user("Explain quantum computing")
    if includeContext {
        user("Additional context here")
    }
}
```

### Protocol-Oriented Configuration
```swift
// Protocol-based configuration system
protocol RequestParameter {
    func apply(to request: inout Request) throws
}

struct Temperature: RequestParameter {
    let value: Double
    init(_ value: Double) throws {
        // Validation logic
    }
    func apply(to request: inout Request) throws {
        request.temperature = value
    }
}
```

### Fluent Interface Pattern
```swift
// Method chaining for fluent APIs
let client = LLMClient(baseURL: url)
    .withTimeout(30)
    .withRetryPolicy(.exponentialBackoff)
    .withAuth(apiKey: key)
```

### Type-Safe Builders with Phantom Types
```swift
// Phantom types for compile-time state tracking
struct RequestBuilder<State> {
    // Implementation ensuring valid state transitions
}

let request = RequestBuilder<Empty>()
    .withModel("gpt-4")        // Returns RequestBuilder<ModelSet>
    .withMessages([...])       // Returns RequestBuilder<MessagesSet>
    .build()                   // Only available when all required fields set
```

## DSL Anti-Patterns to Avoid

### ❌ Over-Abstraction
```swift
// AVOID: Too abstract, loses domain meaning
let config = Builder()
    .add("temperature", 0.7)
    .add("max_tokens", 1000)

// PREFER: Domain-specific, type-safe
let config = RequestConfig {
    Temperature(0.7)
    MaxTokens(1000)
}
```

### ❌ String-Based Configuration
```swift
// AVOID: Runtime errors, no autocomplete
client.configure("temperature", value: 0.7)
client.configure("model", value: "gpt-4")

// PREFER: Type-safe, compile-time checked
client.configure {
    Temperature(0.7)
    Model(.gpt4)
}
```

### ❌ Mixing Concerns
```swift
// AVOID: Builder handles too many responsibilities
let request = RequestBuilder()
    .setModel("gpt-4")
    .setTemperature(0.7)
    .setNetworkingTimeout(30)    // Networking concern
    .setCachePolicy(.reload)     // Caching concern
    .setLoggingLevel(.debug)     // Logging concern

// PREFER: Focused, single-responsibility builders
let request = RequestBuilder {
    Model(.gpt4)
    Temperature(0.7)
}
let network = NetworkConfig {
    Timeout(30)
    CachePolicy(.reload)
}
```

### ❌ Ignoring Swift's Type System
```swift
// AVOID: Any loses type safety
let parameters: [Any] = [0.7, 1000, "gpt-4"]

// PREFER: Generic, type-safe containers
let parameters: [any RequestParameter] = [
    Temperature(0.7),
    MaxTokens(1000),
    Model(.gpt4)
]
```

## Concurrency Requirements

* **Asynchronous Operations**: Use async/await for I/O-bound tasks (e.g., networking). Mark methods as async throws where appropriate, leveraging async inference for trailing closures.

* **Thread Safety**: Employ actors to manage shared state (e.g., clients with sessions). Use nonisolated for methods that don't access isolated state, improving usability. Explicitly document isolated vs. nonisolated: e.g., mark actor methods as isolated if they mutate state, nonisolated for pure computations. For types like SessionManager, if intended for concurrent access, wrap mutable state (e.g., history) in an actor or use @MainActor if UI-bound.

* **Sendable Conformance**: Ensure all types crossing concurrency domains conform to Sendable (Swift 6 strict concurrency). Explicitly avoid capturing non-Sendable types in closures; use compiler diagnostics (e.g., warnings in Swift 6) as a guide during generation. For custom types, mark properties as @unchecked Sendable if necessary, with justification in doc comments.

* **Streaming**: Support streaming responses with AsyncStream for incremental processing, handling errors via continuation.finish(throwing:). Include notes on buffering (e.g., use AsyncBufferedByteIterator for large streams), backpressure (via await on next()), and combining deltas (e.g., a reduce function to merge Delta into a full Response).

* **Networking**: Use URLSession for HTTP requests, with configurable sessions. Handle authentication, headers, and errors asynchronously. Support timeouts and retries via URLSessionConfiguration.

## Enums

* ```swift
  enum Role: String, Codable { case system, user, assistant, tool }
  ```
  * Example: Represents categories in a domain; encodes as strings.

* ```swift
  enum LLMError: Error, LocalizedError, Equatable {
    case invalidURL, encodingFailed(String), networkError(String), decodingFailed(String), serverError(statusCode: Int, message: String?), rateLimit, invalidResponse, invalidValue(String), missingRequiredField
    case authenticationFailed, timeout, sslError(String), httpError(statusCode: Int, message: String?)
    case jsonParsingError(String), invalidParameter(String, String)

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
        case .authenticationFailed: return "Authentication failed"
        case .timeout: return "Request timed out"
        case .sslError(let msg): return "SSL/TLS error: \(msg)"
        case .httpError(let code, let msg): return "HTTP error (\(code)): \(msg ?? "Unknown error")"
        case .jsonParsingError(let msg): return "JSON parsing error: \(msg)"
        case .invalidParameter(let param, let reason): return "Invalid parameter '\(param)': \(reason)"
      }
    }
  }
  ```
  * Example: Comprehensive error handling with localized descriptions, consistent with LLMError from the main specification.

## Protocols

* ```swift
  protocol DataElement: Encodable, Sendable { 
    var category: Role { get }; 
    var payload: any Encodable { get } 
  }
  ```
  * Example: Defines extensible elements (e.g., messages); encodes to { "role": String, "content": Any }. For custom encoding, conformers should implement encode(to:) by encoding category and wrapping payload in AnyEncodable.

* ```swift
  protocol ConfigParameter: Sendable { 
    func apply(to request: inout Request) throws 
  }
  ```
  * Example: Allows parameters to modify a request struct; throw on apply if post-validation fails (e.g., conflicting params).

## Structs

* ```swift
  struct BasicElement: DataElement { 
    let category: Role; 
    let payload: String 

    enum CodingKeys: String, CodingKey { 
      case category = "role", payload = "content" 
    } 

    func encode(to encoder: Encoder) throws { 
      var container = encoder.container(keyedBy: CodingKeys.self); 
      try container.encode(category, forKey: .category); 
      try container.encode(payload, forKey: .payload) 
    } 
  }
  ```
  * Example: Simple implementation; encodes with CodingKeys.

* Parameter structs (each conforms to ConfigParameter):

  * ```swift
    struct Temperature: ConfigParameter { 
      let value: Double; 
      init(_ value: Double) throws {
        guard (0.0...2.0).contains(value) else {
          throw LLMError.invalidValue("Temperature must be between 0.0 and 2.0")
        };
        self.value = value
      } 
      func apply(to request: inout Request) throws { 
        request.temperature = value 
      } 
    }
    ```

  * ```swift
    struct MaxLimit: ConfigParameter { 
      let value: Int; 
      init(_ value: Int) throws {
        guard value > 0 else {
          throw LLMError.invalidValue("MaxLimit must be positive")
        };
        self.value = value
      } 
      func apply(to request: inout Request) throws { 
        request.maxLimit = value 
      } 
    }
    ```

  * Similar for other parameters (e.g., TopP: 0.0...1.0, FrequencyPenalty: -2.0...2.0), with domain-appropriate names, validations, and throws in apply for chained checks (e.g., ensure temperature and topP don't conflict if domain-specific).

* ```swift
  struct Request: Encodable, Sendable { 
    let identifier: String; 
    let elements: [any DataElement]; 
    var temperature: Double?; 
    var maxLimit: Int?; 
    // Additional optional fields...

    init( identifier: String, streaming: Bool = false, @ConfigBuilder config: () throws -> [any ConfigParameter] = { [] }, @ElementBuilder elements: () -> [any DataElement] ) throws { 
      self.identifier = identifier; 
      self.elements = elements(); 
      var mutableSelf = self; 
      let params = try config(); 
      for param in params { 
        try param.apply(to: &mutableSelf) 
      }; 
      self = mutableSelf 
    } // Apply params after elements, rethrowing errors.

    init( identifier: String, streaming: Bool = false, @ConfigBuilder config: () throws -> [any ConfigParameter] = { [] }, elements: [any DataElement] ) throws { 
      /* Similar, with direct elements */ 
    }

    func encode(to encoder: Encoder) throws { 
      var container = encoder.container(keyedBy: CodingKeys.self); 
      try container.encode(identifier, forKey: .identifier); 
      var elementsContainer = container.nestedUnkeyedContainer(forKey: .elements); 
      for element in elements { 
        try elementsContainer.encode(element) 
      } 
      /* Additional fields */ 
    } 
  }
  ```
  * Example: Core request object; encodes with custom keys using CodingKeys; uses nestedUnkeyedContainer for arrays. For existentials, rely on protocol's custom encode.

* ```swift
  struct SessionManager: Sendable { 
    private actor Storage { 
      var history: [any DataElement] = [] 
    } 
    private let storage = Storage()

    init(@ElementBuilder elements: () -> [any DataElement]) { 
      Task { 
        await storage.history = elements() 
      } 
    }

    init(history: [any DataElement] = []) { 
      Task { 
        await storage.history = history 
      } 
    }

    func add(element: any DataElement) async { 
      await storage.history.append(element) 
    }

    // Convenience add methods...

    func generateRequest( identifier: String, streaming: Bool = false, @ConfigBuilder config: () throws -> [any ConfigParameter] = { [] }, @ElementBuilder additional: () -> [any DataElement] = { [] } ) async throws -> Request { 
      let allElements = await storage.history + additional(); 
      return try Request(identifier: identifier, streaming: streaming, config: config, elements: allElements) 
    } 
  }
  ```
  * Example: Manages stateful sequences (e.g., conversations); uses internal actor for thread-safe mutable state.

* Response structs (Decodable, Sendable):

  * ```swift
    struct Response: Decodable, Sendable { 
      let id: String; 
      let choices: [Choice]; 
      struct Choice: Decodable, Sendable { 
        let delta: Delta; 
        /* etc. */ 
      } 
      /* fields like id, choices... */ 
    }
    ```

  * ```swift
    struct Delta: Decodable, Sendable { 
      let content: String?; 
      /* for streaming increments */ 
      func merge(with previous: Delta?) -> Delta { 
        /* Logic to combine */ 
      } 
    }
    ```

## Result Builders

* ```swift
  @resultBuilder public struct ElementBuilder { 
    @inlinable static func buildBlock(_ components: any DataElement...) -> [any DataElement] 
    // Additional methods for control flow (buildIf, buildEither, buildArray)... 
  }
  ```

* ```swift
  @resultBuilder public struct ConfigBuilder { 
    @inlinable static func buildBlock(_ components: any ConfigParameter...) -> [any ConfigParameter] 
    // Additional methods... 
  }
  ```

## Actor

* ```swift
  public actor Client { 
    public init(endpoint: String, credential: String, sessionConfig: URLSessionConfiguration = .default) throws 
    public func perform(_ request: Request) async throws -> Response 
    public nonisolated func stream(_ request: Request) -> AsyncStream<Delta> { 
      AsyncStream { 
        continuation in 
        Task { 
          do { 
            /* Stream logic, yield deltas, handle buffering */ 
          } catch { 
            continuation.finish(throwing: error) 
          } 
        } 
      } 
    } 
  }
  ```
  * Example: Manages operations; internal state private. Use nonisolated for stream to allow cross-actor calls without await.

## Extensibility Examples

* Custom element: 
  ```swift
  struct AdvancedElement: DataElement { 
    let category: Role = .user; 
    let payload: [AnyEncodable] /* complex structure */ 
    func encode(to encoder: Encoder) throws { 
      /* Custom logic */ 
    } 
  }
  ```

* For data processing: 
  ```swift
  struct QueryElement: DataElement { 
    let category: Role = .system; 
    let payload: SQLQuery /* Extend with domain types */ 
  }
  ```

## Implementation Details

* Mark public APIs as public; internals private.

* Use Swift 6.1+ features: trailing commas, nonisolated, async inference.

* Package.swift: Define target with min platforms.

* Add doc comments to public APIs, including usage examples and preconditions.

## DSL Evolution and Maintenance

### Versioning Strategy

* **Semantic Versioning for DSLs**:
  - **Major**: Breaking changes to DSL syntax or core concepts
  - **Minor**: New features, parameters, or improved syntax
  - **Patch**: Bug fixes, documentation improvements, performance optimizations

* **Deprecation Strategy**:
  ```swift
  @available(*, deprecated, message: "Use 'request' DSL syntax instead", renamed: "request")
  func buildRequest(...) -> Request {
      // Legacy implementation
  }
  ```

### Migration Support

* **Gradual Migration Path**:
  ```swift
  // Old syntax (deprecated but still works)
  let request = client.request(model: "gpt-4", temperature: 0.7)

  // New DSL syntax (preferred)
  let request = try client.request {
      Model(.gpt4)
      Temperature(0.7)
  }
  ```

* **Compatibility Layers**:
  ```swift
  extension LegacyClient {
      func request(model: String, temperature: Double) -> Request {
          // Bridge to new DSL
          return try! Request(model: model) {
              Temperature(temperature)
          }
      }
  }
  ```

### Extensibility Guidelines

* **Protocol Extensions**: Allow users to extend DSL with custom parameters
* **Custom Builders**: Support custom result builders for specialized use cases
* **Plugin Architecture**: Enable third-party extensions and integrations
* **Type-Safe Extensions**: Ensure extensions maintain type safety guarantees

### Documentation Evolution

* **DSL Guides**: Update DSL guides with new features and patterns
* **Migration Guides**: Provide clear migration paths for breaking changes
* **Best Practices**: Evolve best practices based on community feedback
* **Examples**: Maintain up-to-date examples showing current best practices

### Performance Monitoring

* **DSL Performance Benchmarks**: Track DSL performance over time
* **Memory Usage Patterns**: Monitor memory usage of DSL constructs
* **Compilation Time**: Track impact of DSL complexity on build times
* **Runtime Performance**: Measure DSL execution performance vs manual APIs

## Testing DSL Implementations

### Unit Testing Patterns

* **Builder Testing**:
  ```swift
  @Test("Result builder creates valid configuration")
  func testResultBuilder() throws {
      let config = try RequestConfig {
          Temperature(0.7)
          MaxTokens(1000)
      }

      #expect(config.temperature == 0.7)
      #expect(config.maxTokens == 1000)
  }

  @Test("Builder handles validation errors")
  func testBuilderValidation() {
      #expect(throws: LLMError.invalidValue) {
          try Temperature(3.0)  // Invalid range
      }
  }
  ```

* **Parameter Validation Testing**:
  ```swift
  @Test("Parameter validation", arguments: [
      (0.0, true),   // Valid minimum
      (2.0, true),   // Valid maximum
      (-0.1, false), // Invalid minimum
      (2.1, false)   // Invalid maximum
  ])
  func testTemperatureValidation(value: Double, shouldBeValid: Bool) {
      if shouldBeValid {
          #expect(throws: Never.self) {
              try Temperature(value)
          }
      } else {
          #expect(throws: LLMError.invalidValue) {
              try Temperature(value)
          }
      }
  }
  ```

### Integration Testing

* **End-to-End DSL Usage**:
  ```swift
  @Test("Complete DSL workflow")
  func testCompleteDSLWorkflow() async throws {
      let client = try makeTestClient()

      let response = try await client.send {
          Model(.gpt4)
          Temperature(0.7)
      } messages: {
          system("You are a helpful assistant")
          user("Hello, world!")
      }

      #expect(!response.content.isEmpty)
  }
  ```

* **Streaming DSL Testing**:
  ```swift
  @Test("Streaming DSL integration")
  func testStreamingDSL() async throws {
      let client = try makeTestClient()
      var receivedEvents = [StreamingEvent]()

      for try await event in client.stream {
          Model(.gpt4)
          Temperature(0.7)
      } messages: {
          user("Tell me a story")
      } {
          receivedEvents.append(event)
      }

      #expect(!receivedEvents.isEmpty)
      #expect(receivedEvents.contains { $0.isCompletion })
  }
  ```

### DSL-Specific Testing Considerations

* **Syntax Validation**: Test that DSL syntax produces expected internal representations
* **Type Safety**: Verify that invalid combinations are caught at compile time
* **Performance**: Test DSL performance against manual API usage
* **Error Propagation**: Ensure DSL errors are properly wrapped and propagated
* **Extensibility**: Test that custom extensions work seamlessly with existing DSL

### Mocking and Test Doubles

* **Protocol-Based Mocking**:
  ```swift
  class MockLLMClient: LLMClientProtocol {
      var sentRequests = [Request]()

      func send(_ request: Request) async throws -> Response {
          sentRequests.append(request)
          return MockResponse.success
      }
  }
  ```

* **Builder Testing Utilities**:
  ```swift
  extension RequestConfig {
      static func testConfig() -> RequestConfig {
          try! RequestConfig {
              Temperature(0.7)
              MaxTokens(1000)
          }
      }
  }
  ```

### Property-Based Testing

* **DSL Input Generation**:
  ```swift
  @Test("Property-based DSL testing")
  func testDSLProperties() {
      // Generate random valid DSL configurations
      let configs = (0..<100).map { _ in
          RequestConfig {
              Temperature(.random(in: 0...2))
              MaxTokens(.random(in: 1...4000))
          }
      }

      for config in configs {
          #expect(config.isValid)
          #expect(config.temperature != nil)
          #expect(config.maxTokens != nil)
      }
  }
  ```

### Performance Testing

* **DSL vs Manual API Comparison**:
  ```swift
  @Test("DSL performance benchmark")
  func testDSLPerformance() {
      measure {
          let config = RequestConfig {
              Temperature(0.7)
              MaxTokens(1000)
              // ... many parameters
          }
      }
  }
  ```

* **Memory Usage Testing**:
  ```swift
  @Test("DSL memory efficiency")
  func testDSLMemoryUsage() {
      var configs = [RequestConfig]()

      for _ in 0..<1000 {
          configs.append(RequestConfig {
              Temperature(0.7)
              MaxTokens(1000)
          })
      }

      #expect(configs.count == 1000)
      // Memory profiling assertions
  }
  ```
