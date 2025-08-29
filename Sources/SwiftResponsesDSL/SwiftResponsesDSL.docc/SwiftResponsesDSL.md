# SwiftResponsesDSL

@Metadata {
    @DisplayName("SwiftResponsesDSL")
    @PageKind(sampleCode)
    @CallToAction(
        purpose: link,
        label: "View on GitHub",
        url: "https://github.com/RichNasz/SwiftResponsesDSL"
    )
}

SwiftResponsesDSL is an embedded Swift Domain-Specific Language (DSL) that simplifies communication with Large Language Model (LLM) inference servers supporting OpenAI-compatible Responses endpoints.

## Overview

SwiftResponsesDSL provides a type-safe, declarative API for interacting with LLM APIs. Built on Swift's powerful type system and result builders, it offers:

- **Type-Safe Interactions**: Compile-time validation prevents common API errors
- **Declarative Syntax**: Natural language-like syntax using Swift's result builders
- **Multimodal Support**: Handle text, images, files, and other content types
- **Tool Integration**: Built-in support for function calling and external tools
- **Conversation Management**: Seamless handling of multi-turn conversations
- **Streaming Responses**: Real-time response processing with async/await
- **Comprehensive Error Handling**: Detailed error types with recovery suggestions

## Key Features

### Declarative API Design

SwiftResponsesDSL uses Swift's result builder pattern to provide a natural, declarative syntax:

```swift
let client = try LLMClient(baseURLString: "https://api.openai.com/v1/responses")

let response = try await client.respond(to: ResponseRequest(
    model: "gpt-4",
    config: {
        Temperature(0.7)
        MaxOutputTokens(500)
        TopP(0.9)
    },
    input: {
        system("You are a helpful assistant")
        user("Explain quantum computing in simple terms")
    }
))
```

### Type-Safe Configuration

All configuration parameters are strongly typed with compile-time validation:

```swift
// ✅ Compile-time validation prevents invalid values
let temp = try Temperature(0.7)    // Valid: 0.0...2.0
let tokens = try MaxOutputTokens(100)  // Valid: 1...4096

// ❌ This would not compile:
// let invalidTemp = try Temperature(5.0)  // Error: Outside valid range
```

### Multimodal Content Support

Handle diverse content types seamlessly:

```swift
let multimodalMessage = UserMessage(content: [
    .text("What's in this image?"),
    .imageUrl(url: "https://example.com/image.jpg", detail: .high),
    .text("Please describe it in detail.")
])
```

### Tool Integration

Built-in support for function calling and external tools:

```swift
let tools = try Tools([
    Tool(type: .function, function: Tool.Function(
        name: "get_weather",
        description: "Get current weather",
        parameters: .object([
            "location": .string(description: "City name")
        ])
    ))
])

let request = try ResponseRequest(
    model: "gpt-4",
    input: { user("What's the weather in San Francisco?") },
    tools: tools
)
```

## Getting Started

### Installation

Add SwiftResponsesDSL to your Swift Package:

```swift
dependencies: [
    .package(url: "https://github.com/RichNasz/SwiftResponsesDSL.git", from: "1.0.0")
]
```

### Basic Usage

```swift
import SwiftResponsesDSL

// Create a client
let client = try LLMClient(baseURLString: "https://api.openai.com/v1/responses")

// Make a simple request
let response = try await client.chat(
    model: "gpt-4",
    message: "Hello, how are you?"
)

// Handle the response
if let message = response.choices.first?.message.content {
    print("🤖 Assistant: \(message)")
}
```

### Streaming Responses

```swift
let stream = client.stream(request: request)
for try await event in stream {
    switch event {
    case .outputItemAdded(let item):
        if case .message(let message) = item,
           let content = message.content {
            print(content, terminator: "")
        }
    case .completed:
        print("\n✅ Response completed!")
    }
}
```

## Architecture

SwiftResponsesDSL is built on several key architectural patterns:

### Result Builder Pattern
The DSL uses Swift's `@resultBuilder` to provide declarative syntax that compiles to efficient, type-safe code.

### Actor-Based Concurrency
Network operations are handled by Swift actors, ensuring thread-safe concurrent access.

### Protocol-Oriented Design
Extensible protocols allow for custom implementations while maintaining type safety.

### Comprehensive Error Handling
Detailed error types provide specific information about failures and recovery options.

## Learn More About

@Links(visualStyle: detailedGrid) {
    - <doc:DSL.md>
    - <doc:Usage.md>
    - <doc:Architecture.md>
}

## Topics

### Essentials
- ``LLMClient``
- ``ResponseRequest``
- ``ResponseMessage``
- ``Role``

### Configuration
- ``ResponseConfigParameter``
- ``Temperature``
- ``TopP``
- ``MaxOutputTokens``
- ``FrequencyPenalty``
- ``PresencePenalty``

### Messages
- ``SystemMessage``
- ``UserMessage``
- ``AssistantMessage``
- ``ContentPart``

### Tools & Functions
- ``Tool``
- ``ToolChoice``
- ``MaxToolCalls``

### Error Handling
- ``LLMError``
- ``Annotation``

### Advanced Features
- ``ResponseConversation``
- ``StreamOptions``
- ``AnyCodable``

## See Also

### Articles
- <doc:DSL.md> - Comprehensive guide to the Domain Specific Language
- <doc:Usage.md> - Practical examples and usage patterns
- <doc:Architecture.md> - Technical architecture and design

### Related Documentation
- [OpenAI API Documentation](https://platform.openai.com/docs)
- [Swift Language Guide](https://docs.swift.org/swift-book/)
- [Swift Package Manager](https://swift.org/package-manager/)

---

SwiftResponsesDSL makes LLM integration simple, safe, and powerful. Whether you're building a simple chatbot or a complex AI-powered application, SwiftResponsesDSL provides the tools you need for reliable, type-safe LLM interactions.
