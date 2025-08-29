# Troubleshooting Guide

@Metadata {
    @DisplayName("Troubleshooting")
    @PageKind(article)
}

This guide helps you diagnose and resolve common issues when using SwiftResponsesDSL. Each problem includes symptoms, causes, and step-by-step solutions.

## Authentication Issues

### Problem: "Authentication Failed" Error

**Symptoms:**
- `LLMError.authenticationFailed` errors
- HTTP 401 Unauthorized responses
- Requests consistently failing

**Causes & Solutions:**

#### 1. Invalid API Key
```swift
// ❌ Wrong: Hardcoded or invalid key
let client = try LLMClient(
    baseURLString: "https://api.openai.com/v1/responses",
    apiKey: "invalid-key-here"
)

// ✅ Correct: Use environment variables
let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "your-key-here"
let client = try LLMClient(
    baseURLString: "https://api.openai.com/v1/responses",
    apiKey: apiKey
)
```

**Verification Steps:**
```bash
# Check if API key is set
echo $OPENAI_API_KEY

# Test API key validity
curl -H "Authorization: Bearer $OPENAI_API_KEY" \
     https://api.openai.com/v1/models
```

#### 2. Expired API Key
- **Solution**: Regenerate your API key in your LLM provider's dashboard
- **Prevention**: Set up key rotation alerts

#### 3. Incorrect API Key Format
- **Solution**: Ensure the key starts with `sk-` for OpenAI
- **Common Mistake**: Using organization keys instead of user keys

### Problem: "Invalid URL" Error

**Symptoms:**
- `LLMError.invalidURL` during client initialization
- App crashes on startup

**Causes & Solutions:**

```swift
// ❌ Wrong: Missing protocol or typos
let client = try LLMClient(baseURLString: "api.openai.com/v1/responses")

// ✅ Correct: Include protocol
let client = try LLMClient(baseURLString: "https://api.openai.com/v1/responses")

// For custom endpoints
let client = try LLMClient(baseURLString: "https://your-llm-server.com/api/v1/chat")
```

## Network Issues

### Problem: Connection Timeouts

**Symptoms:**
- `LLMError.timeout` errors
- Requests hang indefinitely
- Slow response times

**Solutions:**

#### 1. Network Configuration
```swift
// Create client with custom session configuration
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 60.0  // 60 second timeout
config.timeoutIntervalForResource = 300.0 // 5 minute resource timeout

let client = LLMClient(
    baseURL: URL(string: "https://api.openai.com/v1/responses")!,
    apiKey: "your-key",
    session: URLSession(configuration: config)
)
```

#### 2. Retry Logic Implementation
```swift
struct RetryPolicy {
    let maxAttempts: Int = 3
    let baseDelay: TimeInterval = 1.0
    let maxDelay: TimeInterval = 30.0

    func execute<T: Sendable>(
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error

                if attempt < maxAttempts {
                    let delay = min(baseDelay * pow(2.0, Double(attempt - 1)), maxDelay)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        throw lastError ?? NSError(domain: "RetryError", code: 1)
    }
}

// Usage
let retryPolicy = RetryPolicy()
let response = try await retryPolicy.execute {
    try await client.respond(to: request)
}
```

#### 3. Network Diagnostics
```swift
// Test basic connectivity
func diagnoseNetwork() async {
    let url = URL(string: "https://api.openai.com/v1/models")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

    do {
        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            print("✅ Network connectivity: HTTP \(httpResponse.statusCode)")
        }
    } catch {
        print("❌ Network error: \(error.localizedDescription)")
        print("💡 Check your internet connection and firewall settings")
    }
}
```

### Problem: Rate Limiting

**Symptoms:**
- `LLMError.rateLimit` errors
- HTTP 429 Too Many Requests
- Inconsistent request failures

**Solutions:**

#### 1. Implement Rate Limiting
```swift
class RateLimiter {
    private var requestCount = 0
    private var windowStart = Date()
    private let maxRequestsPerMinute: Int

    init(maxRequestsPerMinute: Int = 50) { // Conservative default
        self.maxRequestsPerMinute = maxRequestsPerMinute
    }

    func checkLimit() async throws {
        let now = Date()
        let timeSinceWindowStart = now.timeIntervalSince(windowStart)

        if timeSinceWindowStart >= 60 {
            // Reset window
            requestCount = 0
            windowStart = now
        }

        if requestCount >= maxRequestsPerMinute {
            let waitTime = 60 - timeSinceWindowStart
            throw LLMError.rateLimit
        }

        requestCount += 1
    }
}

// Usage
let rateLimiter = RateLimiter(maxRequestsPerMinute: 50)

let response = try await rateLimiter.checkLimit()
let result = try await client.respond(to: request)
```

#### 2. Exponential Backoff for Rate Limits
```swift
func handleRateLimit() async throws -> Response {
    var attempt = 0
    let maxAttempts = 5

    while attempt < maxAttempts {
        do {
            return try await client.respond(to: request)
        } catch LLMError.rateLimit {
            attempt += 1
            if attempt < maxAttempts {
                let delay = pow(2.0, Double(attempt)) // Exponential backoff
                print("⏳ Rate limited, waiting \(delay) seconds...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    throw NSError(domain: "RateLimitError", code: 1,
                  userInfo: [NSLocalizedDescriptionKey: "Max retry attempts exceeded"])
}
```

## Response Issues

### Problem: Empty or Incomplete Responses

**Symptoms:**
- Empty response content
- Truncated responses
- `LLMError.invalidResponse` errors

**Causes & Solutions:**

#### 1. Token Limits
```swift
// ❌ Problem: Response cut off due to low token limit
let request = ResponseRequest(
    model: "gpt-4",
    config: {
        MaxOutputTokens(50)  // Too low for detailed responses
    },
    input: { user("Write a detailed analysis...") }
)

// ✅ Solution: Increase token limit
let request = ResponseRequest(
    model: "gpt-4",
    config: {
        MaxOutputTokens(1000)  // Sufficient for detailed responses
    },
    input: { user("Write a detailed analysis...") }
)
```

#### 2. Model Context Window Limits
```swift
// Check model limits
enum ModelLimits {
    static let contextWindows: [String: Int] = [
        "gpt-3.5-turbo": 4096,
        "gpt-4": 8192,
        "gpt-4-turbo": 128000
    ]

    static func isWithinLimits(model: String, inputTokens: Int) -> Bool {
        guard let limit = contextWindows[model] else { return true }
        return inputTokens < limit - 1000 // Leave buffer for output
    }
}

// Usage
let inputTokens = estimateTokens(in: request.input)
if !ModelLimits.isWithinLimits(model: request.model, inputTokens: inputTokens) {
    print("⚠️  Input too long for model context window")
    // Consider chunking or using a larger model
}
```

### Problem: Unexpected Response Format

**Symptoms:**
- JSON parsing errors
- Missing expected fields
- Malformed response data

**Solutions:**

#### 1. Response Validation
```swift
func validateResponse(_ response: Response) throws {
    guard let content = response.choices.first?.message.content else {
        throw ValidationError.emptyResponse
    }

    guard !content.isEmpty else {
        throw ValidationError.emptyContent
    }

    // Check for minimum quality
    if content.count < 10 {
        print("⚠️  Response seems too short: \(content)")
    }

    // Validate JSON if expecting structured output
    if content.hasPrefix("{") || content.hasPrefix("[") {
        guard let _ = content.data(using: .utf8) else {
            throw ValidationError.invalidJSON
        }
    }
}

enum ValidationError: Error {
    case emptyResponse
    case emptyContent
    case invalidJSON
}
```

#### 2. Robust Error Handling
```swift
do {
    let response = try await client.respond(to: request)

    // Validate response
    try validateResponse(response)

    // Process successful response
    if let content = response.choices.first?.message.content {
        print("🤖 Response: \(content)")
    }

} catch LLMError.decodingFailed(let message) {
    print("❌ Response parsing failed: \(message)")
    print("💡 The API returned unexpected data format")
    print("🔧 Check if the model supports the requested features")

} catch ValidationError.emptyResponse {
    print("❌ Empty response from API")
    print("💡 Try rephrasing your request or using a different model")

} catch ValidationError.invalidJSON {
    print("❌ Invalid JSON in response")
    print("💡 Request structured output more clearly")
}
```

## Configuration Issues

### Problem: Parameter Validation Errors

**Symptoms:**
- `LLMError.invalidValue` errors during request creation
- App crashes with parameter validation failures

**Common Issues:**

#### 1. Temperature Out of Range
```swift
// ❌ Invalid temperature values
let invalidRequest = ResponseRequest(
    model: "gpt-4",
    config: {
        Temperature(2.5)  // Too high, max is 2.0
    },
    input: { user("Hello") }
)

// ✅ Valid temperature range
let validRequest = ResponseRequest(
    model: "gpt-4",
    config: {
        Temperature(0.7)  // Valid: 0.0 to 2.0
    },
    input: { user("Hello") }
)
```

#### 2. Token Limit Issues
```swift
// Check token limits before requesting
func validateTokenLimits(_ config: [any ResponseConfigParameter], model: String) throws {
    for parameter in config {
        if let maxTokens = parameter as? MaxOutputTokens {
            let modelLimit = ModelLimits.contextWindows[model] ?? 4096
            if maxTokens.value > modelLimit {
                throw ConfigurationError.tokenLimitExceeded(
                    requested: maxTokens.value,
                    maximum: modelLimit
                )
            }
        }
    }
}

enum ConfigurationError: Error {
    case tokenLimitExceeded(requested: Int, maximum: Int)
}
```

### Problem: Model Not Available

**Symptoms:**
- HTTP 404 errors
- "Model not found" messages
- Inconsistent API behavior

**Solutions:**

#### 1. Model Availability Check
```swift
func checkModelAvailability(client: LLMClient, model: String) async throws -> Bool {
    // This is a simplified check - in practice, you'd call the models endpoint
    let availableModels = ["gpt-3.5-turbo", "gpt-4", "gpt-4-turbo"]

    guard availableModels.contains(model) else {
        throw ModelError.unavailable(model: model)
    }

    return true
}

enum ModelError: Error {
    case unavailable(model: String)
    case deprecated(model: String)
    case requiresUpgrade(model: String)
}

// Usage
do {
    try await checkModelAvailability(client: client, model: request.model)
    let response = try await client.respond(to: request)
} catch ModelError.unavailable(let model) {
    print("❌ Model '\(model)' is not available")
    print("💡 Available models: gpt-3.5-turbo, gpt-4, gpt-4-turbo")
}
```

## Streaming Issues

### Problem: Streaming Connection Drops

**Symptoms:**
- Streaming stops unexpectedly
- Connection timeout errors during streaming
- Incomplete streamed responses

**Solutions:**

#### 1. Connection Stability
```swift
// Configure session for long-running connections
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 300.0     // 5 minutes
config.timeoutIntervalForResource = 3600.0   // 1 hour
config.waitsForConnectivity = true
config.networkServiceType = .responsiveData

let client = LLMClient(
    baseURL: URL(string: "https://api.openai.com/v1/responses")!,
    apiKey: apiKey,
    session: URLSession(configuration: config)
)
```

#### 2. Streaming Error Recovery
```swift
func robustStreaming(request: ResponseRequest, client: LLMClient) async throws -> String {
    var fullResponse = ""
    var retryCount = 0
    let maxRetries = 3

    while retryCount < maxRetries {
        do {
            let stream = client.stream(request: request)

            for try await event in stream {
                switch event {
                case .outputItemAdded(let item):
                    if case .message(let message) = item,
                       let content = message.content {
                        fullResponse += content
                        print(content, terminator: "")
                        fflush(stdout)
                    }
                case .completed:
                    return fullResponse
                }
            }

        } catch {
            retryCount += 1
            if retryCount < maxRetries {
                print("\n🔄 Stream interrupted, retrying... (\(retryCount)/\(maxRetries))")
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            } else {
                print("\n❌ Streaming failed after \(maxRetries) attempts")
                throw error
            }
        }
    }

    return fullResponse
}
```

### Problem: Memory Issues During Streaming

**Symptoms:**
- App becomes unresponsive during long streams
- Memory usage spikes
- Crashes on memory-constrained devices

**Solutions:**

#### 1. Memory-Efficient Streaming
```swift
class MemoryEfficientStreamer {
    private let client: LLMClient
    private let chunkSize = 1024 // 1KB chunks

    init(client: LLMClient) {
        self.client = client
    }

    func streamToFile(request: ResponseRequest, fileURL: URL) async throws {
        let stream = client.stream(request: request)
        let fileHandle = try FileHandle(forWritingTo: fileURL)

        defer {
            try? fileHandle.close()
        }

        for try await event in stream {
            switch event {
            case .outputItemAdded(let item):
                if case .message(let message) = item,
                   let content = message.content?.data(using: .utf8) {
                    // Write directly to file to minimize memory usage
                    fileHandle.write(content)
                }
            case .completed:
                print("✅ Streaming completed, saved to \(fileURL.path)")
            }
        }
    }

    func streamWithCallback(request: ResponseRequest, onChunk: @escaping (String) -> Void) async throws {
        let stream = client.stream(request: request)

        for try await event in stream {
            switch event {
            case .outputItemAdded(let item):
                if case .message(let message) = item,
                   let content = message.content {
                    // Process chunk immediately
                    onChunk(content)
                }
            case .completed:
                print("✅ Streaming completed")
            }
        }
    }
}
```

## Performance Issues

### Problem: Slow Response Times

**Symptoms:**
- Responses taking longer than expected
- Inconsistent performance
- Timeout errors

**Solutions:**

#### 1. Model Selection Optimization
```swift
// Choose appropriate model based on task complexity
func optimizeModel(for task: String, priority: Priority) -> String {
    switch priority {
    case .speed:
        return "gpt-3.5-turbo"  // Fastest
    case .quality:
        return "gpt-4"         // Highest quality
    case .balanced:
        // Analyze task complexity
        if task.count > 1000 || task.contains("analyze") {
            return "gpt-4"     // Complex task
        } else {
            return "gpt-4-turbo" // Good balance
        }
    }
}

enum Priority { case speed, quality, balanced }
```

#### 2. Request Optimization
```swift
// Optimize request parameters for speed
func optimizeForSpeed(_ request: ResponseRequest) -> ResponseRequest {
    var optimized = request

    // Remove expensive parameters for speed
    optimized.config = optimized.config.filter { parameter in
        // Keep only essential parameters
        parameter is Temperature || parameter is MaxOutputTokens
    }

    // Use faster model if possible
    if request.model == "gpt-4" && !requiresComplexity(request.input) {
        optimized.model = "gpt-3.5-turbo"
    }

    return optimized
}

func requiresComplexity(_ input: [any ResponseMessage]) -> Bool {
    let content = input.map { $0.content.first?.text ?? "" }.joined()
    return content.contains("analyze") ||
           content.contains("compare") ||
           content.contains("design") ||
           content.count > 500
}
```

## Testing and Debugging

### Problem: Inconsistent Test Results

**Symptoms:**
- Tests pass locally but fail in CI
- Flaky test behavior
- Race conditions in concurrent tests

**Solutions:**

#### 1. Stable Test Environment
```swift
// Create isolated test client
func createTestClient() throws -> LLMClient {
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 30.0

    return LLMClient(
        baseURL: URL(string: "https://api.openai.com/v1/responses")!,
        apiKey: ProcessInfo.processInfo.environment["OPENAI_TEST_KEY"] ?? "test-key",
        session: URLSession(configuration: config)
    )
}

// Use in tests
@Test func testChatResponse() async throws {
    let client = try createTestClient()

    let request = ResponseRequest(
        model: "gpt-3.5-turbo",  // Use faster model for tests
        config: {
            Temperature(0.1)        // Deterministic responses
            MaxOutputTokens(50)     // Short responses for speed
        },
        input: { user("Say 'Hello, World!' and nothing else") }
    )

    let response = try await client.respond(to: request)

    #expect(response.choices.first?.message.content == "Hello, World!")
}
```

#### 2. Mock Client for Testing
```swift
class MockLLMClient: LLMClientProtocol {
    var mockResponse: Response?
    var mockError: Error?
    var requestHistory: [ResponseRequest] = []

    func respond(to request: ResponseRequest) async throws -> Response {
        requestHistory.append(request)

        if let error = mockError {
            throw error
        }

        guard let response = mockResponse else {
            throw MockError.noMockResponse
        }

        return response
    }
}

enum MockError: Error {
    case noMockResponse
}

// Usage in tests
@Test func testErrorHandling() async throws {
    let mockClient = MockLLMClient()
    mockClient.mockError = LLMError.rateLimit

    do {
        _ = try await mockClient.respond(to: testRequest)
        #expect(Bool(false), "Expected error to be thrown")
    } catch LLMError.rateLimit {
        #expect(Bool(true), "Rate limit error correctly thrown")
    }
}
```

## Platform-Specific Issues

### iOS/macOS Keychain Issues

**Symptoms:**
- Authentication failures on device
- Keychain access errors
- App crashes when accessing stored keys

**Solutions:**

#### 1. Keychain Access Implementation
```swift
// Proper Keychain access for iOS/macOS
class KeychainManager {
    static func storeAPIKey(_ key: String, service: String = "SwiftResponsesDSL") throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "OpenAI_API_Key",
            kSecValueData as String: key.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            // Update existing item
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: "OpenAI_API_Key"
            ]
            let updateAttributes = [kSecValueData as String: key.data(using: .utf8)!]
            SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        } else if status != errSecSuccess {
            throw NSError(domain: "KeychainError", code: Int(status))
        }
    }

    static func retrieveAPIKey(service: String = "SwiftResponsesDSL") throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "OpenAI_API_Key",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "KeychainError", code: Int(status))
        }

        return key
    }
}
```

### Linux Environment Issues

**Symptoms:**
- File system permission errors
- Environment variable issues
- Different behavior than macOS/iOS

**Solutions:**

#### 1. Environment Variable Handling
```swift
// Cross-platform environment variable access
struct Environment {
    static func get(_ key: String) -> String? {
        #if os(Linux)
        return getenv(key).flatMap { String(cString: $0) }
        #else
        return ProcessInfo.processInfo.environment[key]
        #endif
    }

    static func set(_ key: String, value: String) {
        #if os(Linux)
        setenv(key, value, 1)
        #else
        // Note: ProcessInfo doesn't support setting environment variables
        // Use other mechanisms like UserDefaults or configuration files
        #endif
    }
}
```

## Getting Help

### Diagnostic Information Collection

```swift
func collectDiagnostics() -> DiagnosticInfo {
    let info = DiagnosticInfo()

    // System information
    info.osVersion = ProcessInfo.processInfo.operatingSystemVersionString
    info.swiftVersion = "6.2" // Would be detected at runtime

    // Network information
    info.reachability = checkNetworkReachability()

    // API configuration
    info.apiEndpoint = "https://api.openai.com/v1/responses"
    info.hasApiKey = Environment.get("OPENAI_API_KEY") != nil

    // Package information
    info.packageVersion = "1.0.0"

    return info
}

struct DiagnosticInfo {
    var osVersion: String = ""
    var swiftVersion: String = ""
    var reachability: Bool = false
    var apiEndpoint: String = ""
    var hasApiKey: Bool = false
    var packageVersion: String = ""

    func generateReport() -> String {
        """
        === SwiftResponsesDSL Diagnostics ===
        OS Version: \(osVersion)
        Swift Version: \(swiftVersion)
        Network Reachability: \(reachability ? "✅" : "❌")
        API Endpoint: \(apiEndpoint)
        API Key Configured: \(hasApiKey ? "✅" : "❌")
        Package Version: \(packageVersion)
        ===================================
        """
    }
}

// Usage for support requests
let diagnostics = collectDiagnostics()
print(diagnostics.generateReport())
```

### When to Seek Help

1. **Check the Documentation**: Review this troubleshooting guide and the main documentation
2. **Search Existing Issues**: Check GitHub issues for similar problems
3. **Collect Diagnostics**: Use the diagnostic collection above
4. **Provide Minimal Reproduction**: Create a minimal example that reproduces the issue

### Support Resources

- **GitHub Issues**: [Report bugs and request features](https://github.com/RichNasz/SwiftResponsesDSL/issues)
- **Discussions**: [Ask questions and share ideas](https://github.com/RichNasz/SwiftResponsesDSL/discussions)
- **Documentation**: [Complete API reference and guides](./SwiftResponsesDSL.md)

### Problem: Swift 6.2 Toolchain Issues

**Symptoms:**
- "Swift 6.2 required" compilation errors
- Package resolution failures
- Build failures with toolchain-related messages

**Causes & Solutions:**

#### 1. Wrong Swift Version
```bash
# Check current Swift version
swift --version

# Should show: Apple Swift version 6.2.x (or swift-6.2.x for Swiftly)

# If using Swiftly, switch to correct version
swiftly use 6.2

# If using Xcode, ensure Xcode 26 is active
sudo xcode-select -s /Applications/Xcode-26.app
xcodebuild -version  # Should show Xcode 26.x
```

#### 2. Xcode Command Line Tools Version Mismatch
```bash
# Remove old command line tools
sudo rm -rf /Library/Developer/CommandLineTools

# Install fresh command line tools for Xcode 26
xcode-select --install

# Verify Swift version
swift --version
```

#### 3. Swiftly Toolchain Issues
```bash
# Reinstall Swift 6.2 toolchain
swiftly uninstall 6.2
swiftly install 6.2
swiftly use 6.2

# Verify installation
swift --version
swift package --version
```

#### 4. PATH Issues with Swiftly
```bash
# Ensure Swiftly is in your shell profile
echo 'source ~/.swiftly/env.sh' >> ~/.zshrc  # or ~/.bashrc
source ~/.swiftly/env.sh

# Verify Swift is accessible
which swift
swift --version
```

### Problem: Swift Package Manager Issues with Swift 6.2

**Symptoms:**
- Package resolution failures
- "swift-tools-version" errors
- Dependency conflicts

**Solutions:**

#### 1. Update Package.swift for Swift 6.2
```swift
// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "YourPackage",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/RichNasz/SwiftResponsesDSL.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourPackage",
            dependencies: ["SwiftResponsesDSL"]
        )
    ]
)
```

#### 2. Clear Package Cache
```bash
# Remove package caches
rm -rf .build
rm -rf ~/Library/Caches/org.swift.swiftpm

# Reset package resolution
swift package reset

# Clean and resolve
swift package clean
swift package resolve
```

#### 3. Update Dependencies
```bash
# Update all dependencies
swift package update

# Check for compatibility issues
swift package diagnose
```

### Problem: CI/CD Pipeline Failures with Swift 6.2

**Symptoms:**
- GitHub Actions failures
- "Swift 6.2 not found" errors
- Inconsistent build results

**Solutions:**

#### 1. Update GitHub Actions Workflow
```yaml
# .github/workflows/ci.yml
- name: Setup Swift
  uses: swift-actions/setup-swift@v2
  with:
    swift-version: '6.2'

# For macOS, ensure latest Xcode
- name: Setup Xcode
  run: |
    # GitHub macOS runners include Xcode beta
    sudo xcode-select -s /Applications/Xcode.app
    xcodebuild -version
```

#### 2. Use Swiftly in CI
```yaml
# Alternative approach using Swiftly
- name: Setup Swiftly
  run: |
    curl -L https://github.com/swiftlang/swiftly/releases/latest/download/swiftly-install.sh | bash
    source ~/.swiftly/env.sh
    swiftly install 6.2
    swiftly use 6.2
```

#### 3. Specify macOS Version for Xcode 26
```yaml
jobs:
  test:
    runs-on: macos-14  # Specify Sonoma for Xcode 26 support
    # macos-latest will include Xcode beta
```

### Problem: IDE Integration Issues

**Symptoms:**
- Xcode doesn't recognize Swift 6.2 features
- Code completion not working properly
- Build errors in IDE but not command line

**Solutions:**

#### 1. Xcode Configuration
- Ensure Xcode 26+ is installed and selected
- Reset Xcode's package cache: `File > Packages > Reset Package Caches`
- Clean build folder: `Product > Clean Build Folder`
- Restart Xcode after toolchain changes

#### 2. VS Code / Other Editors
```json
// .vscode/settings.json
{
    "swift.path": "/usr/local/swift/usr/bin/swift",
    "swift.buildArguments": [
        "--configuration", "debug"
    ],
    "swift.testArguments": [
        "--parallel"
    ]
}
```

#### 3. Command Line Verification
```bash
# Ensure command line and IDE use same toolchain
which swift
swift --version

# In Xcode: Check Xcode > Toolchains
# Should show Swift 6.2 toolchain
```

This troubleshooting guide covers the most common issues developers encounter. Most problems can be resolved by following these systematic approaches. If you encounter an issue not covered here, please contribute back by creating a GitHub issue with your solution.
