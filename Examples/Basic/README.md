# Basic Examples

Welcome to the **Basic Examples**! This folder contains the fundamental building blocks for using SwiftResponsesDSL. These examples are designed for beginners and focus on core concepts without overwhelming complexity.

## 📚 What's Covered

### 1. Simple Chat (`SimpleChat.swift`)
Learn the absolute basics of SwiftResponsesDSL:
- Creating an LLM client
- Sending simple messages
- Handling responses
- Basic error handling
- Working with different models

### 2. Configuration Basics (`ConfigurationBasics.swift`)
Master the art of controlling LLM behavior:
- Temperature control for creativity
- Response length management
- Parameter validation
- Combining multiple parameters
- Default vs custom configurations

### 3. Streaming Basics (`StreamingBasics.swift`)
Experience real-time AI interactions:
- Basic streaming setup
- Progress indicators
- Response cancellation
- Streaming vs non-streaming comparison
- Error handling in streaming

## 🚀 Getting Started

### Prerequisites
```swift
// Make sure you have SwiftResponsesDSL imported
import SwiftResponsesDSL
```

### API Key Setup
```swift
// You'll need a valid API key for your LLM provider
let client = try LLMClient(baseURLString: "https://api.openai.com/v1/responses")
// Make sure to set your API key in your environment or configuration
```

## 📖 Example Structure

Each example follows this pattern:
1. **Setup**: Create client and basic configuration
2. **Execution**: Make the API call
3. **Results**: Handle and display the response
4. **Cleanup**: Error handling and resource management

## 🎯 Learning Path

Follow this sequence for the best learning experience:

1. **Start Here** → `SimpleChat.swift`
   - Learn the fundamental API
   - Understand basic request/response flow

2. **Then Try** → `ConfigurationBasics.swift`
   - Control LLM behavior
   - Experiment with different parameters

3. **Finally** → `StreamingBasics.swift`
   - Experience real-time interactions
   - Learn advanced streaming patterns

## 💡 Key Concepts

### Simple Chat
```swift
let client = try LLMClient(baseURLString: "https://api.openai.com/v1/responses")
let response = try await client.chat(model: "gpt-4", message: "Hello!")
```

### Configuration
```swift
let request = try ResponseRequest(
    model: "gpt-4",
    config: {
        Temperature(0.7)
        MaxOutputTokens(100)
    },
    input: {
        user("Your message here")
    }
)
```

### Streaming
```swift
let stream = client.stream(request: request)
for try await event in stream {
    switch event {
    case .outputItemAdded(let item):
        // Handle streaming content
    case .completed(let response):
        // Handle completion
    }
}
```

## 🛠️ Running Examples

### Option 1: Copy into your project
1. Copy the example code into your Swift project
2. Add SwiftResponsesDSL as a dependency
3. Set up your API credentials
4. Run the code

### Option 2: Swift Package
```bash
swift run
```

### Option 3: Xcode Playground
1. Create a new playground
2. Add SwiftResponsesDSL package dependency
3. Copy example code into the playground
4. Run and experiment

## 🔧 Configuration Tips

### Temperature Values
- **0.0**: Very focused, deterministic responses
- **0.7**: Balanced creativity and consistency (recommended)
- **1.5**: Highly creative, varied responses

### Token Limits
- **Short responses**: 50-100 tokens
- **Medium responses**: 100-500 tokens
- **Long responses**: 500+ tokens

## 🚨 Common Issues

### "Invalid API Key"
- Check your API key is valid and has proper permissions
- Ensure you're using the correct endpoint URL

### "Network Error"
- Verify internet connectivity
- Check if the API service is available
- Confirm your endpoint URL is correct

### "Invalid Parameters"
- Temperature must be between 0.0 and 2.0
- Max tokens must be between 1 and model limit
- Check parameter validation error messages

## 📈 Next Steps

After mastering these basic examples, you're ready for:

- **[Intermediate Examples](../Intermediate/)**: Advanced features and patterns
- **[Advanced Examples](../Advanced/)**: Complex integrations and customizations
- **[DSL Learning](../DSL-Learning/)**: Deep dive into DSL concepts

## 🤝 Need Help?

- Check the [main README](../../README.md) for setup instructions
- Review the [API documentation](../../Sources/SwiftResponsesDSL/SwiftResponsesDSL.swift)
- Explore the [test cases](../../Tests/) for more usage patterns

Happy coding! 🎉
