# Swift Language Specification for DSLs

This specification outlines patterns and requirements for building embedded domain-specific languages (DSLs) in Swift 6.1+. It emphasizes declarative, type-safe APIs using result builders, concurrency with async/await and actors, JSON serialization via Codable, and extensibility. The guidelines are general-purpose, applicable to various domains (e.g., API requests, configuration, data processing). Specific examples draw from a chat completions context but can be adapted. Use only Foundation; no external dependencies. Minimum platforms: macOS 12.0, iOS 15.0.

## General DSL Requirements

* **Declarative Syntax**: Leverage result builders (@resultBuilder) to enable concise, readable code blocks that support control flow (e.g., if, for, switch). Builders compose arrays of elements (e.g., parameters, messages) from expressions, optionals, and arrays. Ensure builders handle partial failures by rethrowing errors from component initializers.

* **Type Safety**: Use protocols to define extensible interfaces (e.g., for parameters or data elements). Enums for fixed options (e.g., roles, states). Structs for value types to ensure immutability and performance. Avoid classes unless necessary for reference semantics.

* **Configuration and Initialization**: Provide builders for optional parameters, applying them via protocols to mutable structs. Support multiple initializers: one with builders for declarative setup (with throws for validation), another with direct arrays for pre-built data. In builder-based inits, rethrow errors from the builder closures to propagate validation failures.

* **Validation**: Throw custom errors during initialization for invalid values (e.g., range checks, required fields). Use a descriptive error enum conforming to LocalizedError for user-friendly descriptions. For parameters, define standard validation ranges where applicable (e.g., Temperature: 0.0...2.0, MaxLimit: 1...Int.max), and chain validations by applying parameters in sequence, throwing on first failure.

* **Extensibility**: Allow custom conformances to protocols (e.g., new parameter types or data elements). Support future additions like multimodal content via flexible encoding. Provide diverse examples: e.g., for data processing domains, extend DataElement for structured queries; for configurations, add custom ConfigParameters for logging levels or timeouts.

* **JSON Compatibility**: Align with common formats using Codable. Use CodingKeys for key mapping (e.g., snake_case). Handle existential types (e.g., any Protocol) with custom encoding: implement a type-erased wrapper (e.g., AnyEncodable) for heterogeneous arrays, using a switch on concrete types in encode(to:) or decode(from:). For arrays like [any DataElement], use a nestedUnkeyedContainer and encode each element's properties manually to avoid type erasure issues.

* **Performance**: Favor value types (structs/enums) and compile-time features (result builders, @inlinable) to minimize runtime overhead. Use async inference where possible to reduce boilerplate in async methods.

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
  enum CustomError: Error, LocalizedError { 
    case invalidURL, encodingFailed(String), networkError(String), decodingFailed(String), serverError(statusCode: Int, message: String?), rateLimit, invalidResponse, invalidValue(String), missingRequiredField 

    var errorDescription: String? { 
      switch self { 
        /* Provide descriptive strings, e.g., case .invalidValue(let msg): return "Invalid value: \(msg)" */ 
      } 
    } 
  }
  ```
  * Example: Handles domain-specific errors with descriptive strings for equatability and localization.

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
          throw CustomError.invalidValue("Temperature must be between 0.0 and 2.0") 
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
          throw CustomError.invalidValue("MaxLimit must be positive") 
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

## Testing Guidance

* Include unit test patterns using Swift Testing: e.g., @Test for builders with #expect(try config() doesn't throw) for valid configs, #expect(throws: CustomError.self) { try invalidConfig() } for invalids; async tests for Client using #expect(await try client.perform(request) == expected); mock URLSession for networking via a testable URLSessionConfiguration; property-based testing for validations by generating test data manually (e.g., via parameterized @Test functions with ranges), as Swift Testing supports traits like .bug for known issues and .enabled(if:) for conditional tests.
