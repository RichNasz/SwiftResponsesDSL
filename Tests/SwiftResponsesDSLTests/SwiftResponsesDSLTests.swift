import Testing
import Foundation
@testable import SwiftResponsesDSL

@Test func testSystemMessageCreation() {
    let message = SystemMessage(text: "You are a helpful assistant")
    #expect(message.role == .system)
    #expect(message.content.count == 1)
    if case .text(let text) = message.content[0] {
        #expect(text == "You are a helpful assistant")
    }
}

@Test func testUserMessageCreation() {
    let message = UserMessage(text: "Hello, world!")
    #expect(message.role == .user)
    #expect(message.content.count == 1)
}

@Test func testAssistantMessageCreation() {
    let message = AssistantMessage(text: "Hello! How can I help you?")
    #expect(message.role == .assistant)
    #expect(message.content.count == 1)
}

@Test func testTemperatureParameter() throws {
    let temp = try Temperature(0.7)
    #expect(temp.value == 0.7)

    // Test validation
    #expect(throws: LLMError.self) {
        _ = try Temperature(2.5) // Should fail - too high
    }
}

@Test func testTopPParameter() throws {
    let topP = try TopP(0.9)
    #expect(topP.value == 0.9)

    // Test validation
    #expect(throws: LLMError.self) {
        _ = try TopP(1.5) // Should fail - too high
    }
}

@Test func testMaxOutputTokensParameter() throws {
    let maxTokens = try MaxOutputTokens(100)
    #expect(maxTokens.value == 100)

    // Test validation
    #expect(throws: LLMError.self) {
        _ = try MaxOutputTokens(0) // Should fail - must be positive
    }
}

@Test func testResponseRequestCreation() throws {
    let messages: [any ResponseMessage] = [SystemMessage(text: "You are helpful"), UserMessage(text: "Hello")]
    let request = try ResponseRequest(model: "gpt-4", input: messages, previousResponseId: nil, stream: false, config: [])

    #expect(request.model == "gpt-4")
    #expect(request.messages.count == 2)
    #expect(request.stream == false)
}

@Test func testResponseConversation() throws {
    var conversation = ResponseConversation()

    conversation.append(system: "You are a helpful assistant")
    conversation.append(user: "Hello")

    #expect(conversation.messages.count == 2)

    let request = try conversation.generateRequest(model: "gpt-4")
    #expect(request.model == "gpt-4")
    #expect(request.messages.count == 2)
}

@Test func testContentPartEncoding() throws {
    let textPart = ContentPart.text("Hello world")
    let encoder = JSONEncoder()
    let data = try encoder.encode(textPart)
    let jsonString = String(data: data, encoding: .utf8)!

    #expect(jsonString.contains("\"type\":\"text\""))
    #expect(jsonString.contains("\"text\":\"Hello world\""))
}

@Test func testToolCreation() throws {
    let function = Tool.Function(name: "get_weather", description: "Get weather information", parameters: [:], strict: true)
    let tool = Tool(type: "function", function: function, fileSearch: nil, webSearchPreview: nil)

    #expect(tool.type == "function")
    #expect(tool.function?.name == "get_weather")
}

@Test func testConvenienceFunctions() {
    let systemMsg = system("You are helpful")
    #expect(systemMsg.role == .system)

    let userMsg = user("Hello")
    #expect(userMsg.role == .user)

    let assistantMsg = assistant("Hi there")
    #expect(assistantMsg.role == .assistant)
}

@Test func testClientAuthentication() async throws {
    // Test client with API key
    let clientWithAuth = try LLMClient(baseURLString: "https://api.example.com", apiKey: "test-key")
    #expect(clientWithAuth.hasAuthentication == true)
    try clientWithAuth.validateAuthentication() // Should not throw

    // Test client without API key
    let clientWithoutAuth = try LLMClient(baseURLString: "https://api.example.com")
    #expect(clientWithoutAuth.hasAuthentication == false)
    #expect(throws: LLMError.self) {
        try clientWithoutAuth.validateAuthentication() // Should throw
    }

    // Test client with optional API key
    let clientOptionalAuth = LLMClient(baseURL: URL(string: "https://api.example.com")!, apiKey: nil)
    #expect(clientOptionalAuth.hasAuthentication == false)

    let clientWithOptionalKey = LLMClient(baseURL: URL(string: "https://api.example.com")!, apiKey: "optional-key")
    #expect(clientWithOptionalKey.hasAuthentication == true)
}

@Test func testClientInitialization() throws {
    // Test valid URL string
    let client = try LLMClient(baseURLString: "https://api.openai.com/v1/responses", apiKey: "test-key")
    #expect(client.hasAuthentication == true)
}
