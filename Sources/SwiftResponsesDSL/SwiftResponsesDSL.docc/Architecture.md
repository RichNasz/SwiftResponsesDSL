# Architecture Guide

@Metadata {
    @DisplayName("Architecture")
    @PageKind(article)
}

This document explains the technical architecture and design patterns that underpin SwiftResponsesDSL, providing insight into how the framework achieves its goals of type safety, performance, and developer experience.

## Core Architectural Principles

SwiftResponsesDSL is built on several fundamental architectural principles that guide its design and implementation.

### 1. Protocol-Oriented Programming

The framework extensively uses Swift's protocol-oriented programming to achieve:

- **Type Safety**: Compile-time guarantees through protocol constraints
- **Extensibility**: Easy addition of new features without breaking existing code
- **Composition**: Building complex behavior from simple, composable parts
- **Testability**: Protocol-based design enables easy mocking and testing

```swift
// Core protocols enable type-safe composition
public protocol ResponseMessage: Encodable, Sendable {
    var role: Role { get }
    var content: [ContentPart] { get }
}

public protocol ResponseConfigParameter: Sendable {
    func apply(to request: inout ResponseRequest) throws
}
```

### 2. Result Builder Pattern

Swift's `@resultBuilder` enables declarative syntax that compiles to efficient code:

```swift
// Declarative syntax
let request = ResponseRequest(
    model: "gpt-4",
    config: {
        Temperature(0.7)
        MaxOutputTokens(150)
    },
    input: {
        system("You are helpful")
        user("Hello")
    }
)

// Compiles to efficient imperative code
let request = ResponseRequest(
    model: "gpt-4",
    config: [Temperature(0.7), MaxOutputTokens(150)],
    input: [
        SystemMessage(text: "You are helpful"),
        UserMessage(text: "Hello")
    ]
)
```

### 3. Actor-Based Concurrency

Network operations use Swift actors for thread-safe concurrent access:

```swift
public actor LLMClient {
    private let session: URLSession
    private let baseURL: URL

    public func respond(to request: ResponseRequest) async throws -> Response {
        // Thread-safe network operations
        let (data, response) = try await session.data(for: urlRequest)
        return try await decodeResponse(data, response: response)
    }
}
```

## Component Architecture

### Core Components

```
SwiftResponsesDSL
├── Core/                    # Fundamental types and protocols
│   ├── Role                 # Message participant roles
│   ├── LLMError            # Comprehensive error handling
│   ├── ResponseMessage     # Message protocol
│   ├── ResponseConfigParameter # Configuration protocol
│   └── AnyCodable          # Type-erased JSON container
├── Messages/               # Message types and content
│   ├── ContentPart         # Multimodal content representation
│   ├── SystemMessage       # System/instruction messages
│   ├── UserMessage         # User input messages
│   └── AssistantMessage    # AI response messages
├── Configuration/          # Configuration parameters
│   ├── Temperature         # Response creativity control
│   ├── TopP               # Nucleus sampling
│   ├── MaxOutputTokens     # Response length limits
│   └── ...                 # Additional parameters
├── API/                    # Request/Response types
│   ├── ResponseRequest     # API request structure
│   ├── Response           # API response structure
│   ├── Tool               # Function calling tools
│   └── Usage              # Token usage tracking
├── Client/                 # Network and actor layer
│   └── LLMClient          # Main API client
├── Builders/               # DSL syntax builders
│   ├── ResponseBuilder    # Message composition
│   └── ResponseConfigBuilder # Configuration composition
└── Convenience/            # Helper functions and utilities
    ├── system()           # System message helper
    ├── user()             # User message helper
    └── assistant()        # Assistant message helper
```

### Data Flow Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Code     │───▶│  DSL Builders    │───▶│  Type System    │
│                 │    │                  │    │                 │
│ • Natural syntax│    │ • Result builders│    │ • Validation    │
│ • Declarative   │    │ • Composition    │    │ • Type safety   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Validation    │    │  Serialization   │    │   Network       │
│                 │    │                  │    │                 │
│ • Parameter     │    │ • JSON encoding  │    │ • HTTP requests │
│   validation    │    │ • Error handling │    │ • Response      │
│ • Type checking │    │ • Type erasure   │    │   parsing       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Result Builder Implementation

### Message Builder Pattern

The `ResponseBuilder` uses Swift's result builder to compose messages:

```swift
@resultBuilder
public struct ResponseBuilder {
    public static func buildBlock(_ components: ResponseMessage...) -> [ResponseMessage] {
        Array(components)
    }

    public static func buildOptional(_ component: [ResponseMessage]?) -> [ResponseMessage] {
        component ?? []
    }

    public static func buildEither(first component: [ResponseMessage]) -> [ResponseMessage] {
        component
    }

    public static func buildEither(second component: [ResponseMessage]) -> [ResponseMessage] {
        component
    }

    public static func buildArray(_ components: [[ResponseMessage]]) -> [ResponseMessage] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ expression: ResponseMessage) -> [ResponseMessage] {
        [expression]
    }

    public static func buildExpression(_ expression: String) -> [ResponseMessage] {
        [UserMessage(text: expression)]
    }
}
```

This enables natural syntax like:

```swift
input: {
    system("You are helpful")
    user("Hello")
    if includeContext {
        assistant("Previous context")
    }
    user("How are you?")
}
```

### Configuration Builder Pattern

Similarly, `ResponseConfigBuilder` composes configuration parameters:

```swift
@resultBuilder
public struct ResponseConfigBuilder {
    public static func buildBlock(_ components: ResponseConfigParameter...) -> [ResponseConfigParameter] {
        Array(components)
    }

    // Additional builder methods...
}
```

## Actor-Based Network Layer

### LLMClient Architecture

The `LLMClient` actor encapsulates all network operations:

```swift
public actor LLMClient {
    // Private state
    private let session: URLSession
    private let baseURL: URL
    private let apiKey: String?

    // Public interface
    public func respond(to request: ResponseRequest) async throws -> Response
    public func stream(request: ResponseRequest) -> AsyncThrowingStream<StreamEvent, Error>
    public func chat(model: String, message: String, config: [ResponseConfigParameter]) async throws -> Response
    public func chat(conversation: ResponseConversation, config: [ResponseConfigParameter]) async throws -> Response
}
```

### Thread Safety Guarantees

- **Actor Isolation**: All mutable state is protected by actor isolation
- **Sendable Conformance**: All types crossing actor boundaries are `Sendable`
- **Immutable Messages**: Request/response types are value types for safety
- **Concurrent Streaming**: Safe concurrent access to streaming operations

## Type System Design

### Protocol Hierarchy

```
ResponseMessage (protocol)
├── SystemMessage (struct)
├── UserMessage (struct)
└── AssistantMessage (struct)

ResponseConfigParameter (protocol)
├── Temperature (struct)
├── TopP (struct)
├── MaxOutputTokens (struct)
├── FrequencyPenalty (struct)
├── PresencePenalty (struct)
├── ToolChoice (struct)
├── MaxToolCalls (struct)
├── TopLogprobs (struct)
├── Seed (struct)
├── Tools (struct)
├── ParallelToolCalls (struct)
└── StreamOptions (struct)
```

### Type Safety Features

1. **Compile-Time Validation**: Parameter ranges checked at compile time
2. **Enum Constraints**: Fixed values enforced by enums
3. **Protocol Requirements**: Consistent interface across implementations
4. **Generic Constraints**: Type-safe generic operations

## Error Handling Architecture

### Comprehensive Error Classification

```swift
public enum LLMError: Error, LocalizedError, Equatable, Sendable {
    // Network and connectivity errors
    case invalidURL
    case networkError(String)
    case timeout
    case sslError(String)

    // API and authentication errors
    case authenticationFailed
    case rateLimit
    case serverError(statusCode: Int, message: String?)

    // Data and serialization errors
    case encodingFailed(String)
    case decodingFailed(String)
    case jsonParsingError(String)

    // Validation and configuration errors
    case invalidValue(String)
    case invalidParameter(String, String)
    case missingRequiredField
    case missingBaseURL
    case missingModel

    // Response and processing errors
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
}
```

### Error Recovery Strategies

- **Retry Logic**: Exponential backoff for transient failures
- **Circuit Breaker**: Prevent cascading failures
- **Fallback Responses**: Graceful degradation
- **User-Friendly Messages**: Localized error descriptions

## Streaming Architecture

### AsyncStream Implementation

```swift
public func stream(request: ResponseRequest) -> AsyncThrowingStream<StreamEvent, Error> {
    AsyncThrowingStream { continuation in
        Task {
            do {
                let urlRequest = try await buildRequest(from: request)
                let (bytes, response) = try await session.bytes(for: urlRequest)

                for try await line in bytes.lines {
                    if line.starts(with: "data: ") {
                        let data = line.dropFirst(6)
                        if data == "[DONE]" {
                            continuation.finish()
                            break
                        }

                        let event = try decodeStreamEvent(from: data)
                        continuation.yield(event)
                    }
                }
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}
```

### Stream Event Types

```swift
public enum StreamEvent: Sendable {
    case created                           // Stream initialized
    case inProgress                        // Processing in progress
    case outputItemAdded(OutputItem)       // New content chunk
    case completed(Response)               // Stream finished
    case unknown(type: String, data: AnyCodable) // Unrecognized events
}
```

## Configuration System

### Parameter Composition

Configuration parameters compose through the builder pattern:

```swift
let config: [ResponseConfigParameter] = {
    Temperature(0.7)        // Creativity control
    MaxOutputTokens(300)    // Length limit
    TopP(0.9)              // Sampling method
    FrequencyPenalty(0.1)   // Repetition control
    PresencePenalty(0.1)    // Topic diversity
}
```

### Validation and Application

Each parameter validates its input and applies to the request:

```swift
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
```

## Extensibility Points

### Custom Message Types

```swift
struct CustomMessage: ResponseMessage {
    let role: Role
    let content: [ContentPart]
    let metadata: [String: String]  // Custom fields

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
        try container.encode(metadata, forKey: .metadata)
    }
}
```

### Custom Configuration Parameters

```swift
struct CustomParameter: ResponseConfigParameter {
    let key: String
    let value: AnyCodable

    func apply(to request: inout ResponseRequest) throws {
        // Custom application logic
        request.customParameters[key] = value
    }
}
```

## Performance Optimizations

### Compile-Time Optimizations

1. **Result Builder Inlining**: Builder methods are inlined for zero overhead
2. **Value Type Usage**: Structs provide efficient memory usage
3. **Static Dispatch**: Protocol-oriented design enables static dispatch where possible

### Runtime Optimizations

1. **Connection Reuse**: URLSession maintains persistent connections
2. **JSON Streaming**: Large responses processed incrementally
3. **Memory Pooling**: Efficient memory usage for frequent operations
4. **Lazy Evaluation**: Computations performed only when needed

### Actor Performance

1. **Message Batching**: Multiple operations batched within actor
2. **Non-Isolated Methods**: Pure functions marked as non-isolated
3. **Concurrent Streaming**: Safe concurrent access to streams
4. **Task Priorities**: Appropriate QoS for different operation types

## Testing Architecture

### Unit Testing Structure

```swift
class LLMClientTests: XCTestCase {
    var client: LLMClient!
    var mockSession: URLSession!

    override func setUp() {
        mockSession = URLSession(configuration: .ephemeral)
        client = try! LLMClient(baseURLString: "https://api.example.com")
    }

    func testParameterValidation() throws {
        // Test parameter validation logic
        #expect(throws: LLMError.invalidValue) {
            _ = try Temperature(5.0)
        }
    }

    func testRequestConstruction() throws {
        // Test request building
        let request = try ResponseRequest(
            model: "gpt-4",
            input: { user("test") }
        )
        #expect(request.model == "gpt-4")
    }
}
```

### Mock and Stub Architecture

```swift
class MockLLMClient: LLMClientProtocol {
    var mockResponse: Response?

    func respond(to request: ResponseRequest) async throws -> Response {
        guard let response = mockResponse else {
            throw LLMError.invalidResponse
        }
        return response
    }
}
```

## Security Considerations

### API Key Management
- Environment variable storage
- Never logged or exposed
- Secure key rotation support

### Data Protection
- HTTPS-only communication
- No sensitive data in logs
- Secure serialization of requests/responses

### Input Validation
- Comprehensive parameter validation
- SQL injection prevention
- XSS protection through proper encoding

## Deployment Architecture

### Package Structure
```
SwiftResponsesDSL/
├── Package.swift
├── Sources/
│   └── SwiftResponsesDSL/
│       ├── Core.swift
│       ├── Messages.swift
│       ├── Configuration.swift
│       ├── API.swift
│       ├── Client.swift
│       ├── Builders.swift
│       └── Convenience.swift
├── Tests/
│   └── SwiftResponsesDSLTests/
└── Examples/
    └── [Example Categories]/
```

### Platform Support
- **macOS**: 12.0+
- **iOS**: 15.0+
- **Linux**: Ubuntu 22.04+
- **Swift**: 6.2+

### Distribution
- **Swift Package Manager**: Primary distribution method
- **Carthage**: Legacy support
- **CocoaPods**: Framework integration

## Future Architecture Evolution

### Planned Enhancements

1. **Macro Support**: Compile-time DSL generation
2. **Plugin Architecture**: Extensible tool system
3. **Caching Layer**: Response caching and optimization
4. **Multi-Provider Support**: Unified interface for multiple LLM providers

### Backward Compatibility

- **Semantic Versioning**: Major versions for breaking changes
- **Deprecation Warnings**: Clear migration paths
- **Migration Tools**: Automated code migration assistance

This architecture provides a solid foundation for type-safe, efficient, and extensible LLM integration while maintaining excellent developer experience and performance characteristics.
