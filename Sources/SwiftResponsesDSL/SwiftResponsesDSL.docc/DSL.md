# Domain Specific Language Guide

@Metadata {
    @DisplayName("DSL Guide")
    @PageKind(article)
}

Welcome to the SwiftResponsesDSL Domain Specific Language (DSL) Guide! This comprehensive guide will take you from zero knowledge of DSLs to confidently using SwiftResponsesDSL in your projects.

## What is a DSL?

A **Domain Specific Language** (DSL) is a specialized programming language designed for a specific problem domain. Unlike general-purpose languages like Swift, DSLs are tailored to make certain tasks easier and more expressive.

### Why DSLs Matter

Imagine trying to build a house with only a general toolbox versus having specialized tools for each task. DSLs are the specialized tools of programming!

**Without DSLs** (Traditional API):
```swift
let request = APIRequest(endpoint: "/chat/completions")
request.setMethod(.post)
request.setHeader("Authorization", "Bearer \(apiKey)")
request.setBody([
    "model": "gpt-4",
    "messages": [
        ["role": "system", "content": "You are helpful"],
        ["role": "user", "content": "Hello"]
    ]
])
let response = try await client.send(request)
```

**With DSLs** (SwiftResponsesDSL):
```swift
let response = try await client.respond(to: ResponseRequest(
    model: "gpt-4",
    input: {
        system("You are helpful")
        user("Hello")
    }
))
```

The DSL version is:
- ✅ More readable and natural
- ✅ Type-safe with compile-time validation
- ✅ Less error-prone
- ✅ Easier to maintain

## DSL Concepts in SwiftResponsesDSL

### 1. Declarative vs Imperative

**Imperative** (telling the computer "how" to do something):
```swift
// Step-by-step instructions
var messages: [[String: String]] = []
messages.append(["role": "system", "content": "You are helpful"])
messages.append(["role": "user", "content": "Hello"])
let request = ["model": "gpt-4", "messages": messages]
```

**Declarative** (telling the computer "what" you want):
```swift
// Describe the desired outcome
let request = ResponseRequest(
    model: "gpt-4",
    input: {
        system("You are helpful")
        user("Hello")
    }
)
```

### 2. Result Builders

SwiftResponsesDSL uses Swift's `@resultBuilder` feature to create natural syntax. The `input` parameter accepts a closure that uses special syntax:

```swift
input: {
    system("You are helpful")        // System message
    user("Hello")                    // User message
    assistant("Hi there!")           // Assistant message
}
```

This is converted at compile-time into a properly structured array of messages.

## Your First DSL Request

Let's build your first SwiftResponsesDSL request step by step:

### Step 1: Basic Setup

```swift
import SwiftResponsesDSL

// Create your LLM client
let client = try LLMClient(baseURLString: "https://api.openai.com/v1/responses")

// Your first request!
let response = try await client.chat(
    model: "gpt-4",
    message: "Hello, SwiftResponsesDSL!"
)

print(response.choices.first?.message.content ?? "No response")
```

### Step 2: Adding Configuration

```swift
let response = try await client.respond(to: ResponseRequest(
    model: "gpt-4",
    config: {
        Temperature(0.7)        // Control creativity (0.0 = focused, 2.0 = creative)
        MaxOutputTokens(150)    // Limit response length
    },
    input: {
        system("You are a friendly assistant")
        user("Tell me about Swift programming")
    }
))
```

### Step 3: Understanding the Parts

```swift
ResponseRequest(           // The main request object
    model: "gpt-4",        // Which AI model to use
    config: {              // Configuration parameters
        Temperature(0.7)    // How creative/random the response should be
        MaxOutputTokens(150) // Maximum length of response
    },
    input: {               // The conversation messages
        system("You are a friendly assistant")  // AI's personality/context
        user("Tell me about Swift programming") // Your message
    }
)
```

## Common DSL Patterns

### Simple Q&A

```swift
let answer = try await client.chat(
    model: "gpt-4",
    message: "What is the capital of France?"
)
// Result: "The capital of France is Paris."
```

### Conversational AI

```swift
let response = try await client.respond(to: ResponseRequest(
    model: "gpt-4",
    input: {
        system("You are a helpful programming tutor")
        user("How do I create a function in Swift?")
    }
))
```

### Creative Writing

```swift
let story = try await client.respond(to: ResponseRequest(
    model: "gpt-4",
    config: {
        Temperature(0.9)        // High creativity
        MaxOutputTokens(300)    // Allow longer responses
    },
    input: {
        system("You are a creative storyteller")
        user("Write a short story about a robot who falls in love")
    }
))
```

### Technical Analysis

```swift
let analysis = try await client.respond(to: ResponseRequest(
    model: "gpt-4",
    config: {
        Temperature(0.1)        // Low creativity (factual)
        MaxOutputTokens(500)    // Allow detailed analysis
    },
    input: {
        system("You are a technical analyst specializing in code review")
        user("Analyze this Swift code for potential improvements: \(codeSnippet)")
    }
))
```

## Advanced DSL Features

### Streaming Responses

For real-time responses, use streaming:

```swift
let request = ResponseRequest(
    model: "gpt-4",
    input: { user("Write a poem about programming") }
)

let stream = client.stream(request: request)
for try await event in stream {
    switch event {
    case .outputItemAdded(let item):
        if case .message(let message) = item,
           let content = message.content {
            print(content, terminator: "")  // Print as it arrives
        }
    case .completed:
        print("\n✅ Poem complete!")
    }
}
```

### Conversation Management

Maintain context across multiple exchanges:

```swift
var conversation = ResponseConversation()

// First exchange
conversation.append(system: "You are a math tutor"))
conversation.append(user: "What is 2 + 2?")
let response1 = try await client.chat(conversation: conversation)
conversation.append(response: response1)

// Continue the conversation
conversation.append(user: "Now what about 3 × 4?")
let response2 = try await client.chat(conversation: conversation)
```

### Error Handling

The DSL provides comprehensive error handling:

```swift
do {
    let response = try await client.chat(model: "gpt-4", message: "Hello")
} catch LLMError.invalidValue(let message) {
    print("Configuration error: \(message)")
} catch LLMError.networkError(let message) {
    print("Network error: \(message)")
} catch {
    print("Other error: \(error.localizedDescription)")
}
```

## DSL Best Practices

### 1. Keep It Simple

```swift
// ✅ Good: Simple and clear
let response = try await client.chat(
    model: "gpt-4",
    message: "Hello"
)

// ❌ Avoid: Over-complicated
let response = try await client.respond(to: ResponseRequest(
    model: "gpt-4",
    config: { Temperature(0.7) },
    input: { user("Hello") }
))
```

### 2. Use Appropriate Configuration

```swift
// For creative tasks
config: {
    Temperature(0.9)        // High creativity
    TopP(0.95)             // Diverse token selection
}

// For factual/analytical tasks
config: {
    Temperature(0.1)        // Low creativity (factual)
    MaxOutputTokens(1000)   // Allow detailed responses
}
```

### 3. Structure Your Messages

```swift
input: {
    system("You are an expert in \(domain)")
    user("Please help me with: \(specificQuestion)")
    // Add context or examples if needed
}
```

### 4. Handle Errors Gracefully

```swift
do {
    let response = try await client.chat(model: "gpt-4", message: prompt)
    // Process successful response
} catch LLMError.rateLimit {
    // Wait and retry
    try await Task.sleep(nanoseconds: 1_000_000_000)
    // Retry logic here
} catch LLMError.networkError {
    // Handle network issues
    showOfflineMessage()
}
```

## Common DSL Mistakes and Solutions

### Mistake 1: Forgetting System Messages

```swift
// ❌ Bad: No context
input: {
    user("What should I eat for lunch?")
}

// ✅ Good: Provide context
input: {
    system("You are a nutritionist specializing in healthy eating")
    user("What should I eat for lunch?")
}
```

### Mistake 2: Over-configuring

```swift
// ❌ Bad: Too many conflicting parameters
config: {
    Temperature(0.1)        // Very focused
    TopP(0.95)             // Very diverse (conflicts!)
    FrequencyPenalty(2.0)   // Very restrictive
}

// ✅ Good: Thoughtful configuration
config: {
    Temperature(0.7)        // Balanced
    MaxOutputTokens(300)    // Reasonable length
}
```

### Mistake 3: Ignoring Error Handling

```swift
// ❌ Bad: No error handling
let response = try await client.chat(model: "gpt-4", message: "Hello")

// ✅ Good: Proper error handling
do {
    let response = try await client.chat(model: "gpt-4", message: "Hello")
    // Process response
} catch {
    // Handle error
    showError(error.localizedDescription)
}
```

## DSL vs Traditional APIs

### Traditional API Approach

```swift
// Manual JSON construction
let messages = [
    ["role": "system", "content": "You are helpful"],
    ["role": "user", "content": "Hello"]
]

let parameters: [String: Any] = [
    "model": "gpt-4",
    "messages": messages,
    "temperature": 0.7,
    "max_tokens": 150
]

// Manual HTTP request
let jsonData = try JSONSerialization.data(withJSONObject: parameters)
var request = URLRequest(url: apiURL)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
request.httpBody = jsonData

// Manual response handling
let (data, response) = try await URLSession.shared.data(for: request)
// Manual JSON parsing...
```

### DSL Approach

```swift
// Natural, type-safe syntax
let response = try await client.respond(to: ResponseRequest(
    model: "gpt-4",
    config: {
        Temperature(0.7)
        MaxOutputTokens(150)
    },
    input: {
        system("You are helpful")
        user("Hello")
    }
))

// Automatic JSON serialization, HTTP handling, and error management
let message = response.choices.first?.message.content
```

## Performance Considerations

### Efficient Configuration

```swift
// ✅ Good: Reuse configurations
let standardConfig = {
    Temperature(0.7)
    MaxOutputTokens(300)
    TopP(0.9)
}

let response1 = try await client.respond(to: ResponseRequest(
    model: "gpt-4",
    config: standardConfig,
    input: { user("First question") }
))

let response2 = try await client.respond(to: ResponseRequest(
    model: "gpt-4",
    config: standardConfig,
    input: { user("Second question") }
))
```

### Streaming for Large Responses

```swift
// ✅ Good: Use streaming for large responses
let request = ResponseRequest(
    model: "gpt-4",
    config: { MaxOutputTokens(2000) },  // Large response
    input: { user("Write a detailed analysis...") }
)

let stream = client.stream(request: request)
// Process chunks as they arrive (better perceived performance)
```

## Next Steps

Now that you understand the basics of SwiftResponsesDSL, here are some next steps:

### 1. Explore Advanced Features
- **Tool Integration**: Learn about function calling
- **Multimodal Content**: Work with images and files
- **Custom Parameters**: Create domain-specific configurations

### 2. Study Real Examples
Check out the `Examples/` folder for comprehensive examples:
- `Basic/` - Fundamental usage patterns
- `Intermediate/` - Advanced features and integrations
- `Advanced/` - Enterprise patterns and custom extensions

### 3. Best Practices
- Always handle errors appropriately
- Use appropriate temperature settings for your use case
- Provide clear system messages for context
- Consider streaming for better user experience

### 4. Integration Patterns
- **Web Applications**: REST API endpoints
- **Mobile Apps**: User interface integration
- **Command-Line Tools**: Interactive assistants
- **Microservices**: AI-powered services

## Summary

SwiftResponsesDSL's Domain Specific Language makes LLM integration:

- **Simple**: Natural, readable syntax
- **Safe**: Type-safe with compile-time validation
- **Powerful**: Access to all advanced features
- **Maintainable**: Clear, self-documenting code
- **Flexible**: Adapts to your specific needs

The DSL approach transforms complex API interactions into simple, expressive code that reads like natural language. Whether you're building a simple chatbot or a complex AI-powered application, SwiftResponsesDSL provides the perfect balance of power and simplicity.

Happy coding with SwiftResponsesDSL! 🚀
