# Advanced Examples

Welcome to **Advanced Examples**! This folder contains enterprise-level patterns and complex integrations that demonstrate the full power of SwiftResponsesDSL. These examples are for experienced developers building production systems.

## 📚 What's Covered

### 1. Custom Extensions (`CustomExtensions.swift`)
Create domain-specific extensions and specialized components:
- Custom parameter types for specific domains
- Domain-specific result builders
- Custom message types with specialized behavior
- Integration with external services and APIs

### 2. Enterprise Patterns (`EnterprisePatterns.swift`)
Production-ready patterns for large-scale deployments:
- Circuit breaker pattern for resilient API interactions
- Retry logic with exponential backoff
- Request batching and rate limiting
- Comprehensive monitoring and logging

## 🚀 Getting Started

### Prerequisites
```swift
// Make sure you have SwiftResponsesDSL imported
import SwiftResponsesDSL

// For enterprise examples, consider these additional imports
import Foundation // For Date, DispatchQueue, etc.

// Enterprise deployments often need:
import os.log        // For system logging
import Combine       // For reactive patterns
import SwiftUI       // For UI integrations (optional)
```

### Enterprise Considerations
- **API Keys**: Use environment variables or secure key management
- **Rate Limits**: Implement proper rate limiting for production
- **Monitoring**: Set up comprehensive logging and metrics
- **Error Handling**: Implement circuit breakers and retry logic
- **Testing**: Use comprehensive test suites

## 📖 Example Structure

### Custom Extensions
```swift
// Domain-specific parameter
struct ReadingLevel: ResponseConfigParameter {
    let level: String

    init(_ level: String) throws {
        // Validation logic
    }

    func apply(to request: inout ResponseRequest) throws {
        // Custom application logic
    }
}

// Usage
let request = try ResponseRequest(
    model: "gpt-4",
    config: {
        ReadingLevel("college")  // Custom parameter
        Temperature(0.7)
    },
    input: {
        user("Explain quantum physics")
    }
)
```

### Enterprise Patterns
```swift
// Circuit breaker for resilience
let circuitBreaker = CircuitBreaker()

let response = try await circuitBreaker.execute {
    let request = try ResponseRequest(model: "gpt-4", input: { user("Hello") })
    return try await client.respond(to: request)
}

// Retry with exponential backoff
let response = try await retry {
    // Request that might fail
}

// Rate limiting
let rateLimiter = RateLimiter(maxTokens: 10, refillRate: 2)
try await rateLimiter.acquire()
// Make request
```

## 💡 Advanced Concepts

### Custom Extensions
- **Domain Modeling**: Create parameters specific to your use case
- **Type Safety**: Leverage Swift's type system for compile-time guarantees
- **Composition**: Combine multiple extensions for complex behavior
- **Reusability**: Build reusable components for your domain

### Enterprise Patterns
- **Resilience**: Handle failures gracefully with circuit breakers
- **Scalability**: Manage load with rate limiting and batching
- **Observability**: Monitor performance and errors
- **Reliability**: Implement retry logic for transient failures

## 🔧 Configuration Tips

### Custom Extensions
```swift
// Create parameter families
struct EducationalLevel: ResponseConfigParameter {
    // Implementation
}

struct ContentRating: ResponseConfigParameter {
    // Implementation
}

// Combine in configurations
config: {
    EducationalLevel("graduate")
    ContentRating("professional")
    Temperature(0.5)
}
```

### Enterprise Patterns
```swift
// Configure circuit breaker
let circuitBreaker = CircuitBreaker(
    failureThreshold: 5,
    recoveryTime: 60.0
)

// Configure rate limiter
let rateLimiter = RateLimiter(
    maxTokens: 100,      // requests per window
    refillRate: 10       // tokens per second
)

// Configure retry logic
let retryConfig = RetryConfiguration(
    maxAttempts: 3,
    baseDelay: 1.0,
    maxDelay: 30.0,
    backoffMultiplier: 2.0
)
```

## 🚨 Common Advanced Issues

### Custom Extensions
```swift
// ❌ Wrong: Tight coupling
struct MyAppParameter: ResponseConfigParameter {
    func apply(to request: inout ResponseRequest) throws {
        // Hard-coded logic specific to one use case
    }
}

// ✅ Correct: Flexible and reusable
struct ConfigurableParameter: ResponseConfigParameter {
    let key: String
    let value: String

    func apply(to request: inout ResponseRequest) throws {
        // Generic logic that can be configured
    }
}
```

### Enterprise Patterns
```swift
// ❌ Wrong: Blocking rate limiter
let rateLimiter = RateLimiter()
for request in requests {
    try await rateLimiter.acquire()  // Blocks for each request
    // Process request
}

// ✅ Correct: Batch processing
let batch = RequestBatch(maxBatchSize: 5, rateLimiter: rateLimiter)
for request in requests {
    batch.add(id: request.id) {
        // Request logic
    }
}
let results = try await batch.execute()
```

## 📈 Performance Considerations

### Memory Management
- **Large Conversations**: Implement memory limits and cleanup
- **Object Reuse**: Reuse clients and configurations when possible
- **Background Processing**: Use appropriate QoS for background tasks

### Network Efficiency
- **Request Batching**: Group related requests to reduce overhead
- **Compression**: Enable response compression for large payloads
- **Connection Reuse**: Maintain persistent connections when possible

### Monitoring Overhead
- **Selective Logging**: Log only necessary information in production
- **Metrics Sampling**: Use sampling for high-frequency metrics
- **Async Processing**: Don't block main threads with monitoring

## 🎯 Best Practices

### 1. Error Handling
```swift
// Comprehensive error handling
do {
    let response = try await client.respond(to: request)
} catch LLMError.invalidValue(let message) {
    // Handle validation errors
    log.error("Validation failed: \(message)")
} catch LLMError.networkError(let message) {
    // Handle network issues
    log.error("Network error: \(message)")
    // Implement retry logic
} catch LLMError.unauthorized {
    // Handle auth issues
    log.error("Authentication failed")
    // Refresh tokens or prompt user
} catch {
    // Handle unexpected errors
    log.error("Unexpected error: \(error)")
    // Fallback to cached responses or offline mode
}
```

### 2. Configuration Management
```swift
// Environment-based configuration
struct AppConfig {
    let apiKey: String
    let baseURL: String
    let maxRetries: Int
    let rateLimitTokens: Int

    static func production() -> AppConfig {
        AppConfig(
            apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "",
            baseURL: "https://api.openai.com/v1/responses",
            maxRetries: 3,
            rateLimitTokens: 50
        )
    }
}
```

### 3. Testing Strategies
```swift
// Mock client for testing
class MockLLMClient: LLMClientProtocol {
    func respond(to request: ResponseRequest) async throws -> Response {
        // Return mock responses for testing
    }
}

// Dependency injection
class ChatService {
    let client: LLMClientProtocol

    init(client: LLMClientProtocol = LLMClient(...)) {
        self.client = client
    }
}
```

## 🔧 Running Examples

### Individual Examples
```swift
// Run specific advanced examples
try await runCustomExtensionsExamples()
try await runEnterpriseExamples()
```

### Production Configuration
```swift
// Production setup
let config = AppConfig.production()
let rateLimiter = RateLimiter(maxTokens: config.rateLimitTokens)
let circuitBreaker = CircuitBreaker()

let client = try LLMClient(baseURLString: config.baseURL)
// Configure authentication...

// Use in your application
let response = try await circuitBreaker.execute {
    try await retry {
        let request = try ResponseRequest(model: "gpt-4", input: { user("Hello") })
        return try await client.respond(to: request)
    }
}
```

## 📊 Enterprise Integration

### Microservices Architecture
```swift
// Service for handling AI requests
class AIRequestService {
    private let client: LLMClient
    private let metrics: MetricsCollector
    private let rateLimiter: RateLimiter

    func processRequest(_ request: AIRequest) async throws -> AIResponse {
        try await rateLimiter.acquire()

        let startTime = Date()
        defer {
            let duration = Date().timeIntervalSince(startTime)
            metrics.record(name: "request.duration", value: duration)
        }

        // Process request...
    }
}
```

### Cloud Deployment
```swift
// Cloud-optimized configuration
let client = try LLMClient(
    baseURLString: ProcessInfo.processInfo.environment["AI_SERVICE_URL"] ?? ""
)

// Use cloud-native patterns
// - Service discovery
// - Configuration management
// - Observability integration
// - Auto-scaling considerations
```

## 🤝 Need Help?

- Check the [main README](../../README.md) for API documentation
- Review the [DSL Learning](../DSL-Learning/) examples for deeper understanding
- Examine the [test cases](../../Tests/) for implementation details
- Consider the [Intermediate](../Intermediate/) examples for prerequisite knowledge

## 🎯 Next Steps

After mastering these advanced examples, you have several options:

- **Deploy to Production**: Use these patterns in production systems
- **Contribute**: Help improve SwiftResponsesDSL with your enterprise experience
- **Create Libraries**: Build domain-specific libraries on top of SwiftResponsesDSL
- **Research**: Explore cutting-edge AI integration patterns

Happy building! 🚀✨

---

*These examples represent enterprise-grade patterns for production AI systems. Consider security, scalability, and monitoring when implementing in production environments.*
