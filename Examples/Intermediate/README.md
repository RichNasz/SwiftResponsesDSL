# Intermediate Examples

Welcome to **Intermediate Examples**! This folder contains more advanced usage patterns that build upon the basic concepts. These examples demonstrate real-world scenarios and more sophisticated interactions with LLMs.

## 📚 What's Covered

### 1. Conversation Management (`ConversationManagement.swift`)
Master the art of maintaining context across multiple interactions:
- Basic conversation flows with persistent context
- Advanced conversations with custom roles and expertise
- Conversation branching and comparison
- Memory management for long conversations
- Multi-turn problem solving

### 2. Multimodal Content (`MultimodalContent.swift`)
Work with diverse content types beyond text:
- Image analysis and description
- Comparing different image detail levels
- Multiple image analysis simultaneously
- Images with contextual text prompts
- File content analysis (code, documents)
- Structured data analysis (JSON, CSV)
- Multimodal conversations combining multiple content types

### 3. Tool Usage (`ToolUsage.swift`)
Extend LLM capabilities with external tools and functions:
- Basic tool definition and usage
- Weather lookup tool integration
- Multiple tools with intelligent selection
- Tool results processing and conversation continuation
- Complex tool chains for multi-step tasks
- Error handling for tool execution failures

## 🚀 Getting Started

### Prerequisites
```swift
// Make sure you have SwiftResponsesDSL imported
import SwiftResponsesDSL

// For multimodal examples, you might need vision-capable models
let visionClient = try LLMClient(baseURLString: "https://api.openai.com/v1/responses")
// Use models like "gpt-4-vision-preview" for image analysis
```

### API Requirements
Some examples require specific API capabilities:
- **Vision Examples**: Models like `gpt-4-vision-preview`
- **Tool Examples**: Models like `gpt-4` with function calling
- **Standard Examples**: Most GPT models work fine

## 📖 Example Structure

Each example demonstrates:
1. **Setup**: Configure client and tools as needed
2. **Request Building**: Use DSL to construct complex requests
3. **Execution**: Handle both success and error cases
4. **Results Processing**: Extract and present information meaningfully
5. **Best Practices**: Show recommended patterns

## 💡 Key Intermediate Concepts

### Conversation Management
```swift
// Maintain context across multiple exchanges
var conversation = ResponseConversation()
conversation.append(system: "You are a helpful assistant")
conversation.append(user: "Hello!")

let response = try await client.chat(conversation: conversation)
conversation.append(response: response)

// Continue with context preserved
conversation.append(user: "Tell me more...")
```

### Multimodal Content
```swift
// Combine text with images
let request = try ResponseRequest(
    model: "gpt-4-vision-preview",
    input: {
        user([
            .text("What's in this image?"),
            .imageUrl(url: "https://example.com/image.jpg", detail: .high)
        ])
    }
)
```

### Tool Integration
```swift
// Define and use tools
let calculatorTool = Tool(
    type: .function,
    function: Tool.Function(
        name: "calculate",
        description: "Perform calculations",
        parameters: .object([
            "expression": .string(description: "Math expression")
        ])
    )
)

let request = try ResponseRequest(
    model: "gpt-4",
    input: { user("What's 15 * 23?") },
    tools: [calculatorTool]
)
```

## 🔧 Configuration Tips

### Conversation Management
- **Memory Limits**: Monitor conversation length to avoid token limits
- **Context Window**: Keep important context, trim less critical messages
- **Role Consistency**: Maintain consistent system prompts throughout

### Multimodal Content
- **Image Quality**: Choose appropriate detail levels (`low`, `high`)
- **File Types**: Ensure supported formats (images, text files)
- **Size Limits**: Be aware of API limits for file sizes

### Tool Usage
- **Tool Descriptions**: Write clear, specific tool descriptions
- **Parameter Validation**: Define parameter constraints properly
- **Error Handling**: Always handle tool execution failures gracefully

## 🚨 Common Intermediate Issues

### Conversation Context Loss
```swift
// ❌ Wrong: Creating new conversation each time
let response1 = try await client.chat(model: "gpt-4", message: "Hello")
let response2 = try await client.chat(model: "gpt-4", message: "Tell me more")

// ✅ Correct: Maintain conversation state
var conversation = ResponseConversation()
conversation.append(user: "Hello")
let response1 = try await client.chat(conversation: conversation)
conversation.append(response: response1)
conversation.append(user: "Tell me more")
let response2 = try await client.chat(conversation: conversation)
```

### Tool Parameter Errors
```swift
// ❌ Wrong: Missing required parameters
let badTool = Tool(type: .function, function: Tool.Function(
    name: "search",
    description: "Search function"
    // Missing parameters!
))

// ✅ Correct: Define parameters properly
let goodTool = Tool(type: .function, function: Tool.Function(
    name: "search",
    description: "Search for information",
    parameters: .object([
        "query": .string(description: "Search query")
    ])
))
```

### Multimodal Format Issues
```swift
// ❌ Wrong: Mixing incompatible content types
user([
    .text("Analyze this"),
    .file(path: "/path/to/file.pdf"), // Not supported in all models
])

// ✅ Correct: Use supported formats
user([
    .text("Analyze this code"),
    .text("```swift\nlet x = 1\n```") // Text-based file content
])
```

## 📈 Next Steps

After mastering these intermediate examples, you're ready for:

- **[Advanced Examples](../Advanced/)**: Complex integrations, custom extensions, and enterprise patterns
- **[DSL Learning](../DSL-Learning/)**: Deep dive into DSL concepts and architecture
- **[Testing Examples](../Testing/)**: Comprehensive testing strategies

## 🛠️ Running Examples

### Individual Examples
```swift
// Run specific examples
try await runConversationExamples()
try await runMultimodalExamples()
try await runToolExamples()
```

### Selective Execution
```swift
// Run only what you need
try await basicConversationExample()
try await imageAnalysisExample()
try await weatherToolExample()
```

### Error Handling
```swift
do {
    try await runIntermediateExamples()
} catch LLMError.invalidModel {
    print("Check your model name")
} catch LLMError.networkError {
    print("Check your internet connection")
} catch {
    print("Unexpected error:", error.localizedDescription)
}
```

## 🎯 Best Practices

### 1. Conversation Design
- **Clear Roles**: Define assistant roles clearly in system messages
- **Context Management**: Regularly assess what context is still relevant
- **Natural Flow**: Allow conversations to flow naturally while maintaining focus

### 2. Multimodal Integration
- **Content Planning**: Think about how different content types work together
- **Fallback Strategies**: Have text-only alternatives for multimodal content
- **Performance**: Consider token costs for high-detail image analysis

### 3. Tool Architecture
- **Tool Discovery**: Make tools easy to discover and understand
- **Parameter Design**: Design tool parameters to be intuitive
- **Result Processing**: Handle tool results meaningfully in conversations

## 🤝 Need Help?

- Check the [main README](../../README.md) for API setup
- Review the [DSL Learning](../DSL-Learning/) examples for deeper understanding
- Examine the [test cases](../../Tests/) for more usage patterns

Happy exploring! 🚀
