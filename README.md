# SwiftResponsesDSL

![Swift](https://img.shields.io/badge/Swift-6.2+-orange.svg)
![macOS](https://img.shields.io/badge/macOS-12+-blue.svg)
![iOS](https://img.shields.io/badge/iOS-15+-blue.svg)
![Linux](https://img.shields.io/badge/Linux-Ubuntu_22.04+-blue.svg)
![CI](https://github.com/RichNasz/SwiftResponsesDSL/workflows/CI/badge.svg)
![Documentation](https://github.com/RichNasz/SwiftResponsesDSL/workflows/Documentation/badge.svg)

## Overview

**SwiftResponsesDSL** is an embedded Swift Domain-Specific Language (DSL) that simplifies communication with Large Language Model (LLM) inference servers supporting OpenAI-compatible Responses endpoints. It provides a type-safe, declarative API using Swift's powerful type system and result builders.

### What is a DSL?

A **Domain Specific Language** is a specialized programming language designed for a specific problem domain. SwiftResponsesDSL transforms complex LLM API interactions into natural, readable Swift code that expresses your intent clearly and safely.

**Traditional API approach:**
```swift
let messages = [["role": "system", "content": "You are helpful"], ["role": "user", "content": "Hello"]]
let params = ["model": "gpt-4", "messages": messages, "temperature": 0.7]
let response = try await api.send(params) // Manual JSON, error-prone
```

**SwiftResponsesDSL approach:**
```swift
let response = try await client.respond(to: ResponseRequest(
    model: "gpt-4",
    config: { Temperature(0.7) },
    input: {
        system("You are helpful")
        user("Hello")
    }
))
```

## Quick Start

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

// Simple chat
let response = try await client.chat(
    model: "gpt-4",
    message: "Hello! Can you help me learn Swift?"
)

if let message = response.choices.first?.message.content {
    print("🤖 Assistant: \(message)")
}
```

### Your First Response

Here's the minimal code to get started:

```swift
import SwiftResponsesDSL

// 1. Create client with your API endpoint
let client = try LLMClient(baseURLString: "https://api.openai.com/v1/responses")

// 2. Send a message and get response
let response = try await client.chat(model: "gpt-4", message: "Hello!")

// 3. Use the response
print(response.choices.first?.message.content ?? "No response")
```

That's it! You've successfully integrated with an LLM API using SwiftResponsesDSL.

## Usage Examples

### 🎯 Basic Chat (Your First Conversation)

```swift
import SwiftResponsesDSL

// Create your AI assistant
let client = try LLMClient(
    baseURLString: "https://api.openai.com/v1/responses",
    apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!
)

// Start a conversation
let response = try await client.respond(to: ResponseRequest(
    model: "gpt-4",
    input: {
        system("You are a friendly and knowledgeable AI assistant.")
        user("What's the most important concept in programming?")
    }
))

print("🤖 Assistant:", response.choices.first?.message.content ?? "")
```

### 🎨 Content Generation (Creative Writing)

```swift
// Generate creative content with specific style
let story = try await client.respond(to: ResponseRequest(
    model: "gpt-4",
    config: {
        Temperature(0.9)        // High creativity
        MaxOutputTokens(800)    // Allow longer content
        TopP(0.95)             // Diverse word choices
    },
    input: {
        system("You are a creative storyteller who writes engaging narratives.")
        user("Write a short story about a robot learning to paint")
    }
))

if let content = story.choices.first?.message.content {
    print("🎨 Generated Story:")
    print(content)
}
```

### 📚 Educational Assistant (Smart Tutoring)

```swift
// Create an intelligent tutoring system
let lesson = try await client.respond(to: ResponseRequest(
    model: "gpt-4",
    config: {
        Temperature(0.3)        // Factual and educational
        MaxOutputTokens(1000)   // Comprehensive explanations
    },
    input: {
        system("""
        You are an expert programming tutor who explains concepts clearly.
        Break down complex topics into simple, understandable parts.
        Include practical examples and encourage questions.
        """)
        user("Explain how closures work in Swift with examples")
    }
))

print("👨‍🏫 Tutor:", lesson.choices.first?.message.content ?? "")
```

### 🔧 Tool Integration (AI with Superpowers)

```swift
// Give AI access to external tools
let tools = try Tools([
    Tool(type: "function", function: Tool.Function(
        name: "calculate",
        description: "Perform mathematical calculations",
        parameters: [
            "expression": .string(description: "Math expression to evaluate")
        ]
    )),
    Tool(type: "function", function: Tool.Function(
        name: "get_weather",
        description: "Get current weather for a location",
        parameters: [
            "location": .string(description: "City name")
        ]
    ))
])

let smartResponse = try await client.respond(to: ResponseRequest(
    model: "gpt-4",
    config: {
        ToolChoice("auto")      // Let AI decide when to use tools
        MaxToolCalls(3)         // Allow multiple tool uses
    },
    input: {
        system("You are a helpful assistant with access to tools.")
        user("What's 15 × 23 and what's the weather like in San Francisco?")
    },
    tools: tools
))

print("🛠️ Smart Assistant:", smartResponse.choices.first?.message.content ?? "")
```

### 🌊 Real-Time Streaming (Live Interaction)

```swift
// Experience real-time AI responses
let streamRequest = ResponseRequest(
    model: "gpt-4",
    config: {
        Temperature(0.8)
        StreamOptions(["include_usage": true])
    },
    input: {
        user("Write a haiku about programming, word by word")
    }
)

print("📝 Live Writing: ", terminator: "")
let stream = client.stream(request: streamRequest)

for try await event in stream {
    switch event {
    case .outputItemAdded(let item):
        if case .message(let message) = item,
           let content = message.content {
            // Show each word as it's generated
            print(content, terminator: "")
            fflush(stdout)
            // Add dramatic pauses for effect
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    case .completed(let response):
        print("\n✅ Poem complete!")
        if let usage = response.usage {
            print("📊 Tokens used: \(usage.totalTokens)")
        }
    }
}
```

### Advanced Configuration

```swift
let request = ResponseRequest(
    model: "gpt-4",
    config: {
        Temperature(0.3)        // Factual and precise
        MaxOutputTokens(500)    // Allow detailed response
        TopP(0.9)              // Balanced sampling
        FrequencyPenalty(0.1)   // Reduce repetition
        PresencePenalty(0.1)    // Encourage topic diversity
    },
    input: {
        system("You are an expert technical writer")
        user("Explain how machine learning works")
    }
)
```

### Conversation Management

```swift
var conversation = ResponseConversation()

// Set up AI personality
conversation.append(system: "You are a patient coding mentor")

// First exchange
conversation.append(user: "How do I declare a variable in Swift?")
let response1 = try await client.chat(conversation: conversation)
conversation.append(response: response1)

// Continue conversation
conversation.append(user: "What about constants?")
let response2 = try await client.chat(conversation: conversation)

print("First answer:", response1.choices.first?.message.content ?? "")
print("Follow-up:", response2.choices.first?.message.content ?? "")
```

### Multimodal Content

```swift
let multimodalRequest = ResponseRequest(
    model: "gpt-4-vision-preview",
    input: {
        user([
            .text("What's in this image? Describe the main subjects and mood."),
            .imageUrl(url: "https://example.com/photo.jpg", detail: .high),
            .text("What emotions does this image convey?")
        ])
    }
)

let analysis = try await client.respond(to: multimodalRequest)
```

### Tool Integration

```swift
let tools = try Tools([
    Tool(type: .function, function: Tool.Function(
        name: "calculate",
        description: "Perform mathematical calculations",
        parameters: .object([
            "expression": .string(description: "Math expression to evaluate")
        ])
    ))
])

let toolRequest = ResponseRequest(
    model: "gpt-4",
    config: {
        ToolChoice("auto")      // Let AI decide when to use tools
        MaxToolCalls(3)         // Allow up to 3 tool calls
    },
    input: {
        user("What's 15 × 23 + 7?")
    },
    tools: tools
)

let result = try await client.respond(to: toolRequest)
```

## Documentation Links

### 📚 Complete Documentation
- **[Generated DocC Documentation](https://richnasz.github.io/SwiftResponsesDSL/)** - Comprehensive API reference
- **[DSL Guide](./Sources/SwiftResponsesDSL/SwiftResponsesDSL.docc/DSL.md)** - Learn DSL concepts from basics to advanced
- **[Usage Examples](./Sources/SwiftResponsesDSL/SwiftResponsesDSL.docc/Usage.md)** - Practical examples for all skill levels
- **[Architecture Guide](./Sources/SwiftResponsesDSL/SwiftResponsesDSL.docc/Architecture.md)** - Technical deep-dive

### 📖 Learning Resources
- **[Examples Folder](./Examples/)** - 16 example categories with runnable code
- **[Basic Examples](./Examples/Basic/)** - Get started with fundamental patterns
- **[Intermediate Examples](./Examples/Intermediate/)** - Advanced features and integrations
- **[Advanced Examples](./Examples/Advanced/)** - Enterprise patterns and custom extensions

## Requirements

### Swift 6.2 Toolchain Setup

SwiftResponsesDSL requires **Swift 6.2 or later**. Choose your setup based on your development environment:

#### For Xcode Users (macOS)
```bash
# Requires Xcode 26+ (currently in beta)
# Download from: https://developer.apple.com/xcode/
xcode-select --install  # Install command line tools
xcodebuild -version     # Verify Xcode version
```

**Xcode Version Requirements:**
- **Xcode 26.0+** - Full Swift 6.2 support (currently beta)
- **Minimum macOS**: 14.0+ (Sonoma) for Xcode 26

#### For Command Line / CI Users
```bash
# Install Swiftly (Swift toolchain manager)
curl -L https://github.com/swiftlang/swiftly/releases/latest/download/swiftly-install.sh | bash
source ~/.swiftly/env.sh

# Install Swift 6.2 toolchain
swiftly install 6.2

# Set as default
swiftly use 6.2

# Verify installation
swift --version  # Should show Swift 6.2.x
```

#### For Linux Users
```bash
# Ubuntu/Debian
wget https://swift.org/builds/swift-6.2-release/ubuntu2204/swift-6.2-RELEASE/swift-6.2-RELEASE-ubuntu22.04.tar.gz
tar xzf swift-6.2-RELEASE-ubuntu22.04.tar.gz
export PATH=$(pwd)/swift-6.2-RELEASE-ubuntu22.04/usr/bin:$PATH

# Verify
swift --version
```

#### For CI/CD Pipelines
```yaml
# GitHub Actions example
- name: Setup Swift
  uses: swift-actions/setup-swift@v2
  with:
    swift-version: '6.2'

# Or with Swiftly
- name: Setup Swiftly
  run: |
    curl -L https://github.com/swiftlang/swiftly/releases/latest/download/swiftly-install.sh | bash
    source ~/.swiftly/env.sh
    swiftly install 6.2
    swiftly use 6.2
```

### System Requirements
- **Platforms**:
  - macOS 12.0+
  - iOS 15.0+
  - Linux (Ubuntu 22.04+)
- **Memory**: 4GB+ RAM recommended
- **Storage**: 2GB+ free space for toolchain and dependencies

### Dependencies
- **Foundation** (built-in) - Core iOS/macOS framework
- **Swift Standard Library** (built-in) - Core Swift functionality

### API Requirements
- **OpenAI-compatible API** - REST API supporting chat completions
- **API Key** - Valid authentication credentials
- **Network Access** - HTTPS connectivity to API endpoints

## API Reference

### Core Components

| Component | Description |
|-----------|-------------|
| `LLMClient` | Main API client for LLM interactions |
| `ResponseRequest` | Structured request with model, config, and input |
| `Response` | API response with choices, usage, and metadata |
| `ResponseMessage` | Protocol for all message types |
| `ResponseConfigParameter` | Protocol for configuration parameters |

### Message Types

| Type | Purpose |
|------|---------|
| `SystemMessage` | Set AI personality and context |
| `UserMessage` | User input and queries |
| `AssistantMessage` | AI-generated responses |
| `ToolMessage` | Tool execution results |

### Configuration Parameters

| Parameter | Purpose | Range |
|-----------|---------|-------|
| `Temperature` | Control response creativity | 0.0 - 2.0 |
| `TopP` | Nucleus sampling diversity | 0.0 - 1.0 |
| `MaxOutputTokens` | Response length limit | 1+ |
| `FrequencyPenalty` | Reduce token repetition | -2.0 - 2.0 |
| `PresencePenalty` | Encourage topic diversity | -2.0 - 2.0 |

### Advanced Features

| Feature | Description |
|---------|-------------|
| **Streaming** | Real-time response generation |
| **Tool Calling** | Function execution by LLM |
| **Multimodal** | Text, images, and files |
| **Conversations** | Multi-turn dialogue management |
| **Error Handling** | Comprehensive error classification |

## Troubleshooting

### Common Issues

#### API Connection Problems
```swift
// Problem: Invalid API key
catch LLMError.authenticationFailed {
    print("Check your API key configuration")
}

// Problem: Network timeout
catch LLMError.timeout {
    print("Check network connectivity")
    // Consider retry with backoff
}
```

#### Configuration Errors
```swift
// Problem: Invalid temperature
do {
    _ = try Temperature(5.0)  // Will throw
} catch LLMError.invalidValue(let message) {
    print("Fix parameter:", message)
}
```

#### Rate Limiting
```swift
// Problem: Too many requests
catch LLMError.rateLimit {
    print("Rate limit exceeded - wait before retrying")
    try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
}
```

### Debug Mode

Enable detailed logging for troubleshooting:

```swift
// Set environment variable for debug output
setenv("SWIFT_RESPONSES_DSL_DEBUG", "1", 1)

// Or configure client with debug options
let client = try LLMClient(
    baseURLString: "https://api.openai.com/v1/responses",
    debugMode: true
)
```

### Logging and Diagnostics

SwiftResponsesDSL integrates with system logging:

```swift
import os.log

// Log levels
os_log(.info, "Starting LLM request")
os_log(.error, "Request failed: %{public}@", error.localizedDescription)
os_log(.debug, "Response received with %{public}d tokens", usage.totalTokens)
```

## Community and Support

### GitHub
- **Repository**: https://github.com/RichNasz/SwiftResponsesDSL
- **Issues**: https://github.com/RichNasz/SwiftResponsesDSL/issues
- **Pull Requests**: https://github.com/RichNasz/SwiftResponsesDSL/pulls
- **Discussions**: https://github.com/RichNasz/SwiftResponsesDSL/discussions

### Communication
- **Stack Overflow**: Tag `[swift-responses-dsl]` for questions
- **Security Issues**: https://github.com/RichNasz/SwiftResponsesDSL/security/advisories

## Changelog

### [Latest Changes]
- **Enhanced Documentation**: Comprehensive guides and examples
- **Improved Error Handling**: Better error classification and recovery
- **Performance Optimizations**: Streaming and batching improvements
- **New Features**: Tool integration and multimodal support

### Migration Notes
- **Version 1.0.0**: Initial release with core functionality
- **Breaking Changes**: Check migration guides for API updates

### Full Changelog
[View complete changelog](https://github.com/RichNasz/SwiftResponsesDSL/blob/main/CHANGELOG.md)

## Contributing and License

### How to Contribute

We welcome contributions! Here's how to get involved:

1. **Fork** the repository
2. **Create** a feature branch
3. **Make** your changes
4. **Add tests** for new functionality
5. **Submit** a pull request

### Development Setup

```bash
# Clone the repository
git clone https://github.com/RichNasz/SwiftResponsesDSL.git
cd SwiftResponsesDSL

# Run tests
swift test

# Generate documentation
swift package generate-documentation

# Build examples
cd Examples/Basic
swift run
```

### Code of Conduct
This project follows a code of conduct to ensure a welcoming environment for all contributors. See [CODE_OF_CONDUCT.md](https://github.com/RichNasz/SwiftResponsesDSL/blob/main/CODE_OF_CONDUCT.md) for details.

### License
SwiftResponsesDSL is released under the MIT License. See [LICENSE](https://github.com/RichNasz/SwiftResponsesDSL/blob/main/LICENSE) for details.

---

**SwiftResponsesDSL** makes LLM integration simple, safe, and powerful. Whether you're building a chatbot, content generator, or complex AI-powered application, SwiftResponsesDSL provides the perfect balance of expressiveness and reliability.

🚀 **Ready to get started?** Check out the [DSL Guide](./Sources/SwiftResponsesDSL/SwiftResponsesDSL.docc/DSL.md) and explore the [Examples](./Examples/)!

*Built with ❤️ using Swift's powerful type system and modern concurrency features.*
