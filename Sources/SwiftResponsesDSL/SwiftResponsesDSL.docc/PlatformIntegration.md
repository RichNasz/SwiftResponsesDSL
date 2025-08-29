# Platform Integration Guide

@Metadata {
    @DisplayName("Platform Integration")
    @PageKind(article)
}

SwiftResponsesDSL works seamlessly across all Swift platforms. This guide shows you how to integrate it into different types of applications, from mobile apps to server-side services.

## Swift 6.2 Toolchain Setup by Platform

Before integrating SwiftResponsesDSL, ensure you have the correct Swift 6.2 toolchain installed for your platform:

### macOS - Xcode Setup
```bash
# Download Xcode 26+ (beta) from:
# https://developer.apple.com/xcode/

# Install command line tools
xcode-select --install

# Verify Xcode and Swift versions
xcodebuild -version  # Should show Xcode 26.x
swift --version      # Should show swift-6.2.x
```

**Requirements:**
- macOS 14.0+ (Sonoma) for Xcode 26
- Xcode 26.0+ (currently in beta)

### macOS - Swiftly Setup (Command Line)
```bash
# Install Swiftly
curl -L https://github.com/swiftlang/swiftly/releases/latest/download/swiftly-install.sh | bash
source ~/.swiftly/env.sh

# Install and use Swift 6.2
swiftly install 6.2
swiftly use 6.2

# Verify
swift --version  # Should show: swift-6.2.x
```

### Linux - Direct Installation
```bash
# Ubuntu 22.04 example
wget https://swift.org/builds/swift-6.2-release/ubuntu2204/swift-6.2-RELEASE/swift-6.2-RELEASE-ubuntu22.04.tar.gz
tar xzf swift-6.2-RELEASE-ubuntu22.04.tar.gz
export PATH=$PWD/swift-6.2-RELEASE-ubuntu22.04/usr/bin:$PATH

# Verify
swift --version
```

### CI/CD - GitHub Actions
```yaml
- name: Setup Swift
  uses: swift-actions/setup-swift@v2
  with:
    swift-version: '6.2'
```

### Cross-Platform Considerations

- **Swiftly** is recommended for managing multiple Swift versions across platforms
- **Xcode 26+** is required for macOS development with full Swift 6.2 support
- **CI/CD pipelines** should explicitly specify Swift 6.2 to ensure compatibility
- **Team development** should standardize on toolchain versions for consistency

### Troubleshooting Toolchain Issues

**"Swift 6.2 required" error:**
```bash
# Check current version
swift --version

# If using Swiftly, switch versions
swiftly use 6.2

# If using Xcode, ensure Xcode 26 is selected
sudo xcode-select -s /Applications/Xcode-26.app
```

**Missing Swift command:**
```bash
# macOS with Swiftly
source ~/.swiftly/env.sh

# Linux with manual install
export PATH=/path/to/swift/usr/bin:$PATH
```

## iOS Integration

### SwiftUI Chat Interface

Create a modern chat interface with SwiftUI:

```swift
import SwiftUI
import SwiftResponsesDSL

struct ChatView: View {
    @StateObject private var chatModel = ChatViewModel()
    @State private var messageText = ""

    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(chatModel.messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }

            HStack {
                TextField("Type your message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
                .disabled(messageText.isEmpty || chatModel.isLoading)
                .padding(.trailing)
            }
            .padding(.bottom)
        }
        .navigationTitle("AI Chat")
    }

    private func sendMessage() {
        let text = messageText
        messageText = ""
        Task {
            await chatModel.sendMessage(text)
        }
    }
}

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false

    private var conversation = ResponseConversation()
    private var client: LLMClient?

    init() {
        setupClient()
        setupConversation()
    }

    private func setupClient() {
        do {
            // Use Keychain for API key storage in production
            let apiKey = try KeychainManager.getAPIKey()
            client = try LLMClient(
                baseURLString: "https://api.openai.com/v1/responses",
                apiKey: apiKey
            )
        } catch {
            print("Failed to initialize client: \(error)")
        }
    }

    private func setupConversation() {
        conversation.append(system: "You are a helpful AI assistant in a mobile chat app. Keep responses concise and friendly.")
    }

    func sendMessage(_ text: String) async {
        let userMessage = ChatMessage(content: text, isUser: true, timestamp: Date())
        messages.append(userMessage)
        conversation.append(user: text)

        guard let client = client else {
            let errorMessage = ChatMessage(content: "AI service unavailable", isUser: false, timestamp: Date())
            messages.append(errorMessage)
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await client.chat(conversation: conversation)

            if let content = response.choices.first?.message.content {
                let aiMessage = ChatMessage(content: content, isUser: false, timestamp: Date())
                messages.append(aiMessage)
                conversation.append(response: response)
            }
        } catch {
            let errorMessage = ChatMessage(content: "Error: \(error.localizedDescription)", isUser: false, timestamp: Date())
            messages.append(errorMessage)
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer() }

            Text(message.content)
                .padding(12)
                .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(16)
                .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)

            if !message.isUser { Spacer() }
        }
    }
}

// Keychain Manager for secure API key storage
class KeychainManager {
    static func getAPIKey() throws -> String {
        // Implementation for secure key storage
        // In production, use Keychain Services
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return key
        }
        throw NSError(domain: "KeychainError", code: 1, userInfo: [NSLocalizedDescriptionKey: "API key not found"])
    }
}
```

### UIKit Integration

For existing UIKit applications:

```swift
import UIKit
import SwiftResponsesDSL

class ChatViewController: UIViewController {
    private var messages: [ChatMessage] = []
    private var conversation = ResponseConversation()
    private var client: LLMClient?

    private let tableView = UITableView()
    private let messageInput = UITextField()
    private let sendButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupClient()
        setupConversation()
    }

    private func setupClient() {
        do {
            // Load API key from secure storage
            let apiKey = try SecureStorage.getAPIKey()
            client = try LLMClient(
                baseURLString: "https://api.openai.com/v1/responses",
                apiKey: apiKey
            )
        } catch {
            showError("Failed to initialize AI service: \(error.localizedDescription)")
        }
    }

    private func setupConversation() {
        conversation.append(system: "You are a helpful assistant in a mobile app.")
    }

    @objc private func sendMessage() {
        guard let text = messageInput.text, !text.isEmpty else { return }
        messageInput.text = ""

        let userMessage = ChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        tableView.reloadData()

        conversation.append(user: text)
        sendButton.isEnabled = false

        Task {
            await generateResponse()
        }
    }

    private func generateResponse() async {
        guard let client = client else { return }

        do {
            let response = try await client.chat(conversation: conversation)

            if let content = response.choices.first?.message.content {
                let aiMessage = ChatMessage(content: content, isUser: false)
                await MainActor.run {
                    messages.append(aiMessage)
                    tableView.reloadData()
                    sendButton.isEnabled = true
                }
                conversation.append(response: response)
            }
        } catch {
            await MainActor.run {
                showError("Failed to get response: \(error.localizedDescription)")
                sendButton.isEnabled = true
            }
        }
    }
}

// Secure Storage Implementation
class SecureStorage {
    static func getAPIKey() throws -> String {
        // Use iOS Keychain Services
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "OpenAI",
            kSecAttrAccount as String: "APIKey",
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "SecureStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "API key not found"])
        }

        return key
    }
}
```

## macOS Integration

### AppKit Desktop Application

```swift
import AppKit
import SwiftResponsesDSL

class ChatWindowController: NSWindowController {
    private var conversation = ResponseConversation()
    private var client: LLMClient?

    @IBOutlet private var textView: NSTextView!
    @IBOutlet private var inputField: NSTextField!
    @IBOutlet private var sendButton: NSButton!

    override func windowDidLoad() {
        super.windowDidLoad()
        setupClient()
        setupConversation()
        setupUI()
    }

    private func setupClient() {
        do {
            // Use macOS Keychain
            let apiKey = try KeychainAccess.getAPIKey()
            client = try LLMClient(
                baseURLString: "https://api.openai.com/v1/responses",
                apiKey: apiKey
            )
        } catch {
            showError("Failed to initialize AI client: \(error.localizedDescription)")
        }
    }

    private func setupConversation() {
        conversation.append(system: "You are a helpful AI assistant in a desktop application.")
    }

    @IBAction func sendMessage(_ sender: Any) {
        let text = inputField.stringValue
        guard !text.isEmpty else { return }

        appendToChat("You: \(text)", isUser: true)
        inputField.stringValue = ""
        sendButton.isEnabled = false

        conversation.append(user: text)

        Task {
            await generateResponse()
        }
    }

    private func generateResponse() async {
        guard let client = client else { return }

        do {
            let response = try await client.chat(conversation: conversation)

            if let content = response.choices.first?.message.content {
                await MainActor.run {
                    appendToChat("Assistant: \(content)", isUser: false)
                    sendButton.isEnabled = true
                }
                conversation.append(response: response)
            }
        } catch {
            await MainActor.run {
                appendToChat("Error: \(error.localizedDescription)", isUser: false)
                sendButton.isEnabled = true
            }
        }
    }

    private func appendToChat(_ text: String, isUser: Bool) {
        let attributedString = NSAttributedString(
            string: text + "\n\n",
            attributes: [
                .foregroundColor: isUser ? NSColor.blue : NSColor.textColor,
                .font: NSFont.systemFont(ofSize: 12)
            ]
        )

        textView.textStorage?.append(attributedString)
        textView.scrollToEndOfDocument(nil)
    }
}
```

## Server-Side Swift Integration

### Vapor Web Framework

```swift
import Vapor
import SwiftResponsesDSL

struct AIController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let aiRoutes = routes.grouped("ai")
        aiRoutes.post("chat", use: chat)
        aiRoutes.post("stream", use: stream)
    }

    func chat(req: Request) async throws -> ChatResponse {
        let request = try req.content.decode(ChatRequest.self)

        let client = try LLMClient(
            baseURLString: Environment.get("OPENAI_BASE_URL") ?? "https://api.openai.com/v1/responses",
            apiKey: Environment.get("OPENAI_API_KEY")!
        )

        var conversation = ResponseConversation()
        conversation.append(system: request.systemPrompt ?? "You are a helpful assistant.")
        conversation.append(user: request.message)

        let response = try await client.chat(conversation: conversation)

        guard let content = response.choices.first?.message.content else {
            throw Abort(.internalServerError, reason: "No response generated")
        }

        return ChatResponse(message: content)
    }

    func stream(req: Request) -> Response {
        let response = Response(status: .ok, headers: ["Content-Type": "text/plain"])

        response.writeString("🤖 Assistant: ")

        // Note: Streaming in Vapor requires special handling
        // This is a simplified example
        Task {
            do {
                let client = try LLMClient(
                    baseURLString: "https://api.openai.com/v1/responses",
                    apiKey: Environment.get("OPENAI_API_KEY")!
                )

                let streamRequest = ResponseRequest(
                    model: "gpt-4",
                    input: { user("Tell me a story") }
                )

                let stream = client.stream(request: streamRequest)

                for try await event in stream {
                    switch event {
                    case .outputItemAdded(let item):
                        if case .message(let message) = item,
                           let content = message.content {
                            response.writeString(content)
                        }
                    case .completed:
                        response.writeString("\n✅ Complete!")
                        response.complete()
                    default:
                        break
                    }
                }
            } catch {
                response.complete(error.localizedDescription)
            }
        }

        return response
    }
}

struct ChatRequest: Content {
    let message: String
    let systemPrompt: String?
}

struct ChatResponse: Content {
    let message: String
}
```

### Hummingbird Server

```swift
import Hummingbird
import SwiftResponsesDSL

struct AIController {
    let client: LLMClient

    init() throws {
        self.client = try LLMClient(
            baseURLString: Environment.get("OPENAI_BASE_URL") ?? "https://api.openai.com/v1/responses",
            apiKey: Environment.get("OPENAI_API_KEY")!
        )
    }

    func chat(request: Request, context: some RequestContext) async throws -> ChatResponse {
        let chatRequest = try await request.decode(as: ChatRequest.self, context: context)

        var conversation = ResponseConversation()
        conversation.append(system: chatRequest.systemPrompt ?? "You are a helpful assistant.")
        conversation.append(user: chatRequest.message)

        let response = try await client.chat(conversation: conversation)

        guard let content = response.choices.first?.message.content else {
            throw HTTPError(.internalServerError, message: "No response generated")
        }

        return ChatResponse(message: content)
    }

    func stream(request: Request, context: some RequestContext) async throws -> Response {
        let streamRequest = try await request.decode(as: StreamRequest.self, context: context)

        let llmRequest = ResponseRequest(
            model: streamRequest.model,
            input: { user(streamRequest.message) }
        )

        let stream = client.stream(request: llmRequest)

        return StreamingResponse(stream: stream)
    }
}

struct StreamingResponse: ResponseGenerator {
    let stream: AsyncThrowingStream<ResponseEvent, Error>

    func response(from request: Request, context: some RequestContext) async throws -> Response {
        let response = Response(status: .ok, headers: ["Content-Type": "text/plain"])

        var fullResponse = ""
        for try await event in stream {
            switch event {
            case .outputItemAdded(let item):
                if case .message(let message) = item,
                   let content = message.content {
                    response.write(content)
                    fullResponse += content
                }
            case .completed:
                response.end()
                return response
            default:
                break
            }
        }

        response.end()
        return response
    }
}
```

## Command-Line Tools

### Basic CLI Application

```swift
import Foundation
import SwiftResponsesDSL

@main
struct LLMCLI {
    static func main() async {
        let arguments = CommandLine.arguments

        guard arguments.count >= 2 else {
            print("Usage: \(arguments[0]) <message> [--model <model>] [--stream]")
            exit(1)
        }

        let message = arguments[1]

        // Parse arguments
        var model = "gpt-4"
        var useStreaming = false

        var index = 2
        while index < arguments.count {
            switch arguments[index] {
            case "--model":
                if index + 1 < arguments.count {
                    model = arguments[index + 1]
                    index += 2
                } else {
                    print("Error: --model requires a value")
                    exit(1)
                }
            case "--stream":
                useStreaming = true
                index += 1
            default:
                print("Unknown argument: \(arguments[index])")
                exit(1)
            }
        }

        // Initialize client
        let client: LLMClient
        do {
            let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "your-api-key"
            client = try LLMClient(
                baseURLString: "https://api.openai.com/v1/responses",
                apiKey: apiKey
            )
        } catch {
            print("Error initializing client: \(error.localizedDescription)")
            exit(1)
        }

        // Generate response
        do {
            if useStreaming {
                try await streamResponse(client: client, model: model, message: message)
            } else {
                try await simpleResponse(client: client, model: model, message: message)
            }
        } catch {
            print("Error: \(error.localizedDescription)")
            exit(1)
        }
    }

    static func simpleResponse(client: LLMClient, model: String, message: String) async throws {
        let response = try await client.chat(model: model, message: message)

        if let content = response.choices.first?.message.content {
            print("🤖 Assistant: \(content)")
        } else {
            print("No response generated")
        }
    }

    static func streamResponse(client: LLMClient, model: String, message: String) async throws {
        let request = ResponseRequest(
            model: model,
            input: { user(message) }
        )

        let stream = client.stream(request: request)

        print("🤖 Assistant: ", terminator: "")

        for try await event in stream {
            switch event {
            case .outputItemAdded(let item):
                if case .message(let message) = item,
                   let content = message.content {
                    print(content, terminator: "")
                    fflush(stdout)
                }
            case .completed:
                print("\n✅ Complete!")
            default:
                break
            }
        }
    }
}
```

### Advanced CLI with Configuration

```swift
import Foundation
import SwiftResponsesDSL

struct CLIConfig {
    let apiKey: String
    let baseURL: String
    let model: String
    let temperature: Double
    let maxTokens: Int

    static func load() -> CLIConfig {
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "your-api-key"
        let baseURL = ProcessInfo.processInfo.environment["OPENAI_BASE_URL"] ?? "https://api.openai.com/v1/responses"
        let model = ProcessInfo.processInfo.environment["DEFAULT_MODEL"] ?? "gpt-4"
        let temperature = Double(ProcessInfo.processInfo.environment["TEMPERATURE"] ?? "0.7") ?? 0.7
        let maxTokens = Int(ProcessInfo.processInfo.environment["MAX_TOKENS"] ?? "1000") ?? 1000

        return CLIConfig(
            apiKey: apiKey,
            baseURL: baseURL,
            model: model,
            temperature: temperature,
            maxTokens: maxTokens
        )
    }
}

@main
struct AdvancedLLMCLI {
    static func main() async {
        let config = CLIConfig.load()

        do {
            let client = try LLMClient(
                baseURLString: config.baseURL,
                apiKey: config.apiKey
            )

            let request = ResponseRequest(
                model: config.model,
                config: {
                    Temperature(config.temperature)
                    MaxOutputTokens(config.maxTokens)
                },
                input: {
                    user("Hello! Tell me about Swift programming.")
                }
            )

            let response = try await client.respond(to: request)

            if let content = response.choices.first?.message.content {
                print("🤖 Assistant: \(content)")
            }

            // Print usage information
            if let usage = response.usage {
                print("\n📊 Usage:")
                print("  Prompt tokens: \(usage.promptTokens)")
                print("  Completion tokens: \(usage.completionTokens)")
                print("  Total tokens: \(usage.totalTokens)")
            }

        } catch LLMError.authenticationFailed {
            print("❌ Authentication failed. Check your API key.")
            print("💡 Set OPENAI_API_KEY environment variable")
        } catch LLMError.rateLimit {
            print("❌ Rate limit exceeded. Please wait and try again.")
        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }
}
```

## Cross-Platform Considerations

### Platform-Specific Optimizations

```swift
struct PlatformConfig {
    static var shared: PlatformConfig {
        #if os(iOS)
        return iOSConfig()
        #elseif os(macOS)
        return macOSConfig()
        #elseif os(Linux)
        return linuxConfig()
        #else
        return defaultConfig()
        #endif
    }

    let maxConcurrentRequests: Int
    let defaultModel: String
    let useKeychain: Bool

    private static func iOSConfig() -> PlatformConfig {
        PlatformConfig(maxConcurrentRequests: 3, defaultModel: "gpt-3.5-turbo", useKeychain: true)
    }

    private static func macOSConfig() -> PlatformConfig {
        PlatformConfig(maxConcurrentRequests: 5, defaultModel: "gpt-4", useKeychain: true)
    }

    private static func linuxConfig() -> PlatformConfig {
        PlatformConfig(maxConcurrentRequests: 10, defaultModel: "gpt-4", useKeychain: false)
    }

    private static func defaultConfig() -> PlatformConfig {
        PlatformConfig(maxConcurrentRequests: 3, defaultModel: "gpt-4", useKeychain: false)
    }
}
```

### Secure API Key Storage

```swift
protocol SecureStorage {
    func storeAPIKey(_ key: String) throws
    func retrieveAPIKey() throws -> String
    func deleteAPIKey() throws
}

#if os(iOS) || os(macOS)
import Security

class KeychainStorage: SecureStorage {
    func storeAPIKey(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "SwiftResponsesDSL",
            kSecAttrAccount as String: "OpenAI_API_Key",
            kSecValueData as String: key.data(using: .utf8)!
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            // Update existing item
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "SwiftResponsesDSL",
                kSecAttrAccount as String: "OpenAI_API_Key"
            ]
            let updateAttributes: [String: Any] = [
                kSecValueData as String: key.data(using: .utf8)!
            ]
            SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        }
    }

    func retrieveAPIKey() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "SwiftResponsesDSL",
            kSecAttrAccount as String: "OpenAI_API_Key",
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "KeychainError", code: Int(status), userInfo: nil)
        }

        return key
    }

    func deleteAPIKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "SwiftResponsesDSL",
            kSecAttrAccount as String: "OpenAI_API_Key"
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw NSError(domain: "KeychainError", code: Int(status), userInfo: nil)
        }
    }
}
#endif

#if os(Linux)
class EnvironmentStorage: SecureStorage {
    func storeAPIKey(_ key: String) throws {
        // For Linux, you might want to use a secure configuration file
        // or environment variables with proper permissions
        print("⚠️  Linux: Consider using secure configuration files for API keys")
        setenv("OPENAI_API_KEY", key, 1)
    }

    func retrieveAPIKey() throws -> String {
        guard let key = getenv("OPENAI_API_KEY"),
              let keyString = String(cString: key),
              !keyString.isEmpty else {
            throw NSError(domain: "EnvironmentError", code: 1, userInfo: [NSLocalizedDescriptionKey: "API key not found in environment"])
        }
        return keyString
    }

    func deleteAPIKey() throws {
        unsetenv("OPENAI_API_KEY")
    }
}
#endif
```

## Testing Across Platforms

### Platform-Specific Test Setup

```swift
import Testing
import SwiftResponsesDSL

struct LLMClientTests {
    @Test("Test authentication on all platforms")
    func testAuthentication() async throws {
        #if os(iOS) || os(macOS)
        let client = try LLMClient(
            baseURLString: "https://api.openai.com/v1/responses",
            apiKey: "test-key"
        )
        #expect(client.hasAuthentication == true)
        #elseif os(Linux)
        let client = try LLMClient(
            baseURLString: "https://api.openai.com/v1/responses",
            apiKey: "test-key"
        )
        #expect(client.hasAuthentication == true)
        #else
        // Default platform handling
        let client = try LLMClient(
            baseURLString: "https://api.example.com",
            apiKey: "test-key"
        )
        #expect(client.hasAuthentication == true)
        #endif
    }

    @Test("Test platform-specific configurations")
    func testPlatformConfig() {
        let config = PlatformConfig.shared

        #if os(iOS)
        #expect(config.maxConcurrentRequests == 3)
        #expect(config.useKeychain == true)
        #elseif os(macOS)
        #expect(config.maxConcurrentRequests == 5)
        #expect(config.useKeychain == true)
        #elseif os(Linux)
        #expect(config.maxConcurrentRequests == 10)
        #expect(config.useKeychain == false)
        #endif
    }
}
```

## Best Practices by Platform

### iOS Development
- **Memory Management**: Use streaming for large responses to reduce memory usage
- **Background Tasks**: Handle app lifecycle properly with Task cancellation
- **Network Reachability**: Monitor network status and handle offline scenarios
- **Keychain Integration**: Always use Keychain for API key storage
- **Rate Limiting**: Implement client-side rate limiting for mobile networks

### macOS Development
- **App Sandbox**: Handle sandbox restrictions for file access
- **Menu Bar Apps**: Consider lightweight implementations for menu bar tools
- **Window Management**: Handle multiple chat windows properly
- **System Integration**: Use macOS-specific features like notifications

### Server-Side Swift
- **Connection Pooling**: Reuse connections for better performance
- **Request Queuing**: Handle high concurrency with proper queuing
- **Caching**: Implement response caching for frequently asked questions
- **Monitoring**: Add comprehensive logging and metrics
- **Scalability**: Design for horizontal scaling

### Cross-Platform Development
- **Conditional Compilation**: Use platform-specific code paths when needed
- **Feature Detection**: Gracefully handle missing platform features
- **Testing Strategy**: Test on all supported platforms
- **Documentation**: Clearly document platform-specific behavior

This guide provides the foundation for integrating SwiftResponsesDSL into any Swift application. Each platform has its unique considerations, but the core DSL remains consistent across all environments.
