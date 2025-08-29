# Migration Guide

@Metadata {
    @DisplayName("Migration Guide")
    @PageKind(article)
}

This guide helps you migrate between versions of SwiftResponsesDSL. Each section covers breaking changes, new features, and migration steps.

## Latest Version - 1.0.0

**Current stable release with authentication support and comprehensive documentation.**

### What's New in 1.0.0

✅ **API Key Authentication**: Secure authentication for LLM APIs
✅ **GitHub Actions CI/CD**: Automated testing and documentation
✅ **Comprehensive Documentation**: Complete DocC catalog and examples
✅ **Production Ready**: Enterprise-grade error handling and logging

### Migration from 1.0.0-alpha

If you're using the alpha version, here's how to migrate:

```swift
// Before (Alpha)
let client = try LLMClient(baseURL: "https://api.openai.com/v1/responses")

// After (1.0.0)
let client = try LLMClient(
    baseURLString: "https://api.openai.com/v1/responses",
    apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!
)
```

**Breaking Changes:**
- API key is now required for production use
- `baseURL` parameter changed to `baseURLString`
- Added `apiKey` parameter to initializer

## Future Version Planning

### Upcoming Features (2.0.0)

**Planned for Q2 2025**

#### New Features
- **Macro Support**: Compile-time code generation for boilerplate reduction
- **Advanced Streaming**: Enhanced streaming with better error recovery
- **Batch Processing**: Process multiple requests efficiently
- **Response Caching**: Intelligent caching layer for improved performance
- **Custom Model Support**: Easy integration with custom LLM models

#### Breaking Changes
- **Swift Version**: Minimum Swift 6.2 required
- **API Changes**: Some parameter names may change for consistency
- **Deprecation**: Certain legacy methods will be deprecated

#### Migration Preparation

```swift
// Current (1.0.0)
let client = try LLMClient(
    baseURLString: "https://api.openai.com/v1/responses",
    apiKey: "your-key"
)

// Future (2.0.0) - Preview
let client = try LLMClient(
    baseURLString: "https://api.openai.com/v1/responses",
    apiKey: "your-key",
    cache: ResponseCache(duration: 3600)  // New caching support
)
```

### Preparing for 2.0.0

1. **Update Swift Version**
   ```bash
   # Ensure you're using Swift 6.2+
   swift --version
   ```

2. **Review API Usage**
   - Check for deprecated method usage
   - Review error handling patterns
   - Consider performance optimization opportunities

3. **Test Migration**
   ```swift
   // Test with new features
   #if swift(>=6.2)
   let client = try LLMClient(
       baseURLString: "https://api.openai.com/v1/responses",
       apiKey: "your-key",
       cache: ResponseCache(duration: 3600)
   )
   #endif
   ```

## Version Compatibility Matrix

| SwiftResponsesDSL | Swift Version | iOS | macOS | Linux |
|-------------------|---------------|-----|-------|-------|
| 1.0.0            | 6.2+         | 15+ | 12+   | Ubuntu 22.04+ |
| 2.0.0 (Planned)  | 6.2+         | 15+ | 12+   | Ubuntu 22.04+ |

## Migration Strategies

### Strategy 1: Gradual Migration (Recommended)

1. **Update Dependencies**
   ```swift
   // Package.swift
   dependencies: [
       .package(url: "https://github.com/RichNasz/SwiftResponsesDSL.git", from: "1.0.0")
   ]
   ```

2. **Update Code Incrementally**
   ```swift
   // Phase 1: Update client initialization
   let client = try LLMClient(
       baseURLString: "https://api.openai.com/v1/responses",
       apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!
   )

   // Phase 2: Update error handling
   do {
       let response = try await client.respond(to: request)
       // Handle success
   } catch LLMError.authenticationFailed {
       // Handle authentication errors
   } catch {
       // Handle other errors
   }

   // Phase 3: Add new features as needed
   ```

3. **Test Thoroughly**
   - Run existing tests
   - Add new tests for authentication
   - Test error scenarios

### Strategy 2: Big Bang Migration

For smaller projects, you can migrate everything at once:

```swift
// Before
class OldService {
    let client = try! LLMClient(baseURL: "https://api.openai.com/v1/responses")

    func chat(message: String) async throws -> String {
        let request = ResponseRequest(model: "gpt-4", input: { user(message) })
        let response = try await client.respond(to: request)
        return response.choices.first?.message.content ?? ""
    }
}

// After
class NewService {
    let client = try! LLMClient(
        baseURLString: "https://api.openai.com/v1/responses",
        apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!
    )

    func chat(message: String) async throws -> String {
        let request = try ResponseRequest(model: "gpt-4", input: { user(message) })
        let response = try await client.respond(to: request)
        return response.choices.first?.message.content ?? ""
    }

    func validateConnection() throws {
        try client.validateAuthentication()
    }
}
```

## Common Migration Issues

### Issue 1: API Key Management

**Problem**: "How do I manage API keys securely?"

**Solutions**:

#### Environment Variables (Recommended)
```bash
# Set in your environment
export OPENAI_API_KEY="your-secure-key"

# Or use a .env file with a library like swift-dotenv
```

#### Keychain Integration (iOS/macOS)
```swift
import Security  // iOS/macOS only

class KeychainManager {
    static func storeAPIKey(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "SwiftResponsesDSL",
            kSecAttrAccount as String: "OpenAI_API_Key",
            kSecValueData as String: key.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            // Update existing
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "SwiftResponsesDSL",
                kSecAttrAccount as String: "OpenAI_API_Key"
            ]
            let updateAttributes = [kSecValueData as String: key.data(using: .utf8)!]
            SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        }
    }

    static func retrieveAPIKey() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "SwiftResponsesDSL",
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

// Usage
let apiKey = try KeychainManager.retrieveAPIKey()
let client = try LLMClient(
    baseURLString: "https://api.openai.com/v1/responses",
    apiKey: apiKey
)
```

### Issue 2: Error Handling Changes

**Problem**: "My error handling code broke after migration"

**Solutions**:

#### Update Error Handling
```swift
// Before (might not handle all cases)
do {
    let response = try await client.respond(to: request)
} catch {
    print("Error: \(error)")
}

// After (comprehensive error handling)
do {
    let response = try await client.respond(to: request)
} catch LLMError.authenticationFailed {
    print("Authentication failed - check your API key")
    // Handle auth failure (retry with new key, show login, etc.)
} catch LLMError.rateLimit {
    print("Rate limit exceeded - implement backoff")
    // Handle rate limiting (exponential backoff, queue requests, etc.)
} catch LLMError.networkError(let message) {
    print("Network error: \(message)")
    // Handle network issues (retry, offline mode, etc.)
} catch LLMError.invalidResponse {
    print("Invalid response from API")
    // Handle API response issues (fallback, alternative API, etc.)
} catch {
    print("Unexpected error: \(error)")
    // Handle any other errors
}
```

### Issue 3: Parameter Validation

**Problem**: "Getting validation errors for parameters that worked before"

**Solutions**:

#### Check Parameter Ranges
```swift
// Temperature: 0.0 to 2.0
let temperature = try Temperature(0.7)  // ✅ Valid

// MaxOutputTokens: Must be positive
let maxTokens = try MaxOutputTokens(1000)  // ✅ Valid

// TopP: 0.0 to 1.0
let topP = try TopP(0.9)  // ✅ Valid

// Common mistakes
let invalidTemp = try Temperature(2.5)  // ❌ Throws error
let invalidTokens = try MaxOutputTokens(-1)  // ❌ Throws error
```

## Testing After Migration

### Migration Test Suite

```swift
import Testing
import SwiftResponsesDSL

@Test("Migration: Basic functionality still works")
func testBasicFunctionalityAfterMigration() async throws {
    let client = try LLMClient(
        baseURLString: "https://api.openai.com/v1/responses",
        apiKey: "test-key"
    )

    let request = try ResponseRequest(
        model: "gpt-4",
        input: { user("Hello") }
    )

    // Should not throw during request creation
    #expect(request.model == "gpt-4")
    #expect(request.messages.count == 1)
}

@Test("Migration: Authentication works")
func testAuthenticationAfterMigration() throws {
    let clientWithAuth = try LLMClient(
        baseURLString: "https://api.openai.com/v1/responses",
        apiKey: "test-key"
    )
    #expect(clientWithAuth.hasAuthentication == true)

    let clientWithoutAuth = try LLMClient(
        baseURLString: "https://api.openai.com/v1/responses"
    )
    #expect(clientWithoutAuth.hasAuthentication == false)
}

@Test("Migration: Error handling improved")
func testErrorHandlingAfterMigration() {
    let client = try LLMClient(
        baseURLString: "https://api.openai.com/v1/responses",
        apiKey: "test-key"
    )

    #expect(throws: LLMError.self) {
        try client.validateAuthentication()  // Test key is invalid
    }
}
```

## Performance Considerations

### Migration Performance Impact

```swift
class PerformanceMonitor {
    private var metrics: [String: TimeInterval] = [:]

    func measureMigrationImpact() async throws {
        // Test old approach simulation
        let startOld = Date()
        // Simulate old approach...
        let oldTime = Date().timeIntervalSince(startOld)

        // Test new approach
        let client = try LLMClient(
            baseURLString: "https://api.openai.com/v1/responses",
            apiKey: "test-key"
        )

        let request = try ResponseRequest(
            model: "gpt-4",
            input: { user("Test") }
        )

        let startNew = Date()
        // New approach doesn't make API call, just validates
        let newTime = Date().timeIntervalSince(startNew)

        print("Migration performance impact:")
        print("- Old approach: \(oldTime)s")
        print("- New approach: \(newTime)s")
        print("- Improvement: \((oldTime - newTime) / oldTime * 100)%")
    }
}
```

## Rollback Strategy

### If Migration Fails

1. **Immediate Rollback**
   ```swift
   // Temporarily revert to old version
   // Package.swift
   dependencies: [
       .package(url: "https://github.com/RichNasz/SwiftResponsesDSL.git", from: "1.0.0-alpha")
   ]
   ```

2. **Gradual Rollback**
   ```swift
   // Use conditional compilation for gradual migration
   #if swift(>=6.2) && SWIFTRESPONSESDSL_1_0
   let client = try LLMClient(
       baseURLString: "https://api.openai.com/v1/responses",
       apiKey: "your-key"
   )
   #else
   let client = try LLMClient(baseURL: "https://api.openai.com/v1/responses")
   #endif
   ```

3. **Feature Flags**
   ```swift
   class MigrationManager {
       static var useNewVersion = false

       static func createClient() throws -> LLMClient {
           if useNewVersion {
               return try LLMClient(
                   baseURLString: "https://api.openai.com/v1/responses",
                   apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!
               )
           } else {
               return try LLMClient(baseURL: "https://api.openai.com/v1/responses")
           }
       }
   }
   ```

## Getting Help

### Migration Support

- **GitHub Issues**: Report migration problems
- **Discussions**: Ask migration questions
- **Documentation**: Check this guide and examples
- **Community**: Join SwiftResponsesDSL discussions

### Support Checklist

Before migrating, ensure:
- [ ] Backup your current working code
- [ ] Review breaking changes in release notes
- [ ] Update Swift version if needed
- [ ] Test migration in a separate branch
- [ ] Have a rollback plan ready
- [ ] Update CI/CD pipelines
- [ ] Notify team members of migration

### Contact Information

- **Issues**: [GitHub Issues](https://github.com/RichNasz/SwiftResponsesDSL/issues)
- **Discussions**: [GitHub Discussions](https://github.com/RichNasz/SwiftResponsesDSL/discussions)
- **Documentation**: [Full Documentation](./SwiftResponsesDSL.md)

## Future Migration Planning

### Staying Up to Date

1. **Watch Repository**: Get notified of new releases
2. **Read Release Notes**: Understand changes before updating
3. **Test Early**: Use beta/rc versions for testing
4. **Plan Migrations**: Schedule migration time during low-traffic periods

### Long-term Compatibility

```swift
// Future-proof your code
protocol LLMService {
    func sendMessage(_ message: String) async throws -> String
}

// Current implementation
class CurrentLLMService: LLMService {
    let client = try! LLMClient(
        baseURLString: "https://api.openai.com/v1/responses",
        apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!
    )

    func sendMessage(_ message: String) async throws -> String {
        let request = try ResponseRequest(model: "gpt-4", input: { user(message) })
        let response = try await client.respond(to: request)
        return response.choices.first?.message.content ?? ""
    }
}

// Easy to swap implementations later
let service: LLMService = CurrentLLMService()
let response = try await service.sendMessage("Hello!")
```

This migration guide will be updated with each major release to help you smoothly transition between versions while maintaining compatibility and taking advantage of new features.
