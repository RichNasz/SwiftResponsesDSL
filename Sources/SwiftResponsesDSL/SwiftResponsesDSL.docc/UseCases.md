# Real-World Use Cases

@Metadata {
    @DisplayName("Use Cases")
    @PageKind(article)
}

SwiftResponsesDSL enables powerful AI integration across diverse domains. This guide showcases real-world applications with complete, runnable code examples that you can adapt for your projects.

## Content Creation & Marketing

### Blog Post Generator

Create engaging blog content with AI assistance:

```swift
import SwiftResponsesDSL

class BlogPostGenerator {
    private let client: LLMClient

    init() throws {
        client = try LLMClient(
            baseURLString: "https://api.openai.com/v1/responses",
            apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!
        )
    }

    func generatePost(topic: String, targetAudience: String, tone: String = "professional") async throws -> BlogPost {
        let request = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.7)        // Creative but focused
                MaxOutputTokens(2000)   // Allow detailed content
                TopP(0.9)              // Varied but coherent writing
            },
            input: {
                system("""
                You are an expert content creator specializing in blog posts.
                Create engaging, well-structured content that resonates with the target audience.
                Always include:
                - Compelling headline
                - SEO-optimized introduction
                - 3-5 main sections with descriptive subheadings
                - Practical takeaways
                - Call-to-action
                """)
                user("""
                Write a comprehensive blog post about: \(topic)

                Target Audience: \(targetAudience)
                Tone: \(tone)

                Make it informative, engaging, and shareable.
                Include practical examples and actionable advice.
                """)
            }
        )

        let response = try await client.respond(to: request)
        let content = response.choices.first?.message.content ?? ""

        return BlogPost(
            title: extractTitle(from: content),
            content: content,
            topic: topic,
            targetAudience: targetAudience,
            generatedAt: Date()
        )
    }

    func optimizeForSEO(post: BlogPost, keywords: [String]) async throws -> BlogPost {
        let seoRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.3)        // More focused for SEO
                MaxOutputTokens(1500)
            },
            input: {
                system("""
                You are an SEO expert. Optimize content for search engines while maintaining readability.
                Focus on:
                - Natural keyword integration
                - Improved meta descriptions
                - Better heading structure
                - Enhanced readability
                - Search intent alignment
                """)
                user("""
                Optimize this blog post for SEO with these keywords: \(keywords.joined(separator: ", "))

                Original post:
                \(post.content)

                Provide the optimized version with SEO improvements.
                """)
            }
        )

        let response = try await client.respond(to: seoRequest)
        let optimizedContent = response.choices.first?.message.content ?? post.content

        return BlogPost(
            title: post.title,
            content: optimizedContent,
            topic: post.topic,
            targetAudience: post.targetAudience,
            generatedAt: post.generatedAt,
            seoOptimized: true,
            keywords: keywords
        )
    }

    private func extractTitle(from content: String) -> String {
        // Extract first line as title, or generate one
        let lines = content.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                return trimmed
            }
        }
        return "Generated Blog Post"
    }
}

struct BlogPost {
    let title: String
    let content: String
    let topic: String
    let targetAudience: String
    let generatedAt: Date
    var seoOptimized: Bool = false
    var keywords: [String] = []
}

// Usage Example
let generator = try BlogPostGenerator()
let post = try await generator.generatePost(
    topic: "Swift Concurrency with Async/Await",
    targetAudience: "iOS developers learning modern Swift",
    tone: "educational"
)
print("📝 Generated Post: \(post.title)")
print("📊 Word count: \(post.content.split(separator: " ").count)")

// Optimize for SEO
let optimizedPost = try await generator.optimizeForSEO(
    post: post,
    keywords: ["Swift", "async", "await", "concurrency", "iOS development"]
)
print("✅ SEO optimized with keywords: \(optimizedPost.keywords)")
```

### Social Media Content Creator

Generate engaging social media posts:

```swift
class SocialMediaManager {
    private let client: LLMClient

    init() throws {
        client = try LLMClient(
            baseURLString: "https://api.openai.com/v1/responses",
            apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!
        )
    }

    func createPostSeries(topic: String, platform: SocialPlatform, count: Int = 5) async throws -> [SocialPost] {
        var posts: [SocialPost] = []

        for i in 1...count {
            let request = ResponseRequest(
                model: "gpt-4",
                config: {
                    Temperature(0.8)        // Creative content
                    MaxOutputTokens(300)    // Concise for social media
                    TopP(0.9)              // Varied but on-topic
                },
                input: {
                    system("""
                    You are a social media expert creating viral content.
                    Platform: \(platform.rawValue)
                    Style: Engaging, concise, shareable
                    Include relevant hashtags and emojis
                    Optimize for platform's best practices
                    """)
                    user("""
                    Create post #\(i) in a series about: \(topic)

                    Make it engaging and encourage interaction.
                    Include a call-to-action.
                    Keep it under \(platform.maxLength) characters.
                    """)
                }
            )

            let response = try await client.respond(to: request)
            if let content = response.choices.first?.message.content {
                let post = SocialPost(
                    content: content,
                    platform: platform,
                    topic: topic,
                    seriesNumber: i,
                    generatedAt: Date()
                )
                posts.append(post)
            }
        }

        return posts
    }

    func optimizePostingSchedule(posts: [SocialPost], timezone: String) async throws -> ScheduledPosts {
        let scheduleRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.2)        // Analytical task
                MaxOutputTokens(500)
            },
            input: {
                system("You are a social media strategist optimizing posting schedules.")
                user("""
                Optimize posting schedule for these \(posts.count) posts about "\(posts.first?.topic ?? "")"
                Target timezone: \(timezone)

                Consider:
                - Peak engagement times
                - Audience demographics
                - Content type optimization
                - Platform algorithms
                - Spacing between posts

                Provide specific times and reasoning.
                """)
            }
        )

        let response = try await client.respond(to: scheduleRequest)
        let scheduleContent = response.choices.first?.message.content ?? ""

        return ScheduledPosts(posts: posts, schedule: scheduleContent, timezone: timezone)
    }
}

enum SocialPlatform: String {
    case twitter = "Twitter/X"
    case linkedin = "LinkedIn"
    case instagram = "Instagram"
    case facebook = "Facebook"
    case tiktok = "TikTok"

    var maxLength: Int {
        switch self {
        case .twitter: return 280
        case .linkedin: return 3000
        case .instagram: return 2200
        case .facebook: return 63206
        case .tiktok: return 2200
        }
    }
}

struct SocialPost {
    let content: String
    let platform: SocialPlatform
    let topic: String
    let seriesNumber: Int
    let generatedAt: Date
}

struct ScheduledPosts {
    let posts: [SocialPost]
    let schedule: String
    let timezone: String
}

// Usage Example
let socialManager = try SocialMediaManager()
let posts = try await socialManager.createPostSeries(
    topic: "SwiftUI Layout Techniques",
    platform: .twitter,
    count: 3
)

for (index, post) in posts.enumerated() {
    print("📱 Post \(index + 1): \(post.content.prefix(100))...")
}

let scheduled = try await socialManager.optimizePostingSchedule(
    posts: posts,
    timezone: "America/New_York"
)
print("📅 Schedule: \(scheduled.schedule)")
```

## Education & Learning

### Interactive Quiz Generator

Create educational quizzes with AI-generated questions:

```swift
class QuizGenerator {
    private let client: LLMClient

    init() throws {
        client = try LLMClient(
            baseURLString: "https://api.openai.com/v1/responses",
            apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!
        )
    }

    func generateQuiz(topic: String, difficulty: Difficulty, questionCount: Int = 10) async throws -> Quiz {
        let request = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.7)        // Balanced creativity
                MaxOutputTokens(1500)   // Allow detailed questions
                TopP(0.9)              // Varied question types
            },
            input: {
                system("""
                You are an expert educator creating high-quality quizzes.
                Create a comprehensive quiz with:
                - Multiple choice questions
                - True/false questions
                - Short answer questions
                - Scenario-based questions
                - Proper difficulty distribution
                - Clear explanations for answers
                """)
                user("""
                Create a \(questionCount)-question quiz about: \(topic)

                Difficulty: \(difficulty.rawValue)
                Format: JSON with questions, options, correct answers, and explanations

                Make questions challenging but fair.
                Include variety in question types.
                """)
            }
        )

        let response = try await client.respond(to: request)
        let content = response.choices.first?.message.content ?? "{}"

        // Parse JSON response into Quiz object
        return try parseQuiz(from: content, topic: topic, difficulty: difficulty)
    }

    func generateAdaptiveQuiz(userPerformance: [QuizResult], topic: String) async throws -> Quiz {
        let performanceSummary = userPerformance
            .map { "Question: \($0.questionId), Score: \($0.score), Time: \($0.timeSpent)s" }
            .joined(separator: "\n")

        let adaptiveRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.6)        // Balanced but focused
                MaxOutputTokens(1200)
            },
            input: {
                system("""
                You are an adaptive learning specialist.
                Analyze student performance and create appropriately challenging questions.
                Focus on weak areas while maintaining engagement.
                Adjust difficulty based on performance patterns.
                """)
                user("""
                Based on this performance data, create an adaptive quiz:

                \(performanceSummary)

                Topic: \(topic)
                Create 8-10 questions that address knowledge gaps and build on strengths.
                Include questions slightly above current ability level.
                """)
            }
        )

        let response = try await adaptiveRequest.respond(to: adaptiveRequest)
        let content = response.choices.first?.message.content ?? "{}"

        return try parseQuiz(from: content, topic: topic, difficulty: .adaptive)
    }

    private func parseQuiz(from jsonString: String, topic: String, difficulty: Difficulty) throws -> Quiz {
        // JSON parsing implementation
        // This would parse the AI-generated JSON into structured Quiz objects
        // For brevity, returning a mock implementation
        return Quiz(
            id: UUID(),
            topic: topic,
            difficulty: difficulty,
            questions: [],
            createdAt: Date()
        )
    }
}

enum Difficulty: String {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case adaptive = "Adaptive"
}

struct Quiz {
    let id: UUID
    let topic: String
    let difficulty: Difficulty
    let questions: [QuizQuestion]
    let createdAt: Date
}

struct QuizQuestion {
    let id: String
    let type: QuestionType
    let question: String
    let options: [String]?
    let correctAnswer: String
    let explanation: String
}

enum QuestionType {
    case multipleChoice
    case trueFalse
    case shortAnswer
    case scenario
}

struct QuizResult {
    let questionId: String
    let score: Double
    let timeSpent: TimeInterval
    let attempts: Int
}

// Usage Example
let quizGenerator = try QuizGenerator()

// Generate a standard quiz
let quiz = try await quizGenerator.generateQuiz(
    topic: "Swift Memory Management",
    difficulty: .intermediate,
    questionCount: 10
)
print("📚 Generated quiz: \(quiz.topic) - \(quiz.questions.count) questions")

// Generate adaptive quiz based on performance
let performanceData = [
    QuizResult(questionId: "q1", score: 0.8, timeSpent: 45, attempts: 1),
    QuizResult(questionId: "q2", score: 0.3, timeSpent: 120, attempts: 3),
    QuizResult(questionId: "q3", score: 1.0, timeSpent: 25, attempts: 1)
]

let adaptiveQuiz = try await quizGenerator.generateAdaptiveQuiz(
    userPerformance: performanceData,
    topic: "Swift Memory Management"
)
print("🎯 Adaptive quiz created based on performance data")
```

### Code Review Assistant

AI-powered code review and improvement suggestions:

```swift
class CodeReviewAssistant {
    private let client: LLMClient

    init() throws {
        client = try LLMClient(
            baseURLString: "https://api.openai.com/v1/responses",
            apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!
        )
    }

    func reviewCode(code: String, language: String, context: String? = nil) async throws -> CodeReview {
        let request = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.3)        // Analytical task
                MaxOutputTokens(1500)   // Detailed analysis
                TopP(0.1)              // Focused analysis
            },
            input: {
                system("""
                You are an expert code reviewer with years of experience.
                Provide constructive, actionable feedback on code quality, performance, security, and best practices.
                Focus on:
                - Code readability and maintainability
                - Performance optimizations
                - Security considerations
                - Best practices compliance
                - Error handling
                - Documentation needs
                """)
                user("""
                Review this \(language) code:

                ```\(language)
                \(code)
                ```

                \(context.map { "Context: \($0)" } ?? "")

                Provide:
                1. Overall assessment (1-10 scale)
                2. Specific issues found
                3. Improvement suggestions
                4. Security considerations
                5. Performance recommendations
                """)
            }
        )

        let response = try await client.respond(to: request)
        let reviewContent = response.choices.first?.message.content ?? ""

        return CodeReview(
            code: code,
            language: language,
            review: reviewContent,
            reviewedAt: Date()
        )
    }

    func suggestRefactoring(review: CodeReview) async throws -> RefactoringPlan {
        let refactorRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.4)        // Creative but practical
                MaxOutputTokens(2000)   // Detailed refactoring plan
            },
            input: {
                system("""
                You are a refactoring expert. Create detailed, actionable refactoring plans.
                Focus on:
                - Breaking down complex functions
                - Improving separation of concerns
                - Enhancing testability
                - Reducing technical debt
                - Modernizing code patterns
                """)
                user("""
                Based on this code review, create a refactoring plan:

                REVIEW:
                \(review.review)

                CODE:
                ```\(review.language)
                \(review.code)
                ```

                Provide:
                1. Refactoring priority (High/Medium/Low)
                2. Step-by-step refactoring plan
                3. Code examples for each step
                4. Testing strategy for refactored code
                5. Risk assessment and mitigation
                """)
            }
        )

        let response = try await client.respond(to: refactorRequest)
        let planContent = response.choices.first?.message.content ?? ""

        return RefactoringPlan(
            originalCode: review.code,
            review: review.review,
            plan: planContent,
            createdAt: Date()
        )
    }
}

struct CodeReview {
    let code: String
    let language: String
    let review: String
    let reviewedAt: Date
}

struct RefactoringPlan {
    let originalCode: String
    let review: String
    let plan: String
    let createdAt: Date
}

// Usage Example
let reviewAssistant = try CodeReviewAssistant()

let codeToReview = """
func processUserData(users: [User]) -> [String] {
    var result: [String] = []
    for user in users {
        if user.age > 18 {
            result.append("\(user.name) is an adult")
        } else {
            result.append("\(user.name) is a minor")
        }
    }
    return result
}
"""

let review = try await reviewAssistant.reviewCode(
    code: codeToReview,
    language: "swift",
    context: "User data processing function in an iOS app"
)
print("🔍 Code Review Results:")
print(review.review)

if review.review.contains("refactor") || review.review.contains("improve") {
    let refactorPlan = try await reviewAssistant.suggestRefactoring(review: review)
    print("\n🔧 Refactoring Plan:")
    print(refactorPlan.plan)
}
```

## Customer Support & Automation

### Intelligent Chatbot

Create context-aware customer support chatbots:

```swift
class CustomerSupportBot {
    private let client: LLMClient
    private var conversationHistory: [String: [String]] = [:]

    init() throws {
        client = try LLMClient(
            baseURLString: "https://api.openai.com/v1/responses",
            apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!
        )
    }

    func handleCustomerInquiry(customerId: String, message: String, context: CustomerContext) async throws -> SupportResponse {
        // Retrieve or initialize conversation history
        var history = conversationHistory[customerId] ?? []

        let request = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.3)        // Professional, consistent responses
                MaxOutputTokens(800)    // Comprehensive but concise
                TopP(0.85)             // Balanced creativity
            },
            input: {
                system("""
                You are a professional customer support representative for \(context.companyName).
                Company specializes in: \(context.businessDescription)

                Guidelines:
                - Be empathetic and understanding
                - Provide accurate, helpful information
                - Escalate complex issues when appropriate
                - Maintain professional tone
                - Ask clarifying questions when needed
                - Suggest next steps clearly

                Customer context:
                - Account type: \(context.accountType)
                - Support history: \(context.supportTickets) previous tickets
                - Preferred contact: \(context.preferredContact)
                """)

                // Add recent conversation history
                for previousMessage in history.suffix(5) {
                    assistant(previousMessage)
                }

                user(message)
            }
        )

        let response = try await client.respond(to: request)
        let aiResponse = response.choices.first?.message.content ?? "I'm sorry, I couldn't process your request."

        // Store response in history
        history.append("Customer: \(message)")
        history.append("Assistant: \(aiResponse)")
        conversationHistory[customerId] = history

        return SupportResponse(
            message: aiResponse,
            sentiment: try await analyzeSentiment(message: message),
            suggestedActions: try await suggestActions(message: message, response: aiResponse),
            shouldEscalate: shouldEscalate(message: message, response: aiResponse)
        )
    }

    private func analyzeSentiment(message: String) async throws -> Sentiment {
        let sentimentRequest = ResponseRequest(
            model: "gpt-3.5-turbo",
            config: {
                Temperature(0.1)        // Factual analysis
                MaxOutputTokens(50)     // Brief response
            },
            input: {
                system("Analyze the sentiment of customer messages. Respond with only: positive, negative, or neutral.")
                user(message)
            }
        )

        let response = try await client.respond(to: sentimentRequest)
        let sentimentText = response.choices.first?.message.content?.lowercased() ?? "neutral"

        switch sentimentText {
        case _ where sentimentText.contains("positive"): return .positive
        case _ where sentimentText.contains("negative"): return .negative
        default: return .neutral
        }
    }

    private func suggestActions(message: String, response: String) async throws -> [String] {
        let actionRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.2)        // Practical suggestions
                MaxOutputTokens(200)
            },
            input: {
                system("Suggest 2-3 concrete next steps for the customer based on their message and your response.")
                user("""
                Customer message: \(message)
                Your response: \(response)

                Suggest specific, actionable next steps.
                """)
            }
        )

        let actionResponse = try await client.respond(to: actionRequest)
        let suggestions = actionResponse.choices.first?.message.content ?? ""
        return suggestions.components(separatedBy: "\n").filter { !$0.isEmpty }
    }

    private func shouldEscalate(message: String, response: String) -> Bool {
        let escalationKeywords = ["refund", "cancel", "complaint", "urgent", "emergency"]
        let lowerMessage = message.lowercased()

        return escalationKeywords.contains { lowerMessage.contains($0) } ||
               response.contains("escalate") ||
               response.contains("supervisor")
    }
}

struct CustomerContext {
    let companyName: String
    let businessDescription: String
    let accountType: String
    let supportTickets: Int
    let preferredContact: String
}

enum Sentiment {
    case positive, neutral, negative
}

struct SupportResponse {
    let message: String
    let sentiment: Sentiment
    let suggestedActions: [String]
    let shouldEscalate: Bool
}

// Usage Example
let supportBot = try CustomerSupportBot()
let context = CustomerContext(
    companyName: "SwiftShop",
    businessDescription: "E-commerce platform for Swift developers",
    accountType: "Premium",
    supportTickets: 3,
    preferredContact: "email"
)

let response = try await supportBot.handleCustomerInquiry(
    customerId: "user123",
    message: "I'm having trouble with my recent order. It shows as delivered but I haven't received it.",
    context: context
)

print("🤖 Support Response: \(response.message)")
print("😊 Sentiment: \(response.sentiment)")
print("📋 Suggested Actions: \(response.suggestedActions.joined(separator: ", "))")
if response.shouldEscalate {
    print("🚨 This issue should be escalated to a supervisor")
}
```

## Data Processing & Analysis

### Document Summarization Pipeline

Process and summarize large documents:

```swift
class DocumentProcessor {
    private let client: LLMClient

    init() throws {
        client = try LLMClient(
            baseURLString: "https://api.openai.com/v1/responses",
            apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!
        )
    }

    func summarizeDocument(content: String, maxLength: Int = 500, focus: String? = nil) async throws -> DocumentSummary {
        let focusInstruction = focus.map { "Focus on: \($0)" } ?? "Provide a comprehensive summary"

        let request = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.3)        // Factual summarization
                MaxOutputTokens(maxLength / 4)  // Estimate token usage
            },
            input: {
                system("""
                You are an expert document analyst. Create clear, concise summaries that capture:
                - Main ideas and key points
                - Important data and statistics
                - Conclusions and recommendations
                - Actionable insights
                - Context and background information

                \(focusInstruction)
                Keep summary under \(maxLength) characters.
                """)
                user("""
                Summarize this document:

                \(content)

                Provide:
                1. Executive summary (2-3 sentences)
                2. Key points (bullet points)
                3. Main conclusions
                4. Any recommendations or next steps mentioned
                """)
            }
        )

        let response = try await client.respond(to: request)
        let summary = response.choices.first?.message.content ?? ""

        return DocumentSummary(
            originalLength: content.count,
            summary: summary,
            summaryLength: summary.count,
            focus: focus,
            generatedAt: Date()
        )
    }

    func extractKeyInsights(document: String, categories: [String]? = nil) async throws -> KeyInsights {
        let categoryInstruction = categories.map { "Focus on these categories: \($0.joined(separator: ", "))" } ?? "Extract insights from all relevant areas"

        let insightsRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.2)        // Analytical task
                MaxOutputTokens(1000)
            },
            input: {
                system("""
                You are a data analyst extracting key insights from documents.
                \(categoryInstruction)

                Provide structured insights with:
                - Quantitative data and metrics
                - Qualitative observations
                - Trends and patterns
                - Risks and opportunities
                - Correlations and relationships
                """)
                user("""
                Extract key insights from this document:

                \(document)

                Format as JSON with categories and specific insights.
                Include supporting evidence from the text.
                """)
            }
        )

        let response = try await client.respond(to: insightsRequest)
        let insightsContent = response.choices.first?.message.content ?? "{}"

        return KeyInsights(
            document: document,
            insights: insightsContent,
            categories: categories,
            extractedAt: Date()
        )
    }

    func generateActionItems(summary: DocumentSummary, stakeholder: String) async throws -> ActionPlan {
        let actionRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.4)        // Practical suggestions
                MaxOutputTokens(800)
            },
            input: {
                system("""
                You are a project manager creating actionable plans.
                Create specific, measurable action items based on document summaries.
                Consider the stakeholder's perspective and organizational context.
                """)
                user("""
                Based on this document summary, create an action plan for: \(stakeholder)

                SUMMARY:
                \(summary.summary)

                Create:
                1. Immediate action items (next 1-2 weeks)
                2. Short-term goals (next 1-3 months)
                3. Long-term objectives (3-12 months)
                4. Success metrics for each action
                5. Potential risks and mitigation strategies
                """)
            }
        )

        let response = try await client.respond(to: actionRequest)
        let actionPlan = response.choices.first?.message.content ?? ""

        return ActionPlan(
            summary: summary,
            stakeholder: stakeholder,
            plan: actionPlan,
            createdAt: Date()
        )
    }
}

struct DocumentSummary {
    let originalLength: Int
    let summary: String
    let summaryLength: Int
    let focus: String?
    let generatedAt: Date
}

struct KeyInsights {
    let document: String
    let insights: String
    let categories: [String]?
    let extractedAt: Date
}

struct ActionPlan {
    let summary: DocumentSummary
    let stakeholder: String
    let plan: String
    let createdAt: Date
}

// Usage Example
let processor = try DocumentProcessor()

let longDocument = """
[Long research paper or business report content here...]
"""

// Generate summary
let summary = try await processor.summarizeDocument(
    content: longDocument,
    maxLength: 1000,
    focus: "key findings and recommendations"
)
print("📄 Summary: \(summary.summary)")
print("📊 Compression: \(summary.originalLength) → \(summary.summaryLength) characters")

// Extract insights
let insights = try await processor.extractKeyInsights(
    document: longDocument,
    categories: ["financial", "operational", "strategic"]
)
print("💡 Key Insights: \(insights.insights)")

// Generate action plan
let actionPlan = try await processor.generateActionItems(
    summary: summary,
    stakeholder: "Product Manager"
)
print("📋 Action Plan: \(actionPlan.plan)")
```

## Development & Productivity

### API Documentation Generator

Generate comprehensive API documentation:

```swift
class APIDocumentationGenerator {
    private let client: LLMClient

    init() throws {
        client = try LLMClient(
            baseURLString: "https://api.openai.com/v1/responses",
            apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!
        )
    }

    func generateEndpointDocs(apiSpec: String, language: String) async throws -> APIEndpoint {
        let request = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.2)        // Technical documentation
                MaxOutputTokens(1500)
            },
            input: {
                system("""
                You are a technical writer specializing in API documentation.
                Create comprehensive, accurate documentation including:
                - Clear description of functionality
                - Required and optional parameters
                - Request/response examples
                - Error conditions and codes
                - Authentication requirements
                - Rate limiting considerations
                """)
                user("""
                Generate complete API documentation for this endpoint:

                \(apiSpec)

                Language: \(language)
                Include code examples in the target language.
                Follow REST API documentation best practices.
                """)
            }
        )

        let response = try await client.respond(to: request)
        let documentation = response.choices.first?.message.content ?? ""

        return APIEndpoint(
            specification: apiSpec,
            documentation: documentation,
            language: language,
            generatedAt: Date()
        )
    }

    func createUserGuides(apiDocs: [APIEndpoint], userType: String) async throws -> UserGuide {
        let combinedDocs = apiDocs.map { "\($0.specification): \($0.documentation)" }.joined(separator: "\n\n")

        let guideRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.3)        // Educational content
                MaxOutputTokens(2000)
            },
            input: {
                system("""
                You are a technical educator creating user guides for APIs.
                Create guides that are:
                - Beginner-friendly for \(userType)
                - Progressive in complexity
                - Practical with real-world examples
                - Comprehensive but not overwhelming
                """)
                user("""
                Create a user guide for \(userType) based on these API endpoints:

                \(combinedDocs)

                Structure the guide with:
                1. Introduction and overview
                2. Getting started section
                3. Common use cases with examples
                4. Best practices and tips
                5. Troubleshooting section
                6. API reference summary
                """)
            }
        )

        let response = try await client.respond(to: guideRequest)
        let guideContent = response.choices.first?.message.content ?? ""

        return UserGuide(
            apiDocs: apiDocs,
            content: guideContent,
            targetUser: userType,
            createdAt: Date()
        )
    }
}

struct APIEndpoint {
    let specification: String
    let documentation: String
    let language: String
    let generatedAt: Date
}

struct UserGuide {
    let apiDocs: [APIEndpoint]
    let content: String
    let targetUser: String
    let createdAt: Date
}
```

These real-world use cases demonstrate how SwiftResponsesDSL can be applied across diverse domains, from content creation and education to customer support and data processing. Each example shows the DSL's flexibility and power in solving complex, real-world problems with clean, maintainable Swift code.
