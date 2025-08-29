# Testing Guide

@Metadata {
    @DisplayName("Testing Guide")
    @PageKind(article)
}

Comprehensive testing is crucial for LLM-powered applications. This guide covers strategies, best practices, and examples for testing SwiftResponsesDSL applications effectively.

## Testing Strategy Overview

### Types of Tests

1. **Unit Tests**: Test individual components in isolation
2. **Integration Tests**: Test component interactions
3. **End-to-End Tests**: Test complete user workflows
4. **Performance Tests**: Test system performance and limits
5. **Contract Tests**: Test API compatibility and responses

### Testing Pyramid for LLM Applications

```
End-to-End Tests (Few)
├── Integration Tests (Some)
├── Unit Tests (Many)
└── Static Analysis (Continuous)
```

## Unit Testing

### Testing LLMClient

```swift
import Testing
import SwiftResponsesDSL

@Test("LLMClient initialization with valid parameters")
func testClientInitialization() async throws {
    let client = try LLMClient(
        baseURLString: "https://api.openai.com/v1/responses",
        apiKey: "test-key"
    )

    #expect(client.hasAuthentication == true)
}

@Test("LLMClient initialization with invalid URL")
func testClientInitializationWithInvalidURL() {
    #expect(throws: LLMError.self) {
        _ = try LLMClient(baseURLString: "://invalid", apiKey: "test-key")
    }
}

@Test("LLMClient initialization without API key")
func testClientInitializationWithoutAPIKey() throws {
    let client = try LLMClient(baseURLString: "https://api.openai.com/v1/responses")
    #expect(client.hasAuthentication == false)

    #expect(throws: LLMError.self) {
        try client.validateAuthentication()
    }
}
```

### Testing Request Building

```swift
@Test("ResponseRequest creation with valid parameters")
func testResponseRequestCreation() throws {
    let request = try ResponseRequest(
        model: "gpt-4",
        config: {
            Temperature(0.7)
            MaxOutputTokens(100)
        },
        input: {
            system("You are a helpful assistant")
            user("Hello!")
        }
    )

    #expect(request.model == "gpt-4")
    #expect(request.messages.count == 2)
    #expect(request.stream == false)
}

@Test("ResponseRequest validation with invalid parameters")
func testResponseRequestValidation() {
    #expect(throws: LLMError.self) {
        _ = try ResponseRequest(
            model: "",  // Invalid: empty model
            input: { user("Hello") }
        )
    }

    #expect(throws: LLMError.self) {
        _ = try ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(2.5)  // Invalid: > 2.0
            },
            input: { user("Hello") }
        )
    }
}
```

### Testing Configuration Parameters

```swift
@Test("Temperature parameter validation")
func testTemperatureValidation() throws {
    // Valid temperatures
    _ = try Temperature(0.0)
    _ = try Temperature(1.0)
    _ = try Temperature(2.0)

    // Invalid temperatures
    #expect(throws: LLMError.self) {
        _ = try Temperature(-0.1)
    }

    #expect(throws: LLMError.self) {
        _ = try Temperature(2.1)
    }
}

@Test("MaxOutputTokens parameter validation")
func testMaxOutputTokensValidation() throws {
    // Valid token counts
    let tokens = try MaxOutputTokens(100)
    #expect(tokens.value == 100)

    // Invalid token counts
    #expect(throws: LLMError.self) {
        _ = try MaxOutputTokens(0)
    }

    #expect(throws: LLMError.self) {
        _ = try MaxOutputTokens(-1)
    }
}
```

## Mocking and Test Doubles

### Creating Mock LLM Clients

```swift
class MockLLMClient: LLMClientProtocol {
    var mockResponse: Response?
    var mockError: Error?
    var recordedRequests: [ResponseRequest] = []

    func respond(to request: ResponseRequest) async throws -> Response {
        recordedRequests.append(request)

        if let error = mockError {
            throw error
        }

        guard let response = mockResponse else {
            throw MockError.noMockResponseConfigured
        }

        return response
    }

    func stream(request: ResponseRequest) -> AsyncThrowingStream<ResponseEvent, Error> {
        // Return a mock stream for testing
        AsyncThrowingStream { continuation in
            Task {
                if let error = mockError {
                    continuation.finish(throwing: error)
                } else if let response = mockResponse {
                    continuation.yield(.outputItemAdded(.message(.init(content: "Mock response"))))
                    continuation.yield(.completed(response))
                    continuation.finish()
                } else {
                    continuation.finish(throwing: MockError.noMockResponseConfigured)
                }
            }
        }
    }
}

enum MockError: Error {
    case noMockResponseConfigured
}

// Protocol for dependency injection
protocol LLMClientProtocol {
    func respond(to request: ResponseRequest) async throws -> Response
    func stream(request: ResponseRequest) -> AsyncThrowingStream<ResponseEvent, Error>
}

// Make LLMClient conform to the protocol
extension LLMClient: LLMClientProtocol {}
```

### Using Mocks in Tests

```swift
@Test("Content generator uses LLM client correctly")
func testContentGenerator() async throws {
    // Arrange
    let mockClient = MockLLMClient()
    let mockResponse = Response(
        id: "test-id",
        choices: [
            .init(message: .init(content: "Generated content"), finishReason: "stop")
        ],
        usage: .init(promptTokens: 10, completionTokens: 20, totalTokens: 30)
    )
    mockClient.mockResponse = mockResponse

    let generator = ContentGenerator(client: mockClient)

    // Act
    let result = try await generator.generateContent(topic: "Test Topic")

    // Assert
    #expect(result.content == "Generated content")
    #expect(mockClient.recordedRequests.count == 1)

    let request = mockClient.recordedRequests[0]
    #expect(request.model == "gpt-4")
    #expect(request.messages.count == 2) // system + user messages
}
```

## Integration Testing

### Testing with Real APIs (Controlled)

```swift
class IntegrationTestHelper {
    static func createTestClient() throws -> LLMClient {
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_TEST_KEY"] ?? "test-key"
        return try LLMClient(
            baseURLString: "https://api.openai.com/v1/responses",
            apiKey: apiKey
        )
    }

    static func isAPIKeyAvailable() -> Bool {
        ProcessInfo.processInfo.environment["OPENAI_TEST_KEY"] != nil
    }
}

@Test("Integration test with real API", .enabled(if: IntegrationTestHelper.isAPIKeyAvailable()))
func testRealAPIIntegration() async throws {
    // Arrange
    let client = try IntegrationTestHelper.createTestClient()

    let request = ResponseRequest(
        model: "gpt-3.5-turbo",  // Use cheaper model for tests
        config: {
            Temperature(0.1)        // Deterministic responses
            MaxOutputTokens(50)     // Short responses for speed
        },
        input: {
            user("Say 'Integration test successful' and nothing else")
        }
    )

    // Act
    let response = try await client.respond(to: request)

    // Assert
    #expect(response.choices.count > 0)
    let content = response.choices[0].message.content ?? ""
    #expect(content.contains("Integration test successful"))
    #expect(response.usage?.totalTokens ?? 0 > 0)
}
```

### Testing Streaming Responses

```swift
@Test("Streaming response handling")
func testStreamingResponse() async throws {
    let mockClient = MockLLMClient()

    // Simulate streaming response
    let mockResponse = Response(
        id: "stream-test",
        choices: [.init(message: .init(content: "Hello World"), finishReason: "stop")],
        usage: .init(promptTokens: 5, completionTokens: 10, totalTokens: 15)
    )
    mockClient.mockResponse = mockResponse

    let request = ResponseRequest(
        model: "gpt-4",
        input: { user("Hello") }
    )

    // Act
    var receivedContent = ""
    var eventCount = 0

    let stream = mockClient.stream(request: request)
    for try await event in stream {
        eventCount += 1
        switch event {
        case .outputItemAdded(let item):
            if case .message(let message) = item,
               let content = message.content {
                receivedContent += content
            }
        case .completed:
            break
        }
    }

    // Assert
    #expect(eventCount >= 2) // At least one content event + completed
    #expect(receivedContent == "Hello World")
}
```

## End-to-End Testing

### Testing Complete User Workflows

```swift
class E2ETestHelper {
    let client: LLMClient
    let testTimeout: TimeInterval = 30.0

    init() throws {
        self.client = try LLMClient(
            baseURLString: "https://api.openai.com/v1/responses",
            apiKey: ProcessInfo.processInfo.environment["OPENAI_E2E_KEY"] ?? "test-key"
        )
    }

    func testCompleteConversation() async throws {
        var conversation = ResponseConversation()
        conversation.append(system: "You are a helpful assistant for testing.")

        // Test multiple interactions
        let interactions = [
            "Hello, my name is Test User",
            "What's my name?",
            "Can you help me with Swift programming?",
            "What's the difference between let and var?"
        ]

        for (index, message) in interactions.enumerated() {
            print("Testing interaction \(index + 1): \(message)")

            conversation.append(user: message)

            let response = try await client.respond(to: conversation)
            let content = response.choices.first?.message.content ?? ""

            // Validate response quality
            #expect(!content.isEmpty, "Response should not be empty")
            #expect(content.count > 10, "Response should be substantial")
            #expect(!content.contains("Error"), "Response should not contain errors")

            conversation.append(response: response)
        }

        print("✅ All \(interactions.count) interactions completed successfully")
    }

    func testErrorHandling() async throws {
        let invalidRequest = ResponseRequest(
            model: "invalid-model-name",
            input: { user("This should fail") }
        )

        do {
            _ = try await client.respond(to: invalidRequest)
            #expect(Bool(false), "Expected request to fail with invalid model")
        } catch {
            #expect(error is LLMError, "Should throw LLMError for invalid requests")
        }
    }
}

@Test("End-to-end conversation flow", .enabled(if: ProcessInfo.processInfo.environment["RUN_E2E_TESTS"] == "true"))
func testE2EConversation() async throws {
    let helper = try E2ETestHelper()
    try await helper.testCompleteConversation()
}

@Test("End-to-end error handling")
func testE2EErrorHandling() async throws {
    let helper = try E2ETestHelper()
    try await helper.testErrorHandling()
}
```

## Performance Testing

### Load Testing

```swift
class PerformanceTester {
    let client: LLMClient
    let concurrentRequests: Int

    init(client: LLMClient, concurrentRequests: Int = 5) {
        self.client = client
        self.concurrentRequests = concurrentRequests
    }

    func runLoadTest(requestCount: Int) async throws -> PerformanceReport {
        let request = ResponseRequest(
            model: "gpt-3.5-turbo",  // Use faster model for load testing
            config: {
                Temperature(0.1)
                MaxOutputTokens(50)
            },
            input: { user("Generate a random number between 1 and 100") }
        )

        let startTime = Date()

        // Create concurrent tasks
        let tasks = (0..<requestCount).map { index in
            Task {
                let taskStart = Date()
                do {
                    _ = try await client.respond(to: request)
                    let latency = Date().timeIntervalSince(taskStart)
                    return (index: index, success: true, latency: latency, error: nil)
                } catch {
                    let latency = Date().timeIntervalSince(taskStart)
                    return (index: index, success: false, latency: latency, error: error)
                }
            }
        }

        // Wait for all tasks to complete
        var results: [(index: Int, success: Bool, latency: TimeInterval, error: Error?)] = []

        for task in tasks {
            let result = await task.value
            results.append(result)
        }

        let totalTime = Date().timeIntervalSince(startTime)
        let successfulRequests = results.filter { $0.success }.count
        let failedRequests = results.filter { !$0.success }.count
        let averageLatency = results.map { $0.latency }.reduce(0, +) / Double(results.count)
        let throughput = Double(successfulRequests) / totalTime

        return PerformanceReport(
            totalRequests: requestCount,
            successfulRequests: successfulRequests,
            failedRequests: failedRequests,
            totalTime: totalTime,
            averageLatency: averageLatency,
            throughput: throughput,
            errorRate: Double(failedRequests) / Double(requestCount)
        )
    }
}

struct PerformanceReport {
    let totalRequests: Int
    let successfulRequests: Int
    let failedRequests: Int
    let totalTime: TimeInterval
    let averageLatency: TimeInterval
    let throughput: Double
    let errorRate: Double

    var summary: String {
        """
        Performance Test Results:
        - Total Requests: \(totalRequests)
        - Success Rate: \(String(format: "%.1f", (Double(successfulRequests) / Double(totalRequests)) * 100))%
        - Average Latency: \(String(format: "%.2f", averageLatency))s
        - Throughput: \(String(format: "%.1f", throughput)) req/s
        - Total Time: \(String(format: "%.2f", totalTime))s
        """
    }
}

@Test("Performance load testing", .enabled(if: ProcessInfo.processInfo.environment["RUN_PERFORMANCE_TESTS"] == "true"))
func testPerformanceLoad() async throws {
    let client = try LLMClient(
        baseURLString: "https://api.openai.com/v1/responses",
        apiKey: ProcessInfo.processInfo.environment["OPENAI_PERFORMANCE_KEY"]!
    )

    let tester = PerformanceTester(client: client, concurrentRequests: 3)
    let report = try await tester.runLoadTest(requestCount: 20)

    print(report.summary)

    // Assert performance expectations
    #expect(report.errorRate < 0.1, "Error rate should be less than 10%")
    #expect(report.averageLatency < 10.0, "Average latency should be under 10 seconds")
    #expect(report.successfulRequests > 18, "At least 90% of requests should succeed")
}
```

## Testing Best Practices

### Test Organization

```swift
// Test suite organization
struct SwiftResponsesDSLTests {
    // Unit tests for core components
    @Suite("LLMClient Tests")
    struct LLMClientTests {
        @Test("Client initialization")
        func testInitialization() throws { /* ... */ }

        @Test("Authentication handling")
        func testAuthentication() throws { /* ... */ }
    }

    // Integration tests
    @Suite("Integration Tests")
    struct IntegrationTests {
        @Test("API communication")
        func testAPICommunication() async throws { /* ... */ }
    }

    // Performance tests
    @Suite("Performance Tests")
    struct PerformanceTests {
        @Test("Load testing")
        func testLoadPerformance() async throws { /* ... */ }
    }
}
```

### Test Data Management

```swift
class TestDataManager {
    static func generateTestMessages(count: Int = 5) -> [any ResponseMessage] {
        var messages: [any ResponseMessage] = []
        messages.append(SystemMessage(text: "You are a helpful assistant for testing."))

        for i in 0..<count {
            messages.append(UserMessage(text: "Test message \(i + 1)"))
            messages.append(AssistantMessage(text: "Test response \(i + 1)"))
        }

        return messages
    }

    static func generateTestRequest(model: String = "gpt-4") -> ResponseRequest {
        return try! ResponseRequest(
            model: model,
            config: {
                Temperature(0.7)
                MaxOutputTokens(100)
            },
            input: {
                system("You are a helpful assistant")
                user("Hello, world!")
            }
        )
    }

    static func generateLargeTestContent(wordCount: Int = 1000) -> String {
        let words = ["lorem", "ipsum", "dolor", "sit", "amet", "consectetur", "adipiscing", "elit"]
        return (0..<wordCount).map { _ in words.randomElement()! }.joined(separator: " ")
    }
}
```

### Continuous Integration Testing

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    strategy:
      matrix:
        swift-version: ["6.2"]

    steps:
    - uses: actions/checkout@v4
    - uses: swift-actions/setup-swift@v2
      with:
        swift-version: ${{ matrix.swift-version }}

    - name: Run unit tests
      run: swift test --configuration debug

    - name: Run integration tests
      run: swift test --configuration debug --filter IntegrationTests
      env:
        OPENAI_TEST_KEY: ${{ secrets.OPENAI_TEST_KEY }}

    - name: Run performance tests
      run: swift test --configuration release --filter PerformanceTests
      env:
        OPENAI_PERFORMANCE_KEY: ${{ secrets.OPENAI_PERFORMANCE_KEY }}
        RUN_PERFORMANCE_TESTS: true
```

## Common Testing Patterns

### Testing Error Conditions

```swift
@Test("Network timeout handling")
func testNetworkTimeout() async throws {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 0.1  // Very short timeout

    let client = LLMClient(
        baseURL: URL(string: "https://api.openai.com/v1/responses")!,
        apiKey: "test-key",
        session: URLSession(configuration: config)
    )

    let request = ResponseRequest(model: "gpt-4", input: { user("Test") })

    do {
        _ = try await client.respond(to: request)
        #expect(Bool(false), "Expected timeout error")
    } catch LLMError.networkError {
        #expect(Bool(true), "Network timeout handled correctly")
    } catch {
        #expect(Bool(false), "Expected network timeout, got: \(error)")
    }
}

@Test("Rate limit handling")
func testRateLimitHandling() async throws {
    let mockClient = MockLLMClient()
    mockClient.mockError = LLMError.rateLimit

    let request = TestDataManager.generateTestRequest()

    do {
        _ = try await mockClient.respond(to: request)
        #expect(Bool(false), "Expected rate limit error")
    } catch LLMError.rateLimit {
        #expect(Bool(true), "Rate limit handled correctly")
    }
}
```

### Testing Configuration Validation

```swift
@Test("Configuration parameter combinations")
func testConfigurationCombinations() throws {
    // Test valid combinations
    let validRequest = try ResponseRequest(
        model: "gpt-4",
        config: {
            Temperature(0.7)
            TopP(0.9)
            MaxOutputTokens(100)
            FrequencyPenalty(0.1)
            PresencePenalty(0.1)
        },
        input: { user("Test") }
    )

    #expect(validRequest.config.count == 5)

    // Test conflicting parameters (should not throw, just use last one)
    let conflictingRequest = try ResponseRequest(
        model: "gpt-4",
        config: {
            Temperature(0.5)
            Temperature(0.8)  // This should override the first
        },
        input: { user("Test") }
    )

    let tempParam = conflictingRequest.config.first { $0 is Temperature } as? Temperature
    #expect(tempParam?.value == 0.8)
}
```

## Test Maintenance

### Keeping Tests Up to Date

```swift
// Test helper for API response validation
struct APIResponseValidator {
    static func validateBasicResponse(_ response: Response) {
        #expect(!response.id.isEmpty, "Response should have an ID")
        #expect(response.choices.count > 0, "Response should have at least one choice")
        #expect(response.usage != nil, "Response should include usage information")
    }

    static func validateMessageResponse(_ message: Message) {
        #expect(message.content != nil || message.toolCalls != nil, "Message should have content or tool calls")
        #expect(!message.role.rawValue.isEmpty, "Message should have a valid role")
    }

    static func validateUsage(_ usage: Usage) {
        #expect(usage.promptTokens >= 0, "Prompt tokens should be non-negative")
        #expect(usage.completionTokens >= 0, "Completion tokens should be non-negative")
        #expect(usage.totalTokens == usage.promptTokens + usage.completionTokens, "Total tokens should equal sum of prompt and completion tokens")
    }
}

// Usage in tests
@Test("API response validation")
func testAPIResponseValidation() async throws {
    let client = try createTestClient()
    let request = TestDataManager.generateTestRequest()
    let response = try await client.respond(to: request)

    APIResponseValidator.validateBasicResponse(response)
    APIResponseValidator.validateMessageResponse(response.choices[0].message)
    if let usage = response.usage {
        APIResponseValidator.validateUsage(usage)
    }
}
```

This comprehensive testing guide provides the foundation for building robust, maintainable test suites for SwiftResponsesDSL applications. The strategies and examples here can be adapted to your specific use cases and testing needs.
