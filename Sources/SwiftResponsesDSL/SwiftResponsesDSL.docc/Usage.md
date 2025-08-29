# Usage Examples

@Metadata {
    @DisplayName("Usage Examples")
    @PageKind(article)
}

This guide provides practical examples of SwiftResponsesDSL usage across different experience levels, from basic interactions to advanced integrations.

## For Beginners

If you're new to SwiftResponsesDSL or LLMs, start here with simple, non-technical examples.

### Your First Chat

The simplest way to get started:

```swift
import SwiftResponsesDSL

// Create a client (replace with your API endpoint)
let client = try LLMClient(baseURLString: "https://api.openai.com/v1/responses")

// Have a simple conversation
let response = try await client.chat(
    model: "gpt-4",
    message: "Hello! Can you tell me what SwiftResponsesDSL is?"
)

if let message = response.choices.first?.message.content {
    print("🤖 Assistant: \(message)")
}
```

**What this does:**
- Creates a connection to your LLM API
- Sends a simple text message
- Receives and displays the response
- Handles everything automatically!

### Basic Q&A

Ask questions and get answers:

```swift
// Simple questions
let answers = try await client.chat(
    model: "gpt-4",
    message: "What is the capital of France?"
)
// Expected: "The capital of France is Paris."

let explanation = try await client.chat(
    model: "gpt-4",
    message: "Explain photosynthesis in simple terms"
)
// Expected: Clear, simple explanation of the process
```

### Creative Tasks

Generate creative content:

```swift
let story = try await client.chat(
    model: "gpt-4",
    message: "Write a haiku about programming"
)
// Expected: A short, creative poem about coding
```

## Intermediate Usage

Once you're comfortable with basics, explore more features.

### Adding Context (System Messages)

Provide personality and context:

```swift
let response = try await client.respond(to: ResponseRequest(
    model: "gpt-4",
    input: {
        system("You are a friendly programming tutor who explains concepts clearly")
        user("What is recursion?")
    }
))
// The AI will respond as a programming tutor
```

### Controlling Response Style

Use configuration parameters:

```swift
let creativeResponse = try await client.respond(to: ResponseRequest(
    model: "gpt-4",
    config: {
        Temperature(0.9)        // High creativity
        MaxOutputTokens(100)    // Keep it short
    },
    input: {
        user("Write a creative story about a cat who codes")
    }
))

let factualResponse = try await client.respond(to: ResponseRequest(
    model: "gpt-4",
    config: {
        Temperature(0.1)        // Low creativity (factual)
        MaxOutputTokens(200)    // Allow detailed response
    },
    input: {
        user("Explain how a computer works")
    }
))
```

### Multiple Messages

Have back-and-forth conversations:

```swift
let conversation = ResponseRequest(
    model: "gpt-4",
    input: {
        system("You are a helpful assistant")
        user("What is the weather like?")
        assistant("I don't have access to current weather data, but I can help you find weather information!")
        user("How can I check the weather?")
    }
)

let response = try await client.respond(to: conversation)
```

## Advanced Examples

For experienced developers building complex applications.

### Streaming Responses

Get responses in real-time:

```swift
let request = ResponseRequest(
    model: "gpt-4",
    config: {
        Temperature(0.7)
        MaxOutputTokens(500)
        StreamOptions(["include_usage": true])
    },
    input: {
        user("Write a detailed explanation of machine learning")
    }
)

print("🤖 Assistant: ", terminator: "")

let stream = client.stream(request: request)
for try await event in stream {
    switch event {
    case .outputItemAdded(let item):
        if case .message(let message) = item,
           let content = message.content {
            print(content, terminator: "")
            fflush(stdout)  // Show content immediately
        }

    case .completed(let response):
        print("\n✅ Response complete!")

        if let usage = response.usage {
            print("📊 Tokens used: \(usage.totalTokens)")
            print("💰 Cost estimate: $\(Double(usage.totalTokens) * 0.00003)")
        }

    case .created:
        print("(Thinking...) ", terminator: "")

    default:
        break
    }
}
```

### Conversation Management

Maintain context across multiple interactions:

```swift
// Create a conversation
var conversation = ResponseConversation()

// Set up the AI's role
conversation.append(system: "You are an expert Swift developer helping with code reviews")

// First interaction
conversation.append(user: "Can you review this Swift function?")
let codeSnippet = """
func calculateAverage(_ numbers: [Double]) -> Double {
    var sum = 0.0
    for number in numbers {
        sum += number
    }
    return sum / Double(numbers.count)
}
"""
conversation.append(user: codeSnippet)

let firstResponse = try await client.chat(conversation: conversation)
conversation.append(response: firstResponse)

// Continue the conversation
conversation.append(user: "How can I make it more efficient?")
let followUpResponse = try await client.chat(conversation: conversation)

print("🤖 First review: \(firstResponse.choices.first?.message.content ?? "")")
print("🤖 Efficiency suggestions: \(followUpResponse.choices.first?.message.content ?? "")")
```

### Multimodal Content

Work with images and text together:

```swift
let multimodalRequest = ResponseRequest(
    model: "gpt-4-vision-preview",
    input: {
        user([
            .text("What's in this image? Please describe it in detail."),
            .imageUrl(url: "https://example.com/photo.jpg", detail: .high),
            .text("What emotions or mood does this image convey?")
        ])
    }
)

let analysis = try await client.respond(to: multimodalRequest)
if let description = analysis.choices.first?.message.content {
    print("🖼️ Image Analysis: \(description)")
}
```

### Tool Integration

Add external tools and functions:

```swift
// Define tools
let tools = try Tools([
    Tool(type: .function, function: Tool.Function(
        name: "get_weather",
        description: "Get current weather for a location",
        parameters: .object([
            "location": .string(description: "City and country"),
            "unit": .string(
                description: "Temperature unit",
                enum: ["celsius", "fahrenheit"]
            )
        ])
    )),
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
        user("What's the weather in San Francisco and what's 15 * 23?")
    },
    tools: tools
)

let toolResponse = try await client.respond(to: toolRequest)

// The AI might use tools to get weather data and calculate the math
if let answer = toolResponse.choices.first?.message.content {
    print("🤖 Answer with tool usage: \(answer)")
}
```

### Error Handling Patterns

Robust error handling for production:

```swift
do {
    let response = try await client.chat(model: "gpt-4", message: "Hello")
    print("✅ Success: \(response.choices.first?.message.content ?? "")")

} catch LLMError.invalidValue(let message) {
    print("❌ Configuration Error: \(message)")
    print("💡 Check your parameter values (temperature, token limits, etc.)")

} catch LLMError.networkError(let message) {
    print("❌ Network Error: \(message)")
    print("💡 Check your internet connection and API endpoint")

} catch LLMError.rateLimit {
    print("❌ Rate Limit Exceeded")
    print("💡 Wait a moment before retrying")
    // Implement exponential backoff
    try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds

} catch LLMError.authenticationFailed {
    print("❌ Authentication Failed")
    print("💡 Check your API key and permissions")

} catch LLMError.invalidModel {
    print("❌ Invalid Model")
    print("💡 Use a valid model name like 'gpt-4' or 'gpt-3.5-turbo'")

} catch {
    print("❌ Unexpected Error: \(error.localizedDescription)")
    print("💡 This might be a temporary issue. Try again later.")
}
```

## Configuration Patterns

### For Different Use Cases

```swift
// Creative writing
let creativeConfig = {
    Temperature(0.9)
    TopP(0.95)
    MaxOutputTokens(800)
    PresencePenalty(0.1)
}

// Technical analysis
let technicalConfig = {
    Temperature(0.1)
    MaxOutputTokens(1500)
    FrequencyPenalty(0.1)
}

// Casual conversation
let casualConfig = {
    Temperature(0.7)
    MaxOutputTokens(300)
}

// Code generation
let codingConfig = {
    Temperature(0.2)
    MaxOutputTokens(1000)
    TopP(0.1)
}
```

### Performance Optimization

```swift
// Fast responses for chat UI
let fastChatConfig = {
    Temperature(0.8)
    MaxOutputTokens(150)
    TopP(0.9)
    StreamOptions(["include_usage": true])
}

// High-quality analysis
let deepAnalysisConfig = {
    Temperature(0.3)
    MaxOutputTokens(2000)
    FrequencyPenalty(0.2)
    PresencePenalty(0.1)
}

// Cost-effective processing
let economicalConfig = {
    Temperature(0.5)
    MaxOutputTokens(500)
    // Use smaller model if available
}
```

## Integration Examples

### REST API Service

```swift
class ChatService {
    private let client: LLMClient

    init(apiKey: String) throws {
        self.client = try LLMClient(baseURLString: "https://api.openai.com/v1/responses")
    }

    func processMessage(_ message: String, userId: String) async throws -> String {
        let response = try await client.respond(to: ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.7)
                MaxOutputTokens(500)
            },
            input: {
                system("You are a helpful assistant. User ID: \(userId)")
                user(message)
            }
        ))

        return response.choices.first?.message.content ?? "No response"
    }
}
```

### iOS/macOS Application

```swift
import SwiftUI
import SwiftResponsesDSL

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false

    private let client: LLMClient

    init() throws {
        self.client = try LLMClient(baseURLString: "https://api.openai.com/v1/responses")
    }

    func sendMessage(_ text: String) async {
        let userMessage = ChatMessage(text: text, isUser: true)
        messages.append(userMessage)

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await client.chat(
                model: "gpt-4",
                message: text
            )

            if let content = response.choices.first?.message.content {
                let aiMessage = ChatMessage(text: content, isUser: false)
                messages.append(aiMessage)
            }
        } catch {
            let errorMessage = ChatMessage(text: "Error: \(error.localizedDescription)", isUser: false)
            messages.append(errorMessage)
        }
    }
}
```

### Command-Line Tool

```swift
// CLI Tool Example
@main
struct ChatCLI {
    static func main() async {
        print("🤖 SwiftResponsesDSL Chat CLI")
        print("Type 'quit' to exit")

        let client = try LLMClient(baseURLString: "https://api.openai.com/v1/responses")

        while true {
            print("\n👤 You: ", terminator: "")
            guard let input = readLine(), !input.isEmpty else { continue }

            if input.lowercased() == "quit" { break }

            do {
                let response = try await client.chat(model: "gpt-4", message: input)
                if let answer = response.choices.first?.message.content {
                    print("🤖 Assistant: \(answer)")
                }
            } catch {
                print("❌ Error: \(error.localizedDescription)")
            }
        }
    }
}
```

## Graduating to Advanced Usage

Once you're comfortable with the examples above, explore these advanced features:

### Custom Extensions
Create domain-specific components:
```swift
struct EducationalLevel: ResponseConfigParameter {
    let level: String

    init(_ level: String) throws {
        let valid = ["elementary", "middle_school", "high_school", "college"]
        guard valid.contains(level) else {
            throw LLMError.invalidValue("Invalid education level")
        }
        self.level = level
    }

    func apply(to request: inout ResponseRequest) throws {
        request.input.insert(
            SystemMessage(text: "Explain at a \(level) reading level"),
            at: 0
        )
    }
}
```

### Enterprise Patterns
Implement production-ready patterns:
```swift
// Circuit breaker for resilience
let circuitBreaker = CircuitBreaker()

// Retry with exponential backoff
let response = try await retry {
    try await client.chat(model: "gpt-4", message: prompt)
}

// Request batching for efficiency
let batch = RequestBatch(maxBatchSize: 5)
batch.add(id: "req1") { /* request 1 */ }
let results = try await batch.execute()
```

### Performance Monitoring
Track usage and performance:
```swift
let metrics = MetricsCollector()

let startTime = Date()
let response = try await client.chat(model: "gpt-4", message: "Hello")
let duration = Date().timeIntervalSince(startTime)

metrics.record(name: "response_time", value: duration)
metrics.increment("requests_total")

if let usage = response.usage {
    metrics.record(name: "tokens_used", value: usage.totalTokens)
}
```

## Best Practices Summary

### Configuration
- Use appropriate temperature for your use case
- Set reasonable token limits to control costs
- Consider streaming for better user experience

### Error Handling
- Always handle network and authentication errors
- Implement retry logic for transient failures
- Provide meaningful error messages to users

### Performance
- Use streaming for real-time interfaces
- Batch requests when possible
- Cache frequently used responses
- Monitor token usage and costs

### Integration
- Handle rate limits gracefully
- Implement proper logging and monitoring
- Use appropriate models for different tasks
- Consider cost vs quality trade-offs

This guide covers the most common usage patterns. For more specialized examples, check the `Examples/` folder in the repository, which contains detailed implementations of advanced features and integration patterns.
