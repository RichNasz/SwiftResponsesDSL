# AI Chat App - Sample Project

A complete sample application demonstrating **SwiftResponsesDSL** integration in a real-world command-line chat application.

## 🎯 What This Sample Shows

This sample project demonstrates how to integrate SwiftResponsesDSL into a production-ready application, featuring:

- **Clean Architecture**: Separated concerns with service layers
- **Configuration Management**: Environment-based configuration
- **Error Handling**: Comprehensive error handling and recovery
- **Streaming Support**: Real-time streaming responses
- **Conversation Management**: Persistent conversation state
- **CLI Interface**: User-friendly command-line interface

## 🏗️ Project Structure

```
Sample-Project/
├── Package.swift              # Swift Package Manager configuration
├── Sources/
│   └── AIChatApp/
│       └── main.swift        # Main application entry point
├── Tests/
│   └── AIChatAppTests/       # Test files (placeholder)
└── Resources/                # Static resources (placeholder)
```

## 🚀 Getting Started

### Prerequisites

- **Swift 6.2+**: Required for SwiftResponsesDSL
- **OpenAI API Key**: Get one from [OpenAI Platform](https://platform.openai.com)
- **Terminal/Command Line**: For running the CLI application

### Installation

1. **Clone the repository** (if not already done):
   ```bash
   git clone https://github.com/RichNasz/SwiftResponsesDSL.git
   cd SwiftResponsesDSL
   ```

2. **Navigate to the sample project**:
   ```bash
   cd Examples/Sample-Project
   ```

3. **Set your API key**:
   ```bash
   # Replace 'your-api-key-here' with your actual OpenAI API key
   export OPENAI_API_KEY='your-api-key-here'
   ```

4. **Run the application**:
   ```bash
   swift run
   ```

## 💬 Using the Chat App

### Basic Usage

```bash
# Start the application
swift run

# Have a conversation
👤 You: Hello, how are you?
🤖 Assistant: Hello! I'm doing well, thank you for asking. How can I help you today?

👤 You: What's the capital of France?
🤖 Assistant: The capital of France is Paris.
```

### Available Commands

| Command | Description |
|---------|-------------|
| `/help` | Show help and available commands |
| `/clear` | Clear conversation history |
| `/summary` | Show conversation statistics |
| `/stream` | Toggle streaming mode on/off |
| `/quit` | Exit the application |

### Streaming Mode

```bash
👤 You: /stream
🌊 Streaming mode: ON

👤 You: Tell me a story about space exploration
🤖 The year was 2045 when humanity first set foot on Mars...
```

## 🛠️ Code Architecture

### Application Layers

```swift
// 1. Configuration Layer
struct AppConfig {
    let apiKey: String
    let baseURL: String
    let defaultModel: String
}

// 2. Service Layer
class ChatService {
    private let client: LLMClient
    private var conversation: ResponseConversation
}

// 3. Presentation Layer
class CLI {
    private let chatService: ChatService
    // Command-line interface logic
}
```

### Key Integration Points

#### Client Initialization
```swift
let client = try LLMClient(baseURLString: "https://api.openai.com/v1/responses")
```

#### Request Construction
```swift
let request = try ResponseRequest(
    model: "gpt-4",
    config: {
        Temperature(0.7)
        MaxOutputTokens(500)
    },
    input: {
        system("You are a helpful assistant")
        user(message)
    }
)
```

#### Response Handling
```swift
let response = try await client.respond(to: request)
let message = response.choices.first?.message.content ?? "No response"
```

#### Streaming Support
```swift
let stream = client.stream(request: request)
for try await event in stream {
    switch event {
    case .outputItemAdded(let item):
        // Handle streaming content
    case .completed:
        // Handle completion
    }
}
```

## 🔧 Configuration Options

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENAI_API_KEY` | Your OpenAI API key | Required |
| `OPENAI_BASE_URL` | API base URL | `https://api.openai.com/v1/responses` |

### App Configuration

```swift
let config = AppConfig(
    apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "",
    baseURL: "https://api.openai.com/v1/responses",
    defaultModel: "gpt-4",
    maxConversationLength: 50
)
```

## 🧪 Testing the Sample

### Unit Tests
```bash
swift test
```

### Integration Tests
```bash
# Test with mock responses
swift run AIChatApp --test-mode
```

### Manual Testing Checklist
- [ ] Basic conversation flow
- [ ] Streaming mode toggle
- [ ] Conversation clearing
- [ ] Error handling (network issues)
- [ ] Long conversation management
- [ ] Different model responses

## 🎨 Customization Examples

### Adding New Commands
```swift
// In CLI.run()
case "/model":
    print("Current model: \(config.defaultModel)")
case "/stats":
    showUsageStatistics()
```

### Custom System Prompts
```swift
conversation.append(system: """
You are a specialized coding assistant with expertise in:
- Swift programming
- iOS development
- Best practices and patterns
- Code review and optimization
""")
```

### Advanced Configuration
```swift
let request = try ResponseRequest(
    model: "gpt-4",
    config: {
        Temperature(0.3)        // More focused
        MaxOutputTokens(1000)   // Longer responses
        TopP(0.9)              // Balanced sampling
        PresencePenalty(0.1)   // Encourage variety
    },
    input: conversation.messages
)
```

## 🚨 Error Handling

The sample demonstrates comprehensive error handling:

```swift
do {
    let response = try await chatService.sendMessage(message)
} catch LLMError.networkError(let message) {
    print("❌ Network Error: \(message)")
} catch LLMError.invalidValue(let message) {
    print("❌ Configuration Error: \(message)")
} catch {
    print("❌ Unexpected Error: \(error.localizedDescription)")
}
```

## 📊 Performance Considerations

### Memory Management
- Conversation length limiting prevents memory bloat
- Value types (structs) for efficient memory usage
- Automatic cleanup of old messages

### Network Optimization
- Connection reuse through shared LLMClient
- Streaming for better perceived performance
- Request batching support

## 🔒 Security Best Practices

### API Key Management
- Environment variables (not hardcoded)
- Never log API keys
- Validate keys before use

### Data Handling
- No sensitive data in conversation history
- Clear conversation on app exit
- Secure storage for persistent data

## 🚀 Production Deployment

### Docker Containerization
```dockerfile
FROM swift:6.2
WORKDIR /app
COPY . .
RUN swift build -c release
EXPOSE 8080
CMD ["swift", "run", "AIChatApp"]
```

### Cloud Deployment
```bash
# Build for production
swift build -c release

# Run with production config
OPENAI_API_KEY=your-prod-key swift run AIChatApp
```

## 📚 Learn More

### Related Examples
- **[Basic Examples](../Basic/)**: Fundamental usage patterns
- **[Intermediate Examples](../Intermediate/)**: Advanced features and integrations
- **[Advanced Examples](../Advanced/)**: Enterprise patterns and custom extensions
- **[DSL Learning](../DSL-Learning/)**: Understanding DSL concepts
- **[Testing Examples](../Testing/)**: Testing strategies and patterns

### Documentation
- **[Main README](../../README.md)**: Complete API documentation
- **[SwiftResponsesDSL Package](../..)**: Source code and implementation
- **[OpenAI API](https://platform.openai.com/docs)**: API reference

## 🤝 Contributing

Found an issue or have an improvement? Consider:
- Opening an issue on GitHub
- Submitting a pull request
- Improving the documentation
- Adding new example features

## 📄 License

This sample project is part of SwiftResponsesDSL and follows the same license terms.

---

*This sample demonstrates production-ready SwiftResponsesDSL integration. Adapt the patterns shown here for your own applications!* 🚀
