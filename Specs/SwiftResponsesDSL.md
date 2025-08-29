Specification for SwiftResponsesDSL
Overview
The SwiftResponsesDSL is an embedded Swift Domain-Specific Language (DSL) designed to simplify communication with Large Language Model (LLM) inference servers that support OpenAI-compatible Responses endpoints. It provides a declarative, type-safe interface that abstracts HTTP requests, JSON serialization, authentication, and error handling for both non-streaming and streaming responses. The DSL requires users to provide the complete endpoint URL (baseURL) during client initialization and the model in every request, ensuring compatibility with various servers (e.g., https://api.openai.com/v1/responses, https://your-llm-server.com/custom/endpoint). Optional parameters are configured via a @ResponseConfigBuilder block, allowing users to specify only desired parameters (e.g., Temperature(0.7), MaxOutputTokens(100)) using a result builder for concise, declarative syntax.
To support conversation history, the DSL includes:

An initializer for ResponseRequest that accepts a pre-built array of messages ([any ResponseMessage]), enabling direct passing of conversation history without relying on the result builder.
A ResponseConversation struct for managing persistent conversation history, with methods to append messages and generate ResponseRequests, facilitating stateful interactions. Server-side state management is supported via previousResponseId for servers that implement it.

To enhance usability without reducing functionality:

Added convenience functions (system(_:), user(_:), assistant(_:), tool(_:) ) that return corresponding message types for use in builders.
Extended @ResponseBuilder with buildExpression(_: String) to implicitly create UserMessage from string literals in the input builder, simplifying common single-text user messages.
Added helper methods to ResponseConversation for appending responses (e.g., append(response: Response)), handling output items like messages and tool calls.
Added computed properties to Response for easy extraction of content (e.g., assistantMessages: [AssistantMessage], toolCalls: [Response.OutputItem] excluding messages).
Added convenience methods to LLMClient for common operations, such as chat(model: String, message: String, config: [any ResponseConfigParameter] = []) async throws -> Response, which internally creates a simple ResponseRequest with a single user message.

This specification emphasizes code signatures (e.g., structs, enums, protocols, and their properties/methods) to guide the AI code generator in producing a Swift package that adheres to the defined interfaces. The implementation details (e.g., method bodies, JSON encoding/decoding logic) are left to the code generator, but the data structures for the Responses API are retained as specified, based on OpenAI examples.
Goals

Explicit Configuration: Require baseURL (full endpoint URL) in client initialization and model in every request, without defaults or path modifications.
Optional Parameters: Support any combination of optional parameters (temperature, topP, maxOutputTokens, etc.) via a @ResponseConfigBuilder block, ensuring type safety and minimal code.
Declarative API: Use result builders (@ResponseBuilder, @ResponseConfigBuilder, @ContentPartBuilder) to support control flow (e.g., if, for) in a declarative syntax.
Conversation History: Enable multi-turn conversations via arrays of messages and ResponseConversation for history management, with support for server-side state via previousResponseId.
Type Safety: Enforce roles, parameters, and responses at compile time using enums, protocols, and structs. Handle multimodal content (text, images, files) via typed ContentPart enums.
Concurrency: Use async/await and actors for non-blocking calls; apply nonisolated for streaming method flexibility.
Performance: Use value types (structs) and compile-time transformations (result builders) to minimize runtime overhead.
Extensibility: Support custom messages, events, annotations, and tools via protocols and extensions.
Error Handling: Propagate errors with a custom LLMError enum using throws.
Usability Enhancements: Provide convenience functions, implicit conversions in builders, and helper methods/properties to reduce boilerplate for common scenarios without limiting advanced usage.

Requirements

Swift Version: 6.2+ (for trailing commas, nonisolated, improved type inference, enhanced macros, and refined concurrency).
Dependencies: None; use only Foundation (URLSession for networking, Codable for JSON).
API Compatibility: Align with OpenAI Responses JSON format (camelCase internally, snake_case in JSON via CodingKeys), including multimodal inputs (images/files via base64 data URLs or file IDs) and tools (web search, file search, function calls).
Testing: Support Swift Testing for async validation (e.g., #expect with concurrency traits).
URL Handling: Treat baseURL as the complete endpoint URL, without modification.
Minimum Platform Versions:
- macOS 12.0
- iOS 15.0
- Linux (Ubuntu 22.04+ with Swift 6.0+ toolchain)

Modular Architecture: Implement the DSL using a modular file structure for improved maintainability and developer experience. The generated code must be organized into focused modules rather than a single monolithic file.

Modular Organization:
- Core.swift: Basic enums, protocols, and AnyCodable type-erased codable
- Messages.swift: Message types (SystemMessage, UserMessage, AssistantMessage) and ContentPart
- Configuration.swift: Configuration parameter structs (Temperature, TopP, MaxOutputTokens, etc.)
- API.swift: Request/response types (ResponseRequest, Response, Tool, OutputItem) and conversation management
- Client.swift: LLMClient actor with networking and convenience methods
- Builders.swift: Result builders (@ResponseBuilder, @ResponseConfigBuilder)
- Convenience.swift: Helper functions (system(), user(), assistant(), tool())
- SwiftResponsesDSL.swift: Main entry point with documentation and module coordination


Package.swift Configuration:
```swift
let package = Package(
    name: "SwiftResponsesDSL",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [...],
    targets: [...]
)
```
Date Context: Spec aligns with usage on August 29, 2025, incorporating modern Swift practices and OpenAI Responses API features (statefulness, multimodal support, tools, reasoning models).

Core Components
1. Enums

Role

Signature: enum Role: String, Codable, Sendable { case system, user, assistant, tool }
Purpose: Defines message roles, encoded as JSON strings (e.g., "system").


LLMError

Signature: enum LLMError: Error, LocalizedError, Sendable {
    case invalidURL
    case encodingFailed(String)
    case networkError(String)
    case decodingFailed(String)
    case serverError(statusCode: Int, message: String?)
    case rateLimit
    case invalidResponse
    case invalidValue(String)
    case missingBaseURL
    case missingModel
    case authenticationFailed
    case timeout
    case sslError(String)
    case httpError(statusCode: Int, message: String?)
    case jsonParsingError(String)
    case invalidParameter(String, String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The provided URL is invalid"
        case .encodingFailed(let msg):
            return "Failed to encode request: \(msg)"
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .decodingFailed(let msg):
            return "Failed to decode response: \(msg)"
        case .serverError(let code, let msg):
            return "Server error (\(code)): \(msg ?? "Unknown error")"
        case .rateLimit:
            return "Rate limit exceeded"
        case .invalidResponse:
            return "Received invalid response from server"
        case .invalidValue(let msg):
            return "Invalid value: \(msg)"
        case .missingBaseURL:
            return "Base URL is required but not provided"
        case .missingModel:
            return "Model is required but not provided"
        case .authenticationFailed:
            return "Authentication failed"
        case .timeout:
            return "Request timed out"
        case .sslError(let msg):
            return "SSL/TLS error: \(msg)"
        case .httpError(let code, let msg):
            return "HTTP error (\(code)): \(msg ?? "Unknown error")"
        case .jsonParsingError(let msg):
            return "JSON parsing error: \(msg)"
        case .invalidParameter(let param, let reason):
            return "Invalid parameter '\(param)': \(reason)"
        }
    }
}
Purpose: Handles errors for invalid URLs, JSON failures, server errors (e.g., HTTP 429 for rate limits), network issues, authentication failures, timeouts, and invalid parameters.


ContentPart

Signature: enum ContentPart: Encodable, Sendable {
    case text(String)
    case imageUrl(url: String, detail: Detail? = nil)
    case inputFile(fileId: String)
    case inputFileData(dataUrl: String)
    enum Detail: String, Encodable, Sendable { case auto, low, high }
}


Purpose: Represents multimodal content (text, image URLs, files via ID or base64 data URLs). Encodes to OpenAI format (e.g., {"type": "text", "text": "..."}).


Annotation

Signature:enum Annotation: Decodable, Sendable {
    case urlCitation(startIndex: Int, endIndex: Int, url: String, title: String)
    case fileCitation(index: Int, fileId: String, filename: String)
    case unknown(type: String, data: [String: AnyCodable])
}


Purpose: Represents citations in response text (e.g., url_citation, file_citation).


ResponseEvent

Signature:enum ResponseEvent: Sendable {
    case created(Response)
    case inProgress(Response)
    case outputItemAdded(outputIndex: Int, item: Response.OutputItem)
    case contentPartAdded(itemId: String, outputIndex: Int, contentIndex: Int, part: Response.ContentPartDecodable)
    case outputTextDelta(itemId: String, outputIndex: Int, contentIndex: Int, delta: String)
    case outputTextDone(itemId: String, outputIndex: Int, contentIndex: Int, text: String)
    case contentPartDone(itemId: String, outputIndex: Int, contentIndex: Int, part: Response.ContentPartDecodable)
    case outputItemDone(outputIndex: Int, item: Response.OutputItem)
    case completed(Response)
    case unknown(type: String, data: [String: AnyCodable])
}


Purpose: Represents streaming events (e.g., response.created, response.output_text.delta).



2. Protocols

ResponseMessage

Signature: protocol ResponseMessage: Encodable, Sendable {
    var role: Role { get }
    var content: [ContentPart] { get }
}


Purpose: Defines messages with a role and multimodal content, encoded as JSON objects or strings (for single text parts).


ResponseConfigParameter

Signature: protocol ResponseConfigParameter: Sendable {}


Purpose: Marker protocol for configuration parameter structs.



3. Structs

AnyCodable

Signature:enum AnyCodable: Codable, Sendable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([AnyCodable])
    case dictionary([String: AnyCodable])

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .dictionary(let value):
            try container.encode(value)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([AnyCodable].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: AnyCodable].self) {
            self = .dictionary(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    // Convenience accessors
    var intValue: Int? {
        if case .int(let value) = self { return value }
        return nil
    }

    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    var doubleValue: Double? {
        if case .double(let value) = self { return value }
        return nil
    }
}

Purpose: Type-erased Codable for flexible JSON fields (e.g., metadata, error). Provides complete encoding and decoding implementation for all supported types.


UserMessage

Signature:struct UserMessage: ResponseMessage {
    let role: Role
    let content: [ContentPart]
    init(role: Role = .user, @ContentPartBuilder content: () -> [ContentPart])
    init(role: Role = .user, text: String)
    init(role: Role = .user, fileId: String)
    init(role: Role = .user, base64File: String, mimeType: String = "application/pdf")
}


Purpose: Represents user or tool messages with multimodal content.


SystemMessage

Signature:struct SystemMessage: ResponseMessage {
    let role: Role = .system
    let content: [ContentPart]
    init(text: String)
}


Purpose: Represents system prompts.


AssistantMessage

Signature:struct AssistantMessage: ResponseMessage {
    let role: Role = .assistant
    let content: [ContentPart]
    init(text: String)
}


Purpose: Represents assistant responses in conversation history.


Tool

Signature:struct Tool: Codable, Sendable {
    let type: String
    let function: Function?
    let fileSearch: FileSearch?
    let webSearchPreview: WebSearchPreview?

    enum CodingKeys: String, CodingKey {
        case type, function
        case fileSearch = "file_search"
        case webSearchPreview = "web_search_preview"
    }

    struct Function: Codable, Sendable {
        let name: String
        let description: String?
        let parameters: [String: AnyCodable]
        let strict: Bool?

        enum CodingKeys: String, CodingKey {
            case name, description, parameters, strict
        }
    }

    struct FileSearch: Codable, Sendable {
        let filters: [String: AnyCodable]?
        let maxNumResults: Int?
        let rankingOptions: RankingOptions?
        let vectorStoreIds: [String]?

        enum CodingKeys: String, CodingKey {
            case filters
            case maxNumResults = "max_num_results"
            case rankingOptions = "ranking_options"
            case vectorStoreIds = "vector_store_ids"
        }

        struct RankingOptions: Codable, Sendable {
            let ranker: String
            let scoreThreshold: Double

            enum CodingKeys: String, CodingKey {
                case ranker
                case scoreThreshold = "score_threshold"
            }
        }
    }

    struct WebSearchPreview: Codable, Sendable {
        let domains: [String]
        let searchContextSize: String
        let userLocation: UserLocation?

        enum CodingKeys: String, CodingKey {
            case domains
            case searchContextSize = "search_context_size"
            case userLocation = "user_location"
        }

        struct UserLocation: Codable, Sendable {
            let type: String
            let city: String?
            let country: String?
            let region: String?
            let timezone: String?

            enum CodingKeys: String, CodingKey {
                case type, city, country, region, timezone
            }
        }
    }
}

Purpose: Defines tools (e.g., function, file_search, web_search_preview) with complete configurations and proper JSON mapping.


Configuration Structs

Signature (example for Temperature):struct Temperature: ResponseConfigParameter {
    let value: Double
    init(_ value: Double) throws
}


Configuration Parameter Structs

**TopP**
```swift
struct TopP: ResponseConfigParameter {
    let value: Double
    init(_ value: Double) throws {
        guard (0.0...1.0).contains(value) else {
            throw LLMError.invalidValue("TopP must be between 0.0 and 1.0")
        }
        self.value = value
    }
    func apply(to request: inout ResponseRequest) throws {
        request.topP = value
    }
}
```

**MaxOutputTokens**
```swift
struct MaxOutputTokens: ResponseConfigParameter {
    let value: Int
    init(_ value: Int) throws {
        guard value > 0 else {
            throw LLMError.invalidValue("MaxOutputTokens must be positive")
        }
        self.value = value
    }
    func apply(to request: inout ResponseRequest) throws {
        request.maxOutputTokens = value
    }
}
```

**FrequencyPenalty**
```swift
struct FrequencyPenalty: ResponseConfigParameter {
    let value: Double
    init(_ value: Double) throws {
        guard (-2.0...2.0).contains(value) else {
            throw LLMError.invalidValue("FrequencyPenalty must be between -2.0 and 2.0")
        }
        self.value = value
    }
    func apply(to request: inout ResponseRequest) throws {
        request.frequencyPenalty = value
    }
}
```

**PresencePenalty**
```swift
struct PresencePenalty: ResponseConfigParameter {
    let value: Double
    init(_ value: Double) throws {
        guard (-2.0...2.0).contains(value) else {
            throw LLMError.invalidValue("PresencePenalty must be between -2.0 and 2.0")
        }
        self.value = value
    }
    func apply(to request: inout ResponseRequest) throws {
        request.presencePenalty = value
    }
}
```

**MaxToolCalls**
```swift
struct MaxToolCalls: ResponseConfigParameter {
    let value: Int
    init(_ value: Int) throws {
        guard (1...128).contains(value) else {
            throw LLMError.invalidValue("MaxToolCalls must be between 1 and 128")
        }
        self.value = value
    }
    func apply(to request: inout ResponseRequest) throws {
        request.maxToolCalls = value
    }
}
```

**ToolChoice**
```swift
struct ToolChoice: ResponseConfigParameter {
    let value: String
    init(_ value: String) throws {
        let validChoices = ["none", "auto", "required"]
        guard validChoices.contains(value) else {
            throw LLMError.invalidValue("ToolChoice must be one of: \(validChoices.joined(separator: ", "))")
        }
        self.value = value
    }
    func apply(to request: inout ResponseRequest) throws {
        request.toolChoice = value
    }
}
```

**Tools**
```swift
struct Tools: ResponseConfigParameter {
    let value: [Tool]
    init(_ value: [Tool]) throws {
        guard !value.isEmpty else {
            throw LLMError.invalidValue("Tools array cannot be empty")
        }
        self.value = value
    }
    func apply(to request: inout ResponseRequest) throws {
        request.tools = value
    }
}
```

**StreamOptions**
```swift
struct StreamOptions: ResponseConfigParameter {
    let value: [String: AnyCodable]
    init(_ value: [String: AnyCodable]) {
        self.value = value
    }
    func apply(to request: inout ResponseRequest) throws {
        request.streamOptions = value
    }
}
```

**TopLogprobs**
```swift
struct TopLogprobs: ResponseConfigParameter {
    let value: Int
    init(_ value: Int) throws {
        guard (0...20).contains(value) else {
            throw LLMError.invalidValue("TopLogprobs must be between 0 and 20")
        }
        self.value = value
    }
    func apply(to request: inout ResponseRequest) throws {
        request.topLogprobs = value
    }
}
```

**Seed**
```swift
struct Seed: ResponseConfigParameter {
    let value: Int
    init(_ value: Int) throws {
        guard value >= 0 else {
            throw LLMError.invalidValue("Seed must be non-negative")
        }
        self.value = value
    }
    func apply(to request: inout ResponseRequest) throws {
        request.seed = value
    }
}
```

Purpose: Represent optional request parameters with validation. Each struct enforces specific value ranges and formats as required by the OpenAI API.


ResponseRequest

Signature:struct ResponseRequest: Encodable, Sendable {
    let model: String
    let messages: [any ResponseMessage]
    let stream: Bool
    let previousResponseId: String?
    let temperature: Double?
    let topP: Double?
    let maxOutputTokens: Int?
    let toolChoice: String?
    let tools: [Tool]?
    let parallelToolCalls: Bool?
    let frequencyPenalty: Double?
    let presencePenalty: Double?
    let logitBias: [Int: Int]?
    let user: String?
    let stop: [String]?
    let seed: Int?
    let responseFormat: [String: AnyCodable]?
    let logprobs: Bool?
    let topLogprobs: Int?
    let streamOptions: [String: AnyCodable]?
    let truncation: String?
    let store: Bool?
    let background: Bool?
    let maxToolCalls: Int?
    let serviceTier: String?

    enum CodingKeys: String, CodingKey {
        case model, messages, stream
        case previousResponseId = "previous_response_id"
        case temperature, topP = "top_p"
        case maxOutputTokens = "max_output_tokens"
        case toolChoice = "tool_choice"
        case tools
        case parallelToolCalls = "parallel_tool_calls"
        case frequencyPenalty = "frequency_penalty"
        case presencePenalty = "presence_penalty"
        case logitBias = "logit_bias"
        case user, stop, seed
        case responseFormat = "response_format"
        case logprobs
        case topLogprobs = "top_logprobs"
        case streamOptions = "stream_options"
        case truncation, store, background
        case maxToolCalls = "max_tool_calls"
        case serviceTier = "service_tier"
    }

    init(model: String, input: [any ResponseMessage], previousResponseId: String? = nil, stream: Bool = false, config: [any ResponseConfigParameter]) throws
    init(model: String, previousResponseId: String? = nil, stream: Bool = false, @ResponseConfigBuilder config: () throws -> [any ResponseConfigParameter], @ResponseBuilder input: () -> [any ResponseMessage]) throws
}


Purpose: Represents the API request with required and optional parameters. All CodingKeys map camelCase properties to snake_case JSON keys as required by the OpenAI API.


ResponseConversation

Signature:struct ResponseConversation: Sendable {
    var history: [any ResponseMessage]
    mutating func add(message: any ResponseMessage)
    mutating func addUser(content: String)
    mutating func addAssistant(content: String)
    mutating func append(response: Response) throws
    func request(model: String, previousResponseId: String? = nil, @ResponseConfigBuilder config: () throws -> [any ResponseConfigParameter]) throws -> ResponseRequest
}


Purpose: Manages conversation history and generates requests. The append(response:) method extracts and appends assistant messages and handles tool calls appropriately (e.g., append tool call results as tool messages).


Response

Signature:struct Response: Decodable, Sendable {
    let id: String
    let object: String
    let createdAt: Int
    let status: String
    let background: Bool?
    let error: [String: AnyCodable]?
    let incompleteDetails: [String: AnyCodable]?
    let instructions: String?
    let maxOutputTokens: Int?
    let maxToolCalls: Int?
    let model: String
    let output: [OutputItem]
    let parallelToolCalls: Bool
    let previousResponseId: String?
    let reasoning: Reasoning
    let serviceTier: String?
    let store: Bool
    let temperature: Double
    let text: TextFormat
    let toolChoice: String
    let tools: [Tool]
    let topLogprobs: Int
    let topP: Double
    let truncation: String
    let usage: Usage?
    let user: String?
    let metadata: [String: AnyCodable]
    var assistantMessages: [AssistantMessage] { get }
    var toolCalls: [OutputItem] { get }

    enum CodingKeys: String, CodingKey {
        case id, object, status, background, error, instructions, model, output, reasoning, store, temperature, text, tools, truncation, usage, user, metadata
        case createdAt = "created_at"
        case incompleteDetails = "incomplete_details"
        case maxOutputTokens = "max_output_tokens"
        case maxToolCalls = "max_tool_calls"
        case parallelToolCalls = "parallel_tool_calls"
        case previousResponseId = "previous_response_id"
        case serviceTier = "service_tier"
        case toolChoice = "tool_choice"
        case topLogprobs = "top_logprobs"
        case topP = "top_p"
    }
    enum OutputItem: Decodable, Sendable {
        case message(Message)
        case toolCall(ToolCall)
        case fileSearchCall(FileSearchCall)
        case webSearchCall(WebSearchCall)
        case functionCall(FunctionCall)

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)

            switch type {
            case "message":
                let message = try Message(from: decoder)
                self = .message(message)
            case "tool_call":
                let toolCall = try ToolCall(from: decoder)
                self = .toolCall(toolCall)
            case "file_search_call":
                let fileSearchCall = try FileSearchCall(from: decoder)
                self = .fileSearchCall(fileSearchCall)
            case "web_search_call":
                let webSearchCall = try WebSearchCall(from: decoder)
                self = .webSearchCall(webSearchCall)
            case "function_call":
                let functionCall = try FunctionCall(from: decoder)
                self = .functionCall(functionCall)
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown output item type: \(type)")
            }
        }

        private enum CodingKeys: String, CodingKey {
            case type
        }

        struct Message: Decodable, Sendable {
            let type: String
            let id: String
            let status: String
            let role: Role
            let content: [ContentPartDecodable]
        }
        struct ToolCall: Decodable, Sendable {
            let type: String
            let id: String
            let status: String
        }
        struct FileSearchCall: Decodable, Sendable {
            let type: String
            let id: String
            let status: String
            let queries: [String]
            let results: [AnyCodable]?
        }
        struct WebSearchCall: Decodable, Sendable {
            let type: String
            let id: String
            let status: String
        }
        struct FunctionCall: Decodable, Sendable {
            let type: String
            let id: String
            let callId: String
            let name: String
            let arguments: String
            let status: String

            enum CodingKeys: String, CodingKey {
                case type, id, status, name, arguments
                case callId = "call_id"
            }
        }
    }
    struct ContentPartDecodable: Decodable, Sendable {
        let type: String
        let text: String?
        let annotations: [Annotation]
        let logprobs: [[String: AnyCodable]]
    }
    struct Reasoning: Decodable, Sendable {
        let effort: String?
        let summary: String?
    }
    struct TextFormat: Decodable, Sendable {
        let format: Format
        struct Format: Decodable, Sendable {
            let type: String
        }
    }
    struct Usage: Decodable, Sendable {
        let inputTokens: Int
        let inputTokensDetails: InputTokensDetails
        let outputTokens: Int
        let outputTokensDetails: OutputTokensDetails
        let totalTokens: Int

        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case inputTokensDetails = "input_tokens_details"
            case outputTokens = "output_tokens"
            case outputTokensDetails = "output_tokens_details"
            case totalTokens = "total_tokens"
        }

        struct InputTokensDetails: Decodable, Sendable {
            let cachedTokens: Int

            enum CodingKeys: String, CodingKey {
                case cachedTokens = "cached_tokens"
            }
        }
        struct OutputTokensDetails: Decodable, Sendable {
            let reasoningTokens: Int

            enum CodingKeys: String, CodingKey {
                case reasoningTokens = "reasoning_tokens"
            }
        }
    }
}


Purpose: Represents non-streaming API responses, aligned with OpenAI Responses format. Computed properties like assistantMessages filter and convert .message items with .assistant role; toolCalls returns non-message output items.



4. Result Builders

ContentPartBuilder

Signature:@resultBuilder
struct ContentPartBuilder {
    static func buildBlock(_ components: ContentPart...) -> [ContentPart]
    static func buildOptional(_ component: [ContentPart]?) -> [ContentPart]
    static func buildEither(first component: [ContentPart]) -> [ContentPart]
    static func buildEither(second component: [ContentPart]) -> [ContentPart]
    static func buildArray(_ components: [[ContentPart]]) -> [ContentPart]
    static func buildExpression(_ expression: ContentPart) -> [ContentPart]
}


Purpose: Builds multimodal content declaratively.


ResponseBuilder

Signature:@resultBuilder
struct ResponseBuilder {
    static func buildBlock(_ components: (any ResponseMessage)...) -> [any ResponseMessage]
    static func buildOptional(_ component: [any ResponseMessage]?) -> [any ResponseMessage]
    static func buildEither(first component: [any ResponseMessage]) -> [any ResponseMessage]
    static func buildEither(second component: [any ResponseMessage]) -> [any ResponseMessage]
    static func buildArray(_ components: [[any ResponseMessage]]) -> [any ResponseMessage]
    static func buildExpression(_ expression: any ResponseMessage) -> [any ResponseMessage]
    static func buildExpression(_ expression: String) -> [any ResponseMessage]
    static func buildLimitedAvailability(_ component: [any ResponseMessage]) -> [any ResponseMessage]
    static func buildFinalResult(_ component: [any ResponseMessage]) -> [any ResponseMessage]
}

Example Implementation:
```swift
@resultBuilder
struct ResponseBuilder {
    static func buildBlock(_ components: (any ResponseMessage)...) -> [any ResponseMessage] {
        Array(components)
    }

    static func buildOptional(_ component: [any ResponseMessage]?) -> [any ResponseMessage] {
        component ?? []
    }

    static func buildEither(first component: [any ResponseMessage]) -> [any ResponseMessage] {
        component
    }

    static func buildEither(second component: [any ResponseMessage]) -> [any ResponseMessage] {
        component
    }

    static func buildArray(_ components: [[any ResponseMessage]]) -> [any ResponseMessage] {
        components.flatMap { $0 }
    }

    static func buildExpression(_ expression: any ResponseMessage) -> [any ResponseMessage] {
        [expression]
    }

    static func buildExpression(_ expression: String) -> [any ResponseMessage] {
        [UserMessage(text: expression)]
    }

    static func buildLimitedAvailability(_ component: [any ResponseMessage]) -> [any ResponseMessage] {
        component
    }

    static func buildFinalResult(_ component: [any ResponseMessage]) -> [any ResponseMessage] {
        component
    }
}
```

Purpose: Builds message arrays declaratively. The added buildExpression(_: String) allows string literals to be implicitly converted to [UserMessage(text: expression)], simplifying common user inputs. Includes all standard result builder methods for complete control flow support.


ResponseConfigBuilder

Signature:@resultBuilder
struct ResponseConfigBuilder {
    static func buildBlock(_ components: (any ResponseConfigParameter)...) -> [any ResponseConfigParameter]
    static func buildOptional(_ component: [any ResponseConfigParameter]?) -> [any ResponseConfigParameter]
    static func buildEither(first component: [any ResponseConfigParameter]) -> [any ResponseConfigParameter]
    static func buildEither(second component: [any ResponseConfigParameter]) -> [any ResponseConfigParameter]
    static func buildArray(_ components: [[any ResponseConfigParameter]]) -> [any ResponseConfigParameter]
    static func buildExpression(_ expression: any ResponseConfigParameter) -> [any ResponseConfigParameter]
    static func buildLimitedAvailability(_ component: [any ResponseConfigParameter]) -> [any ResponseConfigParameter]
    static func buildFinalResult(_ component: [any ResponseConfigParameter]) -> [any ResponseConfigParameter]
}

Example Implementation:
```swift
@resultBuilder
struct ResponseConfigBuilder {
    static func buildBlock(_ components: (any ResponseConfigParameter)...) -> [any ResponseConfigParameter] {
        Array(components)
    }

    static func buildOptional(_ component: [any ResponseConfigParameter]?) -> [any ResponseConfigParameter] {
        component ?? []
    }

    static func buildEither(first component: [any ResponseConfigParameter]) -> [any ResponseConfigParameter] {
        component
    }

    static func buildEither(second component: [any ResponseConfigParameter]) -> [any ResponseConfigParameter] {
        component
    }

    static func buildArray(_ components: [[any ResponseConfigParameter]]) -> [any ResponseConfigParameter] {
        components.flatMap { $0 }
    }

    static func buildExpression(_ expression: any ResponseConfigParameter) -> [any ResponseConfigParameter] {
        [expression]
    }

    static func buildLimitedAvailability(_ component: [any ResponseConfigParameter]) -> [any ResponseConfigParameter] {
        component
    }

    static func buildFinalResult(_ component: [any ResponseConfigParameter]) -> [any ResponseConfigParameter] {
        component
    }
}
```

Purpose: Builds configuration parameters declaratively. Includes all standard result builder methods for complete control flow support in configuration blocks.



5. Convenience Functions

Signature:func system(_ text: String) -> SystemMessage
func user(_ text: String) -> UserMessage
func user(@ContentPartBuilder content: () -> [ContentPart]) -> UserMessage
func assistant(_ text: String) -> AssistantMessage
func tool(_ text: String) -> UserMessage // With role .tool


Purpose: Provide shorthand for creating common message types in builders, reducing verbosity (e.g., input: { system("Prompt") ; "User query" } uses implicit UserMessage for the string).

6. Actor: LLMClient

**Authentication Requirements:**
The LLMClient must support API key authentication for LLM API access. Authentication is critical for production use and must be implemented securely.

**Supported Authentication Methods:**
1. **API Key Authentication**: Required for most LLM APIs (OpenAI, etc.)
2. **No Authentication**: For testing or authenticated environments
3. **Custom Headers**: Extensible for future authentication methods

Signature:actor LLMClient {
    public let baseURL: URL
    private let session: URLSession
    private let apiKey: String?
    private let hasAuth: Bool

    // Primary initializer with API key
    public init(baseURLString: String, apiKey: String) throws

    // Alternative initializer without authentication
    public init(baseURLString: String) throws

    // URL-based initializer with optional API key
    public init(baseURL: URL, apiKey: String? = nil, session: URLSession = .shared)

    // Authentication validation
    public nonisolated var hasAuthentication: Bool { hasAuth }
    public nonisolated func validateAuthentication() throws

    // Initialization requirements:
    // - baseURL must be a valid URL
    // - apiKey (if provided) cannot be empty
    // - hasAuth computed during initialization for thread-safe access

    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: URL, apiKey: String? = nil, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.hasAuth = apiKey != nil
        self.session = session

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase

        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    func respond(_ request: ResponseRequest) async throws -> Response {
        let url = try createURL()
        var urlRequest = URLRequest(url: url)

        // Configure request
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Encode request body
        urlRequest.httpBody = try encoder.encode(request)

        // Make request
        let (data, response) = try await session.data(for: urlRequest)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw LLMError.httpError(statusCode: httpResponse.statusCode, message: nil)
        }

        // Decode response
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw LLMError.decodingFailed("Failed to decode response: \(error.localizedDescription)")
        }
    }

    nonisolated func stream(_ request: ResponseRequest) -> AsyncThrowingStream<ResponseEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let streamingRequest = ResponseRequest(
                        model: request.model,
                        input: request.messages,
                        previousResponseId: request.previousResponseId,
                        stream: true,  // Force streaming
                        config: []
                    )

                    try await self.performStreaming(request: streamingRequest, continuation: continuation)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func chat(model: String, message: String, @ResponseConfigBuilder config: () throws -> [any ResponseConfigParameter] = { [] }) async throws -> Response {
        let messages: [any ResponseMessage] = [UserMessage(text: message)]
        return try await chat(model: model, messages: messages, config: config)
    }

    func chat(model: String, messages: [any ResponseMessage], @ResponseConfigBuilder config: () throws -> [any ResponseConfigParameter] = { [] }) async throws -> Response {
        let request = try ResponseRequest(model: model, input: messages, config: config)
        return try await respond(request)
    }

    private func createURL() throws -> URL {
        guard let url = URL(string: baseURL) else {
            throw LLMError.invalidURL
        }
        return url
    }

    private func performStreaming(request: ResponseRequest, continuation: AsyncThrowingStream<ResponseEvent, Error>.Continuation) async throws {
        let url = try createURL()
        var streamingRequest = URLRequest(url: url)
        streamingRequest.httpMethod = "POST"
        streamingRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        streamingRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        streamingRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        streamingRequest.setValue("keep-alive", forHTTPHeaderField: "Connection")

        // Encode request body
        streamingRequest.httpBody = try encoder.encode(request)

        let (bytes, response) = try await session.bytes(for: streamingRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw LLMError.httpError(statusCode: httpResponse.statusCode, message: nil)
        }

        // Parse SSE events
        var buffer = ""
        for try await line in bytes.lines {
            buffer += line + "\n"

            if line.isEmpty {
                // Process complete SSE event
                if let event = try parseSSEEvent(from: buffer) {
                    continuation.yield(event)
                }
                buffer = ""
            }
        }

        continuation.finish()
    }

    private func parseSSEEvent(from buffer: String) throws -> ResponseEvent? {
        let lines = buffer.components(separatedBy: "\n")
        var eventType: String?
        var eventData: String?

        for line in lines {
            if line.hasPrefix("event: ") {
                eventType = String(line.dropFirst(7))
            } else if line.hasPrefix("data: ") {
                eventData = String(line.dropFirst(6))
            }
        }

        guard let eventType = eventType, let eventData = eventData else {
            return nil
        }

        // Parse event data as JSON
        guard let data = eventData.data(using: .utf8) else {
            throw LLMError.decodingFailed("Invalid event data encoding")
        }

        switch eventType {
        case "response.created":
            let response = try decoder.decode(Response.self, from: data)
            return .created(response)
        case "response.in_progress":
            let response = try decoder.decode(Response.self, from: data)
            return .inProgress(response)
        case "response.output_item.added":
            let itemData = try decoder.decode([String: AnyCodable].self, from: data)
            if let outputIndex = itemData["output_index"]?.intValue,
               let itemJson = itemData["item"] {
                // Parse the item based on its type
                // This would need more specific implementation based on the item structure
                return .outputItemAdded(outputIndex: outputIndex, item: .message(Message(type: "message", id: "", status: "", role: .assistant, content: [])))
            }
        case "response.completed":
            let response = try decoder.decode(Response.self, from: data)
            return .completed(response)
        default:
            return .unknown(type: eventType, data: [:])
        }

        return nil
    }
}

Implementation Notes:
- Actor ensures thread-safe access to baseURL, apiKey, and URLSession
- nonisolated stream method allows cross-actor calls without await
- Automatic snake_case conversion for JSON encoding/decoding
- Comprehensive error handling with specific error types
- Convenience chat methods reduce boilerplate for common use cases

Purpose: Manages API calls with thread-safe state (baseURL, apiKey, URLSession). The added chat methods provide convenience for simple non-streaming requests, internally creating and sending a ResponseRequest with default stream=false and no previousResponseId.

Usage Examples

## Basic Chat Completion
```swift
import SwiftResponsesDSL

// Initialize client
let client = try LLMClient(
    baseURL: "https://api.openai.com/v1/chat/completions",
    apiKey: "your-api-key-here"
)

// Simple chat request
let response = try await client.chat(
    model: "gpt-4",
    message: "Explain quantum computing in simple terms."
)
print(response.assistantMessages.first?.content.first?.text ?? "No response")
```

## Advanced Configuration with DSL
```swift
// Complex request with multiple parameters
let request = try ResponseRequest(model: "gpt-4-turbo-preview") {
    Temperature(0.7)
    MaxOutputTokens(1000)
    TopP(0.9)
    FrequencyPenalty(0.1)
    PresencePenalty(0.1)
    ToolChoice("auto")
} input: {
    system("You are a helpful coding assistant with expertise in Swift.")
    user("Please review this Swift code and suggest improvements.")
    user(fileId: "file_abc123")  // Attach a file
}

// Send request
let response = try await client.respond(request)

// Access response data
for message in response.assistantMessages {
    if let text = message.content.first?.text {
        print("Assistant: \(text)")
    }
}

// Check usage statistics
if let usage = response.usage {
    print("Tokens used: \(usage.totalTokens)")
    print("Input tokens: \(usage.inputTokens)")
    print("Output tokens: \(usage.outputTokens)")
}
```

## Multimodal Content
```swift
let multimodalRequest = try ResponseRequest(model: "gpt-4-vision-preview") {
    Temperature(0.1)
    MaxOutputTokens(500)
} input: {
    system("You are an expert at analyzing images and providing detailed descriptions.")
    UserMessage(role: .user) {
        .text("What's in this image?")
        .imageUrl(url: "https://example.com/image.jpg", detail: .high)
    }
}

let response = try await client.respond(multimodalRequest)
```

## Tool Usage
```swift
let toolRequest = try ResponseRequest(model: "gpt-4-turbo-preview") {
    Temperature(0.1)
    ToolChoice("auto")
} input: {
    system("You are a helpful assistant with access to tools.")
    "What's the current weather in San Francisco?"
}

// Configure tools
let tools = [
    Tool(type: "function",
         function: .init(name: "get_weather",
                        description: "Get current weather for a location",
                        parameters: ["location": ["type": "string"]]))
]

let requestWithTools = ResponseRequest(
    model: "gpt-4-turbo-preview",
    input: toolRequest.messages,
    config: [ToolChoice("auto"), Tools(tools)]
)

let response = try await client.respond(requestWithTools)

// Handle tool calls
for outputItem in response.output {
    switch outputItem {
    case .toolCall(let toolCall):
        print("Tool called: \(toolCall.id)")
        // Execute tool and create tool response message
    case .message(let message):
        if let text = message.content.first?.text {
            print("Response: \(text)")
        }
    default:
        break
    }
}
```

## Streaming Response
```swift
let streamingRequest = try ResponseRequest(model: "gpt-4") {
    Temperature(0.7)
    StreamOptions(["include_usage": true])
} input: {
    system("You are a helpful assistant.")
    "Tell me a story about AI."
}

let stream = client.stream(streamingRequest)

for try await event in stream {
    switch event {
    case .created(let response):
        print("Response created: \(response.id)")
    case .inProgress(let response):
        print("Response in progress: \(response.status)")
    case .outputItemAdded(let itemId, let item):
        print("New output item: \(itemId)")
    case .contentPartAdded(_, _, _, let part):
        if let text = part.text {
            print(text, terminator: "")
        }
    case .completed(let response):
        print("\nCompleted!")
        if let usage = response.usage {
            print("Total tokens: \(usage.totalTokens)")
        }
    default:
        break
    }
}
```

## Conversation Management
```swift
var conversation = ResponseConversation()

// Add initial system message
conversation.add(message: SystemMessage(text: "You are a helpful coding assistant."))

// Add user message
conversation.addUser(content: "Help me refactor this Swift function.")

// Generate request from conversation
let request = try conversation.request(model: "gpt-4") {
    Temperature(0.3)
    MaxOutputTokens(1000)
}

// Send request
let response = try await client.respond(request)

// Append response to conversation
try conversation.append(response: response)

// Continue conversation
conversation.addUser(content: "Can you also add error handling?")
let nextRequest = try conversation.request(model: "gpt-4") {
    Temperature(0.3)
}
let nextResponse = try await client.respond(nextRequest)
```

## Error Handling
```swift
do {
    let response = try await client.chat(model: "invalid-model", message: "Hello")
} catch LLMError.invalidValue(let message) {
    print("Validation error: \(message)")
} catch LLMError.rateLimit {
    print("Rate limit exceeded, please try again later")
} catch LLMError.httpError(let code, let message) {
    print("HTTP error \(code): \(message ?? "Unknown error")")
} catch {
    print("Unexpected error: \(error.localizedDescription)")
}
```

## Custom Configuration Parameters
```swift
// Create custom parameter
struct CustomTemperature: ResponseConfigParameter {
    let value: Double

    init(_ value: Double) throws {
        guard (0.0...2.0).contains(value) else {
            throw LLMError.invalidValue("Custom temperature must be between 0.0 and 2.0")
        }
        self.value = value
    }

    func apply(to request: inout ResponseRequest) throws {
        request.temperature = value
    }
}

// Use custom parameter
let request = try ResponseRequest(model: "gpt-4") {
    CustomTemperature(0.8)
} input: {
    "Hello, world!"
}
```



Extensibility

Extend ResponseEvent for new event types.
Extend Annotation for new annotation types.
Extend Response.OutputItem for new output types.
Extend Tool for additional tool configurations.
Extend Response or ResponseConversation with custom helpers.

Implementation Notes

Decoding: Use CodingKeys for snake_case JSON. Implement custom decoding for Response.OutputItem based on type.
Streaming: Parse SSE events (split by \n\n, process event: and data: lines) and map to ResponseEvent.
Concurrency: Ensure all types conform to Sendable. Use nonisolated for stream method.
Validation: Enforce parameter constraints (e.g., Temperature range 0.0–2.0) with LLMError.invalidValue.
Helpers: Implement append(response:) to handle various OutputItem cases (e.g., convert .message to AssistantMessage, add tool results as .tool messages if applicable). For computed properties, filter output array accordingly.
Platform: Set macOS(.v12), iOS(.v15) in Package.swift.
Docs: Include SwiftDoc comments for public APIs.

Required Tests

Tests should use Swift Testing with #expect and cover:
ResponseRequest initialization and configuration.
Invalid parameter validation (e.g., Temperature(3.0)).
ResponseConversation history management and append(response:).
Array-based ResponseRequest initialization.
LLMClient initialization validation and convenience chat methods.
Streaming SSE parsing.
Multimodal message handling.
Empty input handling.
Stateful request with previousResponseId.
Response decoding (including reasoning and usage).
Web search and file search response decoding.
Function call response decoding.
Implicit string to UserMessage in @ResponseBuilder.
Convenience functions (system(_:), etc.) in builders.



This specification provides code signatures to guide the AI code generator in producing a Swift 6.1+ package for the SwiftResponsesDSL, retaining OpenAI-compatible data structures while incorporating usability improvements.cursorcur
