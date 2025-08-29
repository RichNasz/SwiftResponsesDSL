# SwiftResponsesDSL Examples

Welcome to the **SwiftResponsesDSL Examples**! This comprehensive collection demonstrates the full power and flexibility of SwiftResponsesDSL across different experience levels and use cases.

## 📚 Example Categories

### 🎯 [Basic Examples](./Basic/)
Perfect for beginners learning SwiftResponsesDSL fundamentals.

#### What's Included
- **Simple Chat** (`SimpleChat.swift`): Absolute basics of LLM interaction
- **Configuration Basics** (`ConfigurationBasics.swift`): Parameter control and validation
- **Streaming Basics** (`StreamingBasics.swift`): Real-time response handling

#### Key Concepts
- ✅ Creating LLM clients
- ✅ Building basic requests
- ✅ Handling responses and errors
- ✅ Temperature and token control
- ✅ Real-time streaming
- ✅ Error handling patterns

#### Perfect For
- First-time SwiftResponsesDSL users
- Understanding core API patterns
- Learning DSL syntax basics

---

### 🚀 [Intermediate Examples](./Intermediate/)
Advanced features for experienced developers building complex applications.

#### What's Included
- **Conversation Management** (`ConversationManagement.swift`): Multi-turn conversations
- **Multimodal Content** (`MultimodalContent.swift`): Images, files, and structured data
- **Tool Usage** (`ToolUsage.swift`): Function calling and external integrations

#### Key Concepts
- ✅ Conversation state management
- ✅ Image analysis and processing
- ✅ File content analysis
- ✅ Tool integration and function calling
- ✅ Complex parameter combinations
- ✅ Memory management for long conversations

#### Perfect For
- Building chat applications
- Integrating with external APIs
- Handling complex user interactions
- Implementing multimodal features

---

### 🏢 [Advanced Examples](./Advanced/)
Enterprise-grade patterns and custom extensions for production systems.

#### What's Included
- **Custom Extensions** (`CustomExtensions.swift`): Domain-specific components
- **Enterprise Patterns** (`EnterprisePatterns.swift`): Production-ready patterns

#### Key Concepts
- ✅ Custom parameter types
- ✅ Domain-specific builders
- ✅ Circuit breaker pattern
- ✅ Retry with exponential backoff
- ✅ Request batching and rate limiting
- ✅ Comprehensive monitoring and logging

#### Perfect For
- Production applications
- High-traffic systems
- Enterprise integrations
- Custom DSL extensions

---

### 🎓 [DSL Learning](./DSL-Learning/)
Educational content explaining DSL concepts and providing step-by-step tutorials.

#### What's Included
- **What is DSL?** (`WhatIsDSL.swift`): DSL concepts and benefits
- **Step-by-Step Tutorial** (`StepByStepTutorial.swift`): Complete learning path

#### Key Concepts
- ✅ DSL vs traditional API approaches
- ✅ Declarative vs imperative programming
- ✅ Type safety and compile-time validation
- ✅ Progressive complexity from basics to advanced
- ✅ Best practices and anti-patterns

#### Perfect For
- Understanding DSL philosophy
- Learning from zero to hero
- Comparing different approaches
- Best practices and patterns

---

### 🧪 [Testing Examples](./Testing/)
Comprehensive testing strategies and patterns for SwiftResponsesDSL.

#### What's Included
- **Unit Testing** (`UnitTesting.swift`): Component and functionality testing

#### Key Concepts
- ✅ Parameter validation testing
- ✅ Request construction testing
- ✅ Message type testing
- ✅ DSL builder testing
- ✅ Error scenario testing
- ✅ Performance testing
- ✅ Memory usage testing

#### Perfect For
- Writing comprehensive tests
- Understanding testing strategies
- Performance validation
- Quality assurance

---

### 💻 [Sample Project](./Sample-Project/)
Complete working application demonstrating real-world integration.

#### What's Included
- **AI Chat App** (`main.swift`): Full command-line chat application
- **Package Configuration** (`Package.swift`): SPM setup and dependencies
- **Project Structure**: Production-ready organization

#### Key Concepts
- ✅ Complete application architecture
- ✅ Service layer integration
- ✅ Configuration management
- ✅ CLI interface implementation
- ✅ Error handling and recovery
- ✅ Production deployment patterns

#### Perfect For
- Understanding full integration
- Starting new projects
- Learning application architecture
- Production deployment reference

## 🚀 Quick Start Guide

### For Beginners
```bash
# Start with the basics
cd Examples/Basic
swift run  # Run any example file
```

### For Intermediate Users
```bash
# Explore advanced features
cd Examples/Intermediate
swift run
```

### For Production Development
```bash
# See enterprise patterns
cd Examples/Advanced
swift run
```

### For Learning DSL Concepts
```bash
# Understand DSL philosophy
cd Examples/DSL-Learning
swift run
```

### For Complete Application
```bash
# Full working example
cd Examples/Sample-Project
swift run
```

## 📋 Prerequisites

### System Requirements
- **macOS 12.0+** or **Linux (Ubuntu 22.04+)**
- **Swift 6.2+** with full toolchain
- **Terminal/Command Line** access

### API Requirements
- **OpenAI API Key** (for live examples)
- **Internet Connection** (for API calls)

### Setup Instructions
```bash
# 1. Clone the repository
git clone https://github.com/RichNasz/SwiftResponsesDSL.git
cd SwiftResponsesDSL

# 2. Set your API key (for live examples)
export OPENAI_API_KEY='your-api-key-here'

# 3. Navigate to examples
cd Examples

# 4. Run any example
cd Basic
swift run SimpleChat.swift
```

## 🎯 Learning Path

### Path 1: Beginner to Advanced
1. **[Basic Examples](./Basic/)** → Core concepts and syntax
2. **[DSL Learning](./DSL-Learning/)** → Understanding DSL philosophy
3. **[Intermediate Examples](./Intermediate/)** → Advanced features
4. **[Advanced Examples](./Advanced/)** → Enterprise patterns
5. **[Sample Project](./Sample-Project/)** → Complete application

### Path 2: Feature-Specific Learning
1. **Want to build a chat app?** → Start with [Conversation Management](./Intermediate/ConversationManagement.swift)
2. **Need image analysis?** → See [Multimodal Content](./Intermediate/MultimodalContent.swift)
3. **Planning production deployment?** → Study [Enterprise Patterns](./Advanced/EnterprisePatterns.swift)
4. **Learning testing?** → Explore [Unit Testing](./Testing/UnitTesting.swift)

### Path 3: Quick Reference
- **Simple chat** → [Simple Chat](./Basic/SimpleChat.swift)
- **Streaming responses** → [Streaming Basics](./Basic/StreamingBasics.swift)
- **Configuration options** → [Configuration Basics](./Basic/ConfigurationBasics.swift)
- **Complete tutorial** → [Step-by-Step Tutorial](./DSL-Learning/StepByStepTutorial.swift)

## 🛠️ Running Examples

### Individual Examples
```swift
// Most examples can be run directly
import SwiftResponsesDSL

// Run example functions
try await simpleChatExample()
```

### Testing Examples
```swift
// Run unit tests
swift test

// Or run specific test functions
try await testParameterValidation()
```

### Sample Application
```swift
// Run the complete chat application
swift run AIChatApp

// Use interactive commands
👤 You: Hello!
🤖 Assistant: Hello! How can I help you today?

👤 You: /help
# Shows available commands
```

## 🔍 Example Features Matrix

| Feature | Basic | Intermediate | Advanced | DSL Learning | Testing | Sample Project |
|---------|-------|-------------|----------|--------------|---------|----------------|
| **Simple Chat** | ✅ | | | | | ✅ |
| **Configuration** | ✅ | | | | | ✅ |
| **Streaming** | ✅ | | | | | ✅ |
| **Conversations** | | ✅ | | | | ✅ |
| **Multimodal** | | ✅ | | | | |
| **Tools** | | ✅ | | | | |
| **Custom Extensions** | | | ✅ | | | |
| **Enterprise Patterns** | | | ✅ | | | |
| **DSL Concepts** | | | | ✅ | | |
| **Step-by-Step Tutorial** | | | | ✅ | | |
| **Unit Testing** | | | | | ✅ | |
| **Full Application** | | | | | | ✅ |

## 🎨 Code Quality Standards

All examples follow these principles:

### ✅ Consistency
- **Uniform Structure**: Each example follows the same pattern
- **Naming Conventions**: Consistent Swift naming throughout
- **Documentation**: Comprehensive comments and docstrings
- **Error Handling**: Consistent error handling patterns

### ✅ Best Practices
- **Type Safety**: Leveraging Swift's type system
- **Performance**: Efficient patterns and memory management
- **Security**: Safe API key handling and data protection
- **Maintainability**: Clean, readable, and well-organized code

### ✅ Educational Value
- **Progressive Complexity**: From simple to advanced concepts
- **Real-World Relevance**: Practical, applicable examples
- **Clear Explanations**: Comprehensive documentation
- **Working Code**: All examples are runnable and functional

## 🚨 Common Issues & Solutions

### API Key Issues
```bash
# Problem: "API key not found"
export OPENAI_API_KEY='your-key-here'

# Problem: "Invalid API key"
# Solution: Check your key on OpenAI Platform
```

### Network Issues
```swift
// Problem: Network timeout
catch LLMError.networkError {
    print("Check your internet connection")
}
```

### Model Issues
```swift
// Problem: "Model not found"
// Solution: Use a valid model name like "gpt-4", "gpt-3.5-turbo"
```

### Rate Limiting
```swift
// Problem: Too many requests
// Solution: Implement rate limiting (see Advanced examples)
```

## 📈 Performance & Scalability

### Basic Examples
- **Fast Startup**: Minimal dependencies and setup
- **Low Memory**: Simple data structures
- **Quick Feedback**: Immediate results

### Intermediate Examples
- **Balanced Performance**: Optimized for common use cases
- **Memory Efficient**: Proper cleanup and management
- **Scalable Patterns**: Ready for growth

### Advanced Examples
- **Enterprise Ready**: Production-grade performance
- **Monitoring**: Built-in performance tracking
- **Optimization**: Advanced patterns for high throughput

## 🤝 Contributing to Examples

### Adding New Examples
1. **Choose Category**: Fit your example into existing categories
2. **Follow Patterns**: Use established structure and naming
3. **Add Documentation**: Comprehensive README and comments
4. **Test Thoroughly**: Ensure examples work correctly
5. **Update Navigation**: Add to this README

### Improving Existing Examples
1. **Enhance Documentation**: Better explanations and comments
2. **Add Features**: New capabilities and use cases
3. **Performance Optimization**: Better patterns and efficiency
4. **Error Handling**: More comprehensive error scenarios

## 📚 Additional Resources

### Documentation
- **[Main README](../README.md)**: Complete package documentation
- **[API Reference](../Sources/SwiftResponsesDSL/SwiftResponsesDSL.swift)**: Detailed API docs
- **[DSL Specification](../Specs/SwiftDSLSpec.md)**: Technical specifications

### Community
- **GitHub Issues**: Report bugs and request features
- **GitHub Discussions**: Ask questions and share ideas
- **Contributing Guide**: How to contribute to the project

### Related Projects
- **SwiftSyntax**: For understanding macro development
- **OpenAI API**: Official API documentation
- **Swift Package Manager**: For dependency management

## 🎉 Getting Started

Ready to explore SwiftResponsesDSL? Here's your roadmap:

### 🚀 Quick Start (5 minutes)
```bash
cd Examples/Basic
swift run SimpleChat.swift
```

### 📚 Deep Dive (30 minutes)
```bash
cd Examples/DSL-Learning
swift run WhatIsDSL.swift
```

### 💻 Build Something (1 hour)
```bash
cd Examples/Sample-Project
swift run
```

### 🏗️ Production Ready (Ongoing)
```bash
cd Examples/Advanced
# Study enterprise patterns
```

---

## 🎯 Next Steps

After exploring these examples, you'll be ready to:

- **Build Your Own Apps**: Using SwiftResponsesDSL patterns
- **Contribute**: Help improve the examples and documentation
- **Extend**: Create custom extensions for your domain
- **Teach Others**: Share your knowledge and experience

**Happy coding with SwiftResponsesDSL!** 🚀✨

*These examples represent the collective knowledge and best practices of the SwiftResponsesDSL community. Each example is carefully crafted to demonstrate specific concepts while maintaining high code quality and educational value.*
