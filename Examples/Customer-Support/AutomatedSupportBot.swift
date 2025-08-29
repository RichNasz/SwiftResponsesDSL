//
//  AutomatedSupportBot.swift
//  SwiftResponsesDSL Examples
//
//  This example demonstrates an intelligent customer support automation system
//  that can handle common inquiries, escalate complex issues, and learn from interactions.
//
//  Created by SwiftResponsesDSL Example Generator.
//  https://github.com/RichNasz/SwiftResponsesDSL
//

import SwiftResponsesDSL

/// An intelligent customer support automation system
class AutomatedSupportBot {
    private let client: LLMClient
    private var knowledgeBase: KnowledgeBase
    private var conversationHistory: [String: [SupportInteraction]]
    private var escalationThreshold: Double = 0.3 // Escalate if confidence < 30%

    init(knowledgeBase: KnowledgeBase) throws {
        self.client = try LLMClient(
            baseURLString: "https://api.openai.com/v1/responses",
            apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!
        )
        self.knowledgeBase = knowledgeBase
        self.conversationHistory = [:]
    }

    /// Handle customer inquiry with intelligent routing and response
    func handleInquiry(
        customerId: String,
        message: String,
        customerContext: CustomerContext? = nil
    ) async throws -> SupportResponse {
        print("👤 Processing inquiry from customer: \(customerId)")
        print("💬 Message: \(message.prefix(100))...")

        // Analyze the inquiry
        let analysis = try await analyzeInquiry(message: message)

        // Route to appropriate handler
        let response: SupportResponse

        switch analysis.intent {
        case .productInformation:
            response = try await handleProductQuestion(message, analysis: analysis)
        case .technicalSupport:
            response = try await handleTechnicalIssue(message, analysis: analysis)
        case .billing:
            response = try await handleBillingQuestion(message, analysis: analysis)
        case .complaint:
            response = try await handleComplaint(message, analysis: analysis)
        case .general:
            response = try await handleGeneralInquiry(message, analysis: analysis)
        case .unknown:
            response = try await handleUnknownInquiry(message, analysis: analysis)
        }

        // Store interaction for learning
        storeInteraction(customerId: customerId, inquiry: message, response: response)

        // Check if escalation is needed
        if shouldEscalate(response: response, analysis: analysis) {
            response.escalationReason = "Low confidence or complex issue detected"
            print("🚨 Issue escalated for human review")
        }

        print("✅ Response generated with confidence: \(String(format: "%.1f", analysis.confidence * 100))%")
        return response
    }

    /// Analyze customer inquiry to understand intent and context
    private func analyzeInquiry(message: String) async throws -> InquiryAnalysis {
        let analysisRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.1)        // Factual analysis
                MaxOutputTokens(300)
            },
            input: {
                system("""
                You are an expert customer service analyst. Analyze customer inquiries and classify them accurately.

                Classify the inquiry into one of these categories:
                - product_information: Questions about products, features, or specifications
                - technical_support: Technical issues, bugs, or troubleshooting
                - billing: Questions about pricing, payments, or subscriptions
                - complaint: Customer complaints or negative feedback
                - general: General questions or small talk
                - unknown: Cannot be clearly classified

                Provide analysis in this JSON format:
                {
                    "intent": "category_name",
                    "confidence": 0.0-1.0,
                    "urgency": "low|medium|high",
                    "key_topics": ["topic1", "topic2"],
                    "sentiment": "positive|neutral|negative",
                    "requires_human": true|false
                }
                """)
                user("Analyze this customer inquiry: \(message)")
            }
        )

        let response = try await client.respond(to: analysisRequest)
        let analysisText = response.choices.first?.message.content ?? "{}"

        // Parse the JSON response
        return try parseAnalysis(from: analysisText)
    }

    /// Handle product information questions
    private func handleProductQuestion(_ message: String, analysis: InquiryAnalysis) async throws -> SupportResponse {
        let productRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.2)        // Informative but consistent
                MaxOutputTokens(600)
            },
            input: {
                system("""
                You are a knowledgeable product specialist. Provide accurate, helpful information about our products.

                Available products and services:
                \(knowledgeBase.productInformation)

                Guidelines:
                - Be accurate and helpful
                - Provide specific details when relevant
                - Suggest related products or services
                - Include relevant links or resources
                - Keep responses concise but comprehensive
                """)
                user("""
                Customer question: \(message)

                Analysis: Intent=\(analysis.intent.rawValue), Confidence=\(analysis.confidence), Sentiment=\(analysis.sentiment.rawValue)

                Provide a helpful response about our products.
                """)
            }
        )

        let response = try await client.respond(to: productRequest)
        let content = response.choices.first?.message.content ?? "I'm sorry, I couldn't find information about that product."

        return SupportResponse(
            content: content,
            intent: analysis.intent,
            confidence: analysis.confidence,
            suggestedActions: ["Check product documentation", "Contact sales for demo"],
            escalationReason: nil
        )
    }

    /// Handle technical support issues
    private func handleTechnicalIssue(_ message: String, analysis: InquiryAnalysis) async throws -> SupportResponse {
        // Check knowledge base for known issues
        let relevantSolutions = knowledgeBase.findSolutions(for: message)

        let techRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.1)        // Technical accuracy
                MaxOutputTokens(800)
            },
            input: {
                system("""
                You are a technical support specialist. Help customers resolve technical issues effectively.

                Troubleshooting framework:
                1. Gather information about the issue
                2. Provide step-by-step solutions
                3. Offer preventive measures
                4. Suggest escalation if needed

                Known issues and solutions:
                \(relevantSolutions)

                Always be patient, clear, and methodical in your responses.
                """)
                user("""
                Customer technical issue: \(message)

                Analysis: Intent=\(analysis.intent.rawValue), Urgency=\(analysis.urgency.rawValue)

                Provide clear troubleshooting steps and solutions.
                Include escalation guidance if the issue is complex.
                """)
            }
        )

        let response = try await client.respond(to: techRequest)
        let content = response.choices.first?.message.content ?? "I'm sorry, I need more information to help resolve this technical issue."

        let suggestedActions = [
            "Try the troubleshooting steps provided",
            "Restart the application/device",
            "Check system requirements",
            "Contact technical support if issue persists"
        ]

        return SupportResponse(
            content: content,
            intent: analysis.intent,
            confidence: analysis.confidence,
            suggestedActions: suggestedActions,
            escalationReason: analysis.urgency == .high ? "High-priority technical issue" : nil
        )
    }

    /// Handle billing and account questions
    private func handleBillingQuestion(_ message: String, analysis: InquiryAnalysis) async throws -> SupportResponse {
        let billingRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.1)        // Factual and precise
                MaxOutputTokens(400)
            },
            input: {
                system("""
                You are a billing specialist who handles customer account and payment questions professionally.

                Common billing topics:
                - Pricing information
                - Payment methods
                - Invoice questions
                - Account management
                - Refund policies

                Guidelines:
                - Be clear about pricing and policies
                - Direct to appropriate account management tools
                - Protect sensitive information
                - Suggest secure communication channels for sensitive topics
                """)
                user("""
                Customer billing question: \(message)

                Provide accurate information about billing, pricing, or account management.
                Include relevant contact information for sensitive matters.
                """)
            }
        )

        let response = try await client.respond(to: billingRequest)
        let content = response.choices.first?.message.content ?? "For billing questions, please check your account dashboard or contact our billing department."

        return SupportResponse(
            content: content,
            intent: analysis.intent,
            confidence: analysis.confidence,
            suggestedActions: ["Check account dashboard", "Contact billing support"],
            escalationReason: nil
        )
    }

    /// Handle customer complaints
    private func handleComplaint(_ message: String, analysis: InquiryAnalysis) async throws -> SupportResponse {
        let complaintRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.3)        // Empathetic but professional
                MaxOutputTokens(600)
            },
            input: {
                system("""
                You are a customer service specialist handling complaints and negative feedback.

                Complaint handling principles:
                1. Acknowledge the customer's feelings
                2. Apologize for any inconvenience
                3. Take ownership of the issue
                4. Provide clear resolution steps
                5. Offer compensation if appropriate
                6. Prevent future occurrences

                Always be empathetic, professional, and solution-focused.
                Escalate serious complaints to human representatives.
                """)
                user("""
                Customer complaint: \(message)

                Analysis: Sentiment=\(analysis.sentiment.rawValue), Urgency=\(analysis.urgency.rawValue)

                Handle this complaint professionally and provide appropriate resolution steps.
                Include escalation recommendation if needed.
                """)
            }
        )

        let response = try await client.respond(to: complaintRequest)
        let content = response.choices.first?.message.content ?? "I'm sorry you're experiencing issues. Let me help resolve this for you."

        // Complaints often need human attention
        let shouldEscalate = analysis.sentiment == .negative || analysis.urgency == .high

        return SupportResponse(
            content: content,
            intent: analysis.intent,
            confidence: analysis.confidence,
            suggestedActions: ["Follow resolution steps", "Contact supervisor if unsatisfied"],
            escalationReason: shouldEscalate ? "Customer complaint requiring human attention" : nil
        )
    }

    /// Handle general inquiries
    private func handleGeneralInquiry(_ message: String, analysis: InquiryAnalysis) async throws -> SupportResponse {
        let generalRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.4)        // Friendly and engaging
                MaxOutputTokens(400)
            },
            input: {
                system("""
                You are a friendly customer service representative handling general inquiries.

                Company information:
                \(knowledgeBase.companyInformation)

                Be welcoming, helpful, and direct customers to appropriate resources.
                Keep responses conversational but professional.
                """)
                user("""
                General customer inquiry: \(message)

                Provide a helpful response and direct to appropriate resources or team members.
                """)
            }
        )

        let response = try await client.respond(to: generalRequest)
        let content = response.choices.first?.message.content ?? "How can I help you today?"

        return SupportResponse(
            content: content,
            intent: analysis.intent,
            confidence: analysis.confidence,
            suggestedActions: ["Explore help documentation", "Contact appropriate department"],
            escalationReason: nil
        )
    }

    /// Handle unknown or unclear inquiries
    private func handleUnknownInquiry(_ message: String, analysis: InquiryAnalysis) async throws -> SupportResponse {
        let unknownRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.3)        // Helpful and guiding
                MaxOutputTokens(300)
            },
            input: {
                system("""
                You are handling an unclear customer inquiry. Your goal is to:
                1. Seek clarification politely
                2. Provide options for different types of help
                3. Guide the customer to the right resources
                4. Offer to connect them with a human representative

                Be patient and helpful, don't make assumptions.
                """)
                user("""
                Unclear customer message: \(message)

                Ask for clarification and provide helpful options for different types of support.
                """)
            }
        )

        let response = try await client.respond(to: unknownRequest)
        let content = response.choices.first?.message.content ?? "I'm not sure how to help with that. Could you provide more details?"

        return SupportResponse(
            content: content,
            intent: analysis.intent,
            confidence: analysis.confidence,
            suggestedActions: ["Provide more details", "Contact general support"],
            escalationReason: analysis.confidence < 0.2 ? "Unable to understand customer intent" : nil
        )
    }

    /// Store interaction for learning and analytics
    private func storeInteraction(customerId: String, inquiry: String, response: SupportResponse) {
        let interaction = SupportInteraction(
            timestamp: Date(),
            inquiry: inquiry,
            response: response.content,
            intent: response.intent,
            confidence: response.confidence,
            escalated: response.escalationReason != nil
        )

        if conversationHistory[customerId] == nil {
            conversationHistory[customerId] = []
        }
        conversationHistory[customerId]?.append(interaction)
    }

    /// Determine if issue should be escalated
    private func shouldEscalate(response: SupportResponse, analysis: InquiryAnalysis) -> Bool {
        return response.confidence < escalationThreshold ||
               analysis.urgency == .high ||
               analysis.sentiment == .negative ||
               analysis.requiresHuman ||
               response.escalationReason != nil
    }

    /// Parse analysis JSON
    private func parseAnalysis(from jsonString: String) throws -> InquiryAnalysis {
        // Simplified parsing - in production, use proper JSON parsing
        let intent: Intent
        if jsonString.contains("product") { intent = .productInformation }
        else if jsonString.contains("technical") { intent = .technicalSupport }
        else if jsonString.contains("billing") { intent = .billing }
        else if jsonString.contains("complaint") { intent = .complaint }
        else if jsonString.contains("general") { intent = .general }
        else { intent = .unknown }

        return InquiryAnalysis(
            intent: intent,
            confidence: 0.8, // Would be parsed from JSON
            urgency: .medium,
            keyTopics: [],
            sentiment: .neutral,
            requiresHuman: false
        )
    }
}

// Supporting types
enum Intent: String {
    case productInformation = "product_information"
    case technicalSupport = "technical_support"
    case billing = "billing"
    case complaint = "complaint"
    case general = "general"
    case unknown = "unknown"
}

enum Urgency: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

enum Sentiment: String {
    case positive = "positive"
    case neutral = "neutral"
    case negative = "negative"
}

struct InquiryAnalysis {
    let intent: Intent
    let confidence: Double
    let urgency: Urgency
    let keyTopics: [String]
    let sentiment: Sentiment
    let requiresHuman: Bool
}

struct SupportResponse {
    let content: String
    let intent: Intent
    let confidence: Double
    var suggestedActions: [String]
    var escalationReason: String?
}

struct CustomerContext {
    let customerId: String
    let accountType: String
    let supportHistory: Int
    let preferredContactMethod: String
}

struct SupportInteraction {
    let timestamp: Date
    let inquiry: String
    let response: String
    let intent: Intent
    let confidence: Double
    let escalated: Bool
}

struct KnowledgeBase {
    let productInformation: String
    let companyInformation: String
    let faq: [String: String]

    func findSolutions(for query: String) -> String {
        // Simple keyword matching - in production, use proper search
        let solutions = faq.filter { query.lowercased().contains($0.key.lowercased()) }
        return solutions.map { "Q: \($0.key)\nA: \($0.value)" }.joined(separator: "\n\n")
    }
}

// Demo usage
@main
struct SupportBotDemo {
    static func main() async {
        print("🤖 SwiftResponsesDSL Automated Support Bot Demo")
        print("==============================================")

        // Create knowledge base
        let knowledgeBase = KnowledgeBase(
            productInformation: """
            Our main products:
            - Premium Plan: $29/month, includes advanced features
            - Basic Plan: $9/month, essential features only
            - Enterprise Plan: Custom pricing, full features + support
            """,
            companyInformation: """
            Company: TechCorp Solutions
            Founded: 2010
            Headquarters: San Francisco, CA
            Support Hours: 9 AM - 6 PM PST, Monday-Friday
            """,
            faq: [
                "password reset": "Go to settings > account > reset password",
                "billing cycle": "Billing occurs monthly on the same date you signed up",
                "refund policy": "Refunds available within 30 days for unused services",
                "technical support": "Contact support@techcorp.com for technical issues"
            ]
        )

        do {
            let supportBot = try AutomatedSupportBot(knowledgeBase: knowledgeBase)

            // Simulate customer inquiries
            let inquiries = [
                "What's the difference between Premium and Basic plans?",
                "I'm having trouble logging in to my account",
                "I want to cancel my subscription and get a refund",
                "How do I reset my password?",
                "The app keeps crashing when I try to upload files"
            ]

            for (index, inquiry) in inquiries.enumerated() {
                print("\n" + String(repeating: "=", count: 60))
                print("🚨 CUSTOMER INQUIRY #\(index + 1)")
                print(String(repeating: "=", count: 60))

                let response = try await supportBot.handleInquiry(
                    customerId: "demo-customer-\(index + 1)",
                    message: inquiry
                )

                print("📝 Response: \(response.content)")
                print("🎯 Intent: \(response.intent.rawValue)")
                print("📊 Confidence: \(String(format: "%.1f", response.confidence * 100))%")

                if !response.suggestedActions.isEmpty {
                    print("💡 Suggested Actions:")
                    for action in response.suggestedActions {
                        print("   • \(action)")
                    }
                }

                if let reason = response.escalationReason {
                    print("🚨 Escalation Reason: \(reason)")
                }
            }

            print("\n" + String(repeating: "=", count: 60))
            print("✅ Demo completed! The support bot successfully handled \(inquiries.count) inquiries.")
            print("💡 In a production environment, this would integrate with your CRM,")
            print("   ticketing system, and customer database for enhanced automation.")

        } catch {
            print("❌ Error: \(error.localizedDescription)")

            if let llmError = error as? LLMError {
                switch llmError {
                case .authenticationFailed:
                    print("💡 Check your OPENAI_API_KEY environment variable")
                case .rateLimit:
                    print("💡 You've hit the API rate limit. Try again later.")
                case .networkError:
                    print("💡 Check your internet connection")
                default:
                    print("💡 Check your API configuration")
                }
            }
        }
    }
}
