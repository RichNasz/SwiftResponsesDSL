# Getting Started Tutorial

@Metadata {
    @DisplayName("Getting Started")
    @PageKind(tutorial)
}

Welcome to SwiftResponsesDSL! This hands-on tutorial will guide you through building your first LLM-powered application in just 15 minutes. By the end, you'll have a working Swift application that can chat with AI models, handle conversations, and process streaming responses.

## What You'll Build

In this tutorial, you'll create a **Swift command-line application** that:
- ✅ Connects to an LLM API (OpenAI or compatible)
- ✅ Has a natural conversation interface
- ✅ Supports both regular and streaming responses
- ✅ Handles errors gracefully
- ✅ Demonstrates advanced features like tool calling

## Prerequisites

Before starting, ensure you have:
- **Swift 6.2+** installed (see toolchain setup below)
- **LLM API access** (OpenAI API key or compatible service)

### Swift 6.2 Toolchain Setup

#### Option 1: Xcode (macOS)
```bash
# Download and install Xcode 26+ from:
# https://developer.apple.com/xcode/

# Install command line tools
xcode-select --install

# Verify installation
xcodebuild -version  # Should show Xcode 26.x
swift --version      # Should show Swift 6.2.x
```

**Requirements:**
- macOS 14.0+ (Sonoma)
- Xcode 26.0+ (currently in beta)

#### Option 2: Swiftly (Command Line / All Platforms)
```bash
# Install Swiftly (Swift toolchain manager)
curl -L https://github.com/swiftlang/swiftly/releases/latest/download/swiftly-install.sh | bash
source ~/.swiftly/env.sh

# Install Swift 6.2
swiftly install 6.2

# Set as your default Swift version
swiftly use 6.2

# Verify installation
swift --version  # Should show: swift-6.2.x
```

#### Option 3: Manual Installation (Linux)
```bash
# Download Swift 6.2 for your platform
# Ubuntu 22.04 example:
wget https://swift.org/builds/swift-6.2-release/ubuntu2204/swift-6.2-RELEASE/swift-6.2-RELEASE-ubuntu22.04.tar.gz
tar xzf swift-6.2-RELEASE-ubuntu22.04.tar.gz

# Add to PATH
export PATH=$PWD/swift-6.2-RELEASE-ubuntu22.04/usr/bin:$PATH

# Verify
swift --version
```

### Verifying Your Setup

Run these commands to ensure everything is working:

```bash
# Check Swift version
swift --version

# Check Package Manager
swift package --version

# Test basic functionality
swift package init --type executable
cd <your-project>
swift build
swift run
```

### Troubleshooting Toolchain Issues

**"swift: command not found"**
- Ensure Swift is in your PATH
- If using Swiftly: `source ~/.swiftly/env.sh`
- If manual install: Check your PATH export

**"Swift 6.2 required" error**
- Run `swiftly use 6.2` to switch versions
- Or reinstall with the correct version

**Xcode issues on macOS**
- Ensure you're using Xcode 26+ (not Xcode 15)
- Set the correct Xcode: `sudo xcode-select -s /Applications/Xcode-26.app`

## Step 1: Project Setup

### Create a New Swift Package

```bash
# Create a new Swift package
mkdir MyFirstLLMApp
cd MyFirstLLMApp

# Initialize the package
swift package init --type executable

# Add SwiftResponsesDSL dependency
# Edit Package.swift
```

### Update Package.swift

Replace the contents of `Package.swift` with:

```swift
// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "MyFirstLLMApp",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/RichNasz/SwiftResponsesDSL.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "MyFirstLLMApp",
            dependencies: ["SwiftResponsesDSL"]
        )
    ]
)
```

### Update main.swift

Replace the contents of `Sources/MyFirstLLMApp/main.swift` with:

```swift
import SwiftResponsesDSL

@main
struct MyFirstLLMApp {
    static func main() async {
        print("🤖 Welcome to My First LLM App!")
        print("=================================")

        // Step 2: We'll add the client initialization here
    }
}
```

### Test the Setup

```bash
# Build the project
swift build

# Run it (should just print the welcome message)
swift run
```

## Step 2: Connect to an LLM API

### Add API Configuration

Update your `main.swift` to include API connection:

```swift
import SwiftResponsesDSL

@main
struct MyFirstLLMApp {
    static func main() async {
        print("🤖 Welcome to My First LLM App!")
        print("=================================")

        // Initialize the LLM client
        let client: LLMClient
        do {
            // For OpenAI (replace with your actual API key)
            client = try LLMClient(
                baseURLString: "https://api.openai.com/v1/responses",
                apiKey: "your-api-key-here"
            )
            print("✅ Connected to LLM API")
        } catch {
            print("❌ Failed to connect: \(error.localizedDescription)")
            print("💡 Make sure your API key is correct")
            return
        }

        // Step 3: We'll add the conversation logic here
    }
}
```

### Environment Variables (Recommended)

For better security, use environment variables for your API key:

```bash
# Set your API key as an environment variable
export OPENAI_API_KEY="your-api-key-here"
```

Then update your code:

```swift
// Initialize the LLM client
let client: LLMClient
do {
    let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "your-api-key-here"
    client = try LLMClient(
        baseURLString: "https://api.openai.com/v1/responses",
        apiKey: apiKey
    )
    print("✅ Connected to LLM API")
} catch {
    print("❌ Failed to connect: \(error.localizedDescription)")
    print("💡 Check your API key and internet connection")
    return
}
```

## Step 3: Your First Conversation

### Add Basic Chat Functionality

Add this after the client initialization:

```swift
// Start a simple conversation
print("\n💬 Let's have a conversation!")
print("Type 'quit' to exit, 'help' for commands")
print("---------------------------------------")

var conversation = ResponseConversation()

// Set up the AI's personality
conversation.append(system: "You are a friendly and helpful AI assistant. Keep your responses concise but informative.")

while true {
    print("\n👤 You: ", terminator: "")
    guard let input = readLine(), !input.isEmpty else { continue }

    if input.lowercased() == "quit" {
        print("👋 Goodbye! Thanks for chatting!")
        break
    }

    if input.lowercased() == "help" {
        printCommands()
        continue
    }

    // Add user message to conversation
    conversation.append(user: input)

    // Get AI response
    do {
        let response = try await client.chat(conversation: conversation)

        if let message = response.choices.first?.message.content {
            print("🤖 Assistant: \(message)")
            // Add AI response to conversation for context
            conversation.append(response: response)
        } else {
            print("🤖 Assistant: (No response)")
        }
    } catch {
        print("❌ Error: \(error.localizedDescription)")
        print("💡 Try again or check your API key")
    }
}
```

### Add Helper Function

Add this function before the main function:

```swift
func printCommands() {
    print("""
    Available commands:
    • 'quit' - Exit the application
    • 'help' - Show this help message
    • 'clear' - Start a new conversation
    • 'history' - Show conversation history
    • Any other text - Chat with the AI
    """)
}
```

### Test Your Application

```bash
# Run your application
swift run

# Try these commands:
# Hello! Who are you?
# What's the weather like today?
# Can you help me write a Swift function?
# quit
```

## Step 4: Add Advanced Features

### Streaming Responses

Add streaming support to your application. First, add a streaming command:

```swift
if input.lowercased() == "stream" {
    print("🎯 Switching to streaming mode...")
    print("🤖 Assistant: ", terminator: "")

    // Create a streaming request
    let streamRequest = ResponseRequest(
        model: "gpt-4",
        input: {
            system("You are a helpful assistant providing detailed explanations.")
            user("Explain how Swift's async/await works")
        }
    )

    do {
        let stream = client.stream(request: streamRequest)
        var fullResponse = ""

        for try await event in stream {
            switch event {
            case .outputItemAdded(let item):
                if case .message(let message) = item,
                   let content = message.content {
                    print(content, terminator: "")
                    fflush(stdout)  // Force immediate output
                    fullResponse += content
                }
            case .completed:
                print("\n✅ Response complete!")
            default:
                break
            }
        }

        // Add to conversation history
        if !fullResponse.isEmpty {
            conversation.append(user: "Explain how Swift's async/await works")
            conversation.append(assistant: fullResponse)
        }
    } catch {
        print("\n❌ Streaming error: \(error.localizedDescription)")
    }
    continue
}
```

### Tool Calling (Advanced)

Add tool calling capabilities:

```swift
if input.lowercased() == "tools" {
    print("🛠️  Demonstrating tool calling...")

    // Define a simple calculator tool
    let tools = try Tools([
        Tool(type: "function", function: Tool.Function(
            name: "calculate",
            description: "Perform mathematical calculations",
            parameters: [
                "expression": .string(description: "Mathematical expression to evaluate")
            ]
        ))
    ])

    let toolRequest = ResponseRequest(
        model: "gpt-4",
        config: {
            ToolChoice("auto")
            MaxToolCalls(3)
        },
        input: {
            system("You are a helpful math tutor. Use the calculator tool when needed.")
            user("What's 15 multiplied by 23, then divided by 5?")
        },
        tools: tools
    )

    do {
        let response = try await client.respond(to: toolRequest)
        if let content = response.choices.first?.message.content {
            print("🤖 Assistant: \(content)")
        }

        // Show any tool calls made
        if let toolCalls = response.choices.first?.message.toolCalls, !toolCalls.isEmpty {
            print("🔧 Tools used: \(toolCalls.count)")
            for (index, toolCall) in toolCalls.enumerated() {
                print("  \(index + 1). \(toolCall.function.name)")
            }
        }
    } catch {
        print("❌ Tool calling error: \(error.localizedDescription)")
    }
    continue
}
```

## Step 5: Error Handling and Polish

### Add Comprehensive Error Handling

Replace the conversation loop's error handling:

```swift
do {
    let response = try await client.chat(conversation: conversation)

    if let message = response.choices.first?.message.content {
        print("🤖 Assistant: \(message)")
        conversation.append(response: response)
    } else {
        print("🤖 Assistant: (No response generated)")
    }
} catch LLMError.authenticationFailed {
    print("❌ Authentication Error: Check your API key")
    print("💡 Set OPENAI_API_KEY environment variable or update the code")
} catch LLMError.rateLimit {
    print("❌ Rate Limit Exceeded: Please wait before trying again")
    print("💡 Consider upgrading your API plan for higher limits")
} catch LLMError.networkError(let message) {
    print("❌ Network Error: \(message)")
    print("💡 Check your internet connection")
} catch {
    print("❌ Unexpected Error: \(error.localizedDescription)")
    print("💡 This might be a temporary issue. Try again.")
}
```

### Add Conversation Management

Add conversation management commands:

```swift
if input.lowercased() == "clear" {
    conversation = ResponseConversation()
    conversation.append(system: "You are a friendly and helpful AI assistant.")
    print("🧹 Conversation cleared. Starting fresh!")
    continue
}

if input.lowercased() == "history" {
    print("\n📚 Conversation History:")
    print("========================")
    for (index, message) in conversation.messages.enumerated() {
        let role = message.role.rawValue.capitalized
        let preview = String((message.content.first?.text ?? "N/A").prefix(50))
        print("\(index + 1). \(role): \(preview)...")
    }
    print("Total messages: \(conversation.messages.count)")
    continue
}
```

## Step 6: Final Polish and Testing

### Complete Application Code

Here's the complete `main.swift` file:

```swift
import SwiftResponsesDSL

func printCommands() {
    print("""
    🤖 My First LLM App Commands:
    ================================
    • 'quit'     - Exit the application
    • 'help'     - Show this help message
    • 'clear'    - Start a new conversation
    • 'history'  - Show conversation history
    • 'stream'   - Demonstrate streaming responses
    • 'tools'    - Demonstrate tool calling
    • Any text   - Chat with the AI
    ================================
    """)
}

@main
struct MyFirstLLMApp {
    static func main() async {
        print("🤖 Welcome to My First LLM App!")
        print("=================================")

        // Initialize the LLM client
        let client: LLMClient
        do {
            let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "your-api-key-here"
            client = try LLMClient(
                baseURLString: "https://api.openai.com/v1/responses",
                apiKey: apiKey
            )
            print("✅ Connected to LLM API")
        } catch {
            print("❌ Failed to connect: \(error.localizedDescription)")
            print("💡 Set OPENAI_API_KEY environment variable or update the API key in the code")
            return
        }

        // Initialize conversation
        var conversation = ResponseConversation()
        conversation.append(system: "You are a friendly and helpful AI assistant. Keep responses concise but informative.")

        print("\n💬 Let's have a conversation!")
        printCommands()

        while true {
            print("\n👤 You: ", terminator: "")
            guard let input = readLine(), !input.isEmpty else { continue }

            switch input.lowercased() {
            case "quit":
                print("👋 Goodbye! Thanks for chatting!")
                return

            case "help":
                printCommands()

            case "clear":
                conversation = ResponseConversation()
                conversation.append(system: "You are a friendly and helpful AI assistant.")
                print("🧹 Conversation cleared. Starting fresh!")

            case "history":
                print("\n📚 Conversation History:")
                print("========================")
                for (index, message) in conversation.messages.enumerated() {
                    let role = message.role.rawValue.capitalized
                    let preview = String((message.content.first?.text ?? "N/A").prefix(50))
                    print("\(index + 1). \(role): \(preview)...")
                }
                print("Total messages: \(conversation.messages.count)")

            case "stream":
                await demonstrateStreaming(client: client, conversation: &conversation)

            case "tools":
                await demonstrateToolCalling(client: client)

            default:
                // Regular chat
                conversation.append(user: input)

                do {
                    let response = try await client.chat(conversation: conversation)

                    if let message = response.choices.first?.message.content {
                        print("🤖 Assistant: \(message)")
                        conversation.append(response: response)
                    } else {
                        print("🤖 Assistant: (No response generated)")
                    }
                } catch LLMError.authenticationFailed {
                    print("❌ Authentication Error: Check your API key")
                    print("💡 Set OPENAI_API_KEY environment variable")
                } catch LLMError.rateLimit {
                    print("❌ Rate Limit Exceeded: Please wait before trying again")
                } catch LLMError.networkError(let message) {
                    print("❌ Network Error: \(message)")
                } catch {
                    print("❌ Unexpected Error: \(error.localizedDescription)")
                }
            }
        }
    }

    static func demonstrateStreaming(client: LLMClient, conversation: inout ResponseConversation) async {
        print("🎯 Switching to streaming mode...")
        print("🤖 Assistant: ", terminator: "")

        let streamRequest = ResponseRequest(
            model: "gpt-4",
            input: {
                system("You are a helpful assistant providing detailed explanations.")
                user("Explain how Swift's async/await works in simple terms")
            }
        )

        do {
            let stream = client.stream(request: streamRequest)
            var fullResponse = ""

            for try await event in stream {
                switch event {
                case .outputItemAdded(let item):
                    if case .message(let message) = item,
                       let content = message.content {
                        print(content, terminator: "")
                        fflush(stdout)
                        fullResponse += content
                    }
                case .completed:
                    print("\n✅ Response complete!")
                default:
                    break
                }
            }

            if !fullResponse.isEmpty {
                conversation.append(user: "Explain how Swift's async/await works")
                conversation.append(assistant: fullResponse)
            }
        } catch {
            print("\n❌ Streaming error: \(error.localizedDescription)")
        }
    }

    static func demonstrateToolCalling(client: LLMClient) async {
        print("🛠️  Demonstrating tool calling...")

        let tools = try? Tools([
            Tool(type: "function", function: Tool.Function(
                name: "calculate",
                description: "Perform mathematical calculations",
                parameters: [
                    "expression": .string(description: "Mathematical expression to evaluate")
                ]
            ))
        ])

        guard let tools = tools else {
            print("❌ Failed to create tools")
            return
        }

        let toolRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                ToolChoice("auto")
                MaxToolCalls(3)
            },
            input: {
                system("You are a helpful math tutor. Use the calculator tool when needed.")
                user("What's 15 multiplied by 23, then divided by 5?")
            },
            tools: tools
        )

        do {
            let response = try await client.respond(to: toolRequest)
            if let content = response.choices.first?.message.content {
                print("🤖 Assistant: \(content)")
            }

            if let toolCalls = response.choices.first?.message.toolCalls, !toolCalls.isEmpty {
                print("🔧 Tools used: \(toolCalls.count)")
                for (index, toolCall) in toolCalls.enumerated() {
                    print("  \(index + 1). \(toolCall.function.name)")
                }
            }
        } catch {
            print("❌ Tool calling error: \(error.localizedDescription)")
        }
    }
}
```

## Step 7: Testing and Next Steps

### Test Your Application

```bash
# Build and run
swift run

# Try these interactions:
# help
# Hello! Can you help me learn Swift?
# stream
# tools
# history
# clear
# What's the capital of France?
# quit
```

### Expected Output

```
🤖 Welcome to My First LLM App!
=================================
✅ Connected to LLM API

💬 Let's have a conversation!
🤖 My First LLM App Commands:
================================
• 'quit'     - Exit the application
• 'help'     - Show this help message
• 'clear'    - Start a new conversation
• 'history'  - Show conversation history
• 'stream'   - Demonstrate streaming responses
• 'tools'    - Demonstrate tool calling
• Any text   - Chat with the AI
================================

👤 You: Hello! Can you help me learn Swift?
🤖 Assistant: Hello! I'd be happy to help you learn Swift! Swift is a powerful and intuitive programming language developed by Apple for building apps across all their platforms...

👤 You: stream
🎯 Switching to streaming mode...
🤖 Assistant: Swift's async/await is a concurrency feature that makes asynchronous programming much easier to write and understand...

👤 You: quit
👋 Goodbye! Thanks for chatting!
```

## Congratulations! 🎉

You've successfully built your first LLM-powered Swift application! Here's what you accomplished:

### ✅ What You Learned
- **LLM API Integration** - Connecting to and authenticating with AI services
- **Swift Concurrency** - Using async/await for asynchronous operations
- **Error Handling** - Comprehensive error handling with specific error types
- **Streaming Responses** - Real-time response processing
- **Tool Calling** - AI agents that can use external tools
- **Conversation Management** - Maintaining context across multiple interactions

### 🚀 Next Steps

1. **Experiment with Different Models**
   ```swift
   // Try different models
   let response = try await client.respond(to: ResponseRequest(
       model: "gpt-3.5-turbo",  // Faster, cheaper
       // model: "gpt-4",        // More capable
       // model: "gpt-4-turbo",  // Latest and greatest
       input: { user("Hello!") }
   ))
   ```

2. **Customize AI Behavior**
   ```swift
   let response = try await client.respond(to: ResponseRequest(
       model: "gpt-4",
       config: {
           Temperature(0.3)        // More focused
           MaxOutputTokens(1000)   // Longer responses
           TopP(0.9)              // Creative variety
       },
       input: { user("Write a creative story") }
   ))
   ```

3. **Build More Complex Applications**
   - **Chatbot Interface** - Add a web or mobile UI
   - **Code Assistant** - Help with programming tasks
   - **Content Generator** - Create articles, marketing copy
   - **Educational Tool** - Build interactive learning experiences

### 📚 Further Reading

Now that you have a working application, explore these resources:

- **[DSL Guide](./DSL.md)** - Deep dive into the Domain Specific Language concepts
- **[Usage Examples](./Usage.md)** - More advanced usage patterns
- **[Architecture Guide](./Architecture.md)** - Technical implementation details
- **[Examples Folder](../../Examples/)** - Additional code examples
- **[API Reference](./SwiftResponsesDSL.md)** - Complete API documentation

### 💡 Tips for Success

1. **Start Simple** - Begin with basic chat functionality
2. **Handle Errors** - Always include proper error handling
3. **Manage Costs** - Monitor API usage and set appropriate limits
4. **Test Thoroughly** - Test with different inputs and edge cases
5. **Iterate Quickly** - Use the DSL to rapidly prototype and improve

Happy coding with SwiftResponsesDSL! 🚀✨

**Ready to build something amazing?** Check out the [Usage Examples](./Usage.md) for more advanced patterns, or explore the [Examples folder](../../Examples/) for complete application templates.
