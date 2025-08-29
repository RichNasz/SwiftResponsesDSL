//
//  BlogPostGenerator.swift
//  SwiftResponsesDSL Examples
//
//  This example demonstrates how to create a comprehensive blog post generator
//  that can produce SEO-optimized content for various topics and audiences.
//
//  Created by SwiftResponsesDSL Example Generator.
//  https://github.com/RichNasz/SwiftResponsesDSL
//

import SwiftResponsesDSL

/// A comprehensive blog post generator with SEO optimization
class BlogPostGenerator {
    private let client: LLMClient

    init() throws {
        client = try LLMClient(
            baseURLString: "https://api.openai.com/v1/responses",
            apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!
        )
    }

    /// Generate a complete blog post with metadata
    func generatePost(
        topic: String,
        targetAudience: String,
        tone: Tone = .professional,
        wordCount: Int = 800
    ) async throws -> BlogPost {
        print("📰 Generating blog post about: \(topic)")
        print("👥 Target audience: \(targetAudience)")
        print("🎭 Tone: \(tone.rawValue)")
        print("📝 Target word count: \(wordCount)")
        print("⏳ Generating...")

        let request = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.7)        // Creative but focused
                MaxOutputTokens(wordCount * 2)  // Allow room for content
                TopP(0.9)              // Balanced creativity
            },
            input: {
                system("""
                You are an expert content creator and SEO specialist who writes high-quality blog posts.
                Create compelling, well-structured content that engages the target audience.

                Your blog posts should include:
                1. SEO-optimized title (under 60 characters)
                2. Compelling meta description (under 160 characters)
                3. Engaging introduction with hook
                4. 3-5 main sections with descriptive headings
                5. Practical takeaways and actionable advice
                6. Strong call-to-action
                7. Natural keyword integration throughout

                Format the response as a complete blog post ready for publishing.
                """)
                user("""
                Write a comprehensive blog post with these specifications:

                TOPIC: \(topic)
                AUDIENCE: \(targetAudience)
                TONE: \(tone.rawValue)
                TARGET LENGTH: Approximately \(wordCount) words

                Make the content:
                - Highly engaging and shareable
                - Optimized for search engines
                - Practical with real examples
                - Authoritative and trustworthy
                - Mobile-friendly in structure

                Focus on providing genuine value to readers.
                """)
            }
        )

        let response = try await client.respond(to: request)
        let content = response.choices.first?.message.content ?? ""

        let post = BlogPost(
            title: extractTitle(from: content),
            content: content,
            topic: topic,
            targetAudience: targetAudience,
            tone: tone,
            wordCount: wordCount,
            generatedAt: Date()
        )

        print("✅ Blog post generated successfully!")
        print("📊 Actual word count: \(content.split(separator: " ").count)")
        print("🎯 Title: \(post.title)")

        return post
    }

    /// Optimize existing content for SEO
    func optimizeForSEO(
        post: BlogPost,
        keywords: [String],
        targetKeywordDensity: Double = 1.5
    ) async throws -> BlogPost {
        print("🔍 Optimizing for SEO...")
        print("🎯 Target keywords: \(keywords.joined(separator: ", "))")

        let optimizationRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.3)        // Factual optimization
                MaxOutputTokens(2000)
            },
            input: {
                system("""
                You are an SEO expert who optimizes content for search engines while maintaining quality.
                Focus on:
                - Natural keyword integration (aim for \(targetKeywordDensity)% density)
                - Improved heading structure (H1, H2, H3 tags)
                - Better meta descriptions and title tags
                - Enhanced readability and user experience
                - Internal linking suggestions
                - Schema markup recommendations
                - Social media optimization

                Maintain the original meaning and quality while improving SEO performance.
                """)
                user("""
                Optimize this blog post for SEO:

                TITLE: \(post.title)
                KEYWORDS TO INTEGRATE: \(keywords.joined(separator: ", "))
                TARGET KEYWORD DENSITY: \(targetKeywordDensity)%

                ORIGINAL CONTENT:
                \(post.content)

                Provide the optimized version with:
                1. Improved title and meta description
                2. Natural keyword integration
                3. Better heading structure
                4. Enhanced readability
                5. SEO recommendations
                """)
            }
        )

        let response = try await client.respond(to: optimizationRequest)
        let optimizedContent = response.choices.first?.message.content ?? post.content

        var optimizedPost = post
        optimizedPost.content = optimizedContent
        optimizedPost.seoOptimized = true
        optimizedPost.keywords = keywords

        print("✅ SEO optimization complete!")
        return optimizedPost
    }

    /// Generate a content calendar for consistent publishing
    func generateContentCalendar(
        niche: String,
        months: Int = 3,
        postsPerWeek: Int = 2
    ) async throws -> ContentCalendar {
        print("📅 Generating content calendar for: \(niche)")
        print("📆 Duration: \(months) months")
        print("📝 Posts per week: \(postsPerWeek)")

        let totalPosts = months * 4 * postsPerWeek // Approximate weeks per month

        let calendarRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.6)        // Creative but practical
                MaxOutputTokens(1500)
            },
            input: {
                system("""
                You are a content strategist who creates comprehensive content calendars.
                Develop a detailed publishing calendar that includes:
                - Pillar content (comprehensive guides)
                - Cluster content (supporting articles)
                - Seasonal and trending topics
                - User intent optimization
                - Internal linking opportunities
                - Content repurposing suggestions

                Balance different content types and difficulty levels.
                """)
                user("""
                Create a \(months)-month content calendar for a \(niche) blog/website.

                REQUIREMENTS:
                - Total posts: \(totalPosts) (\(postsPerWeek) per week)
                - Mix of content types: tutorials, guides, news, opinion pieces
                - SEO-optimized titles and topics
                - Seasonal considerations
                - Difficulty progression for readers

                For each post, provide:
                1. Title (SEO-optimized)
                2. Content type (Tutorial, Guide, News, etc.)
                3. Target keyword
                4. Estimated word count
                5. Publishing week
                6. Brief description
                """)
            }
        )

        let response = try await client.respond(to: calendarRequest)
        let calendarContent = response.choices.first?.message.content ?? ""

        return ContentCalendar(
            niche: niche,
            durationMonths: months,
            postsPerWeek: postsPerWeek,
            content: calendarContent,
            generatedAt: Date()
        )
    }

    /// Extract title from generated content
    private func extractTitle(from content: String) -> String {
        let lines = content.components(separatedBy: "\n")

        // Look for title in first few lines
        for line in lines.prefix(5) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty &&
               !trimmed.hasPrefix("#") &&
               !trimmed.hasPrefix("-") &&
               trimmed.count > 10 &&
               trimmed.count < 100 {
                return trimmed
            }
        }

        // Fallback title
        return "Generated Blog Post: \(content.prefix(50))"
    }
}

// Supporting types
enum Tone: String {
    case professional = "Professional"
    case casual = "Casual"
    case friendly = "Friendly"
    case authoritative = "Authoritative"
    case conversational = "Conversational"
    case technical = "Technical"
}

struct BlogPost {
    var title: String
    var content: String
    var topic: String
    var targetAudience: String
    var tone: Tone
    var wordCount: Int
    var generatedAt: Date
    var seoOptimized: Bool = false
    var keywords: [String] = []

    var readingTimeMinutes: Int {
        let wordsPerMinute = 200
        let wordCount = content.split(separator: " ").count
        return max(1, wordCount / wordsPerMinute)
    }
}

struct ContentCalendar {
    let niche: String
    let durationMonths: Int
    let postsPerWeek: Int
    let content: String
    let generatedAt: Date

    var totalPosts: Int {
        durationMonths * 4 * postsPerWeek
    }
}

// Usage Example
@main
struct BlogGeneratorDemo {
    static func main() async {
        print("📰 SwiftResponsesDSL Blog Post Generator Demo")
        print("==============================================")

        do {
            let generator = try BlogPostGenerator()

            // Generate a blog post
            let post = try await generator.generatePost(
                topic: "Mastering Swift Concurrency: From Async/Await to Actors",
                targetAudience: "iOS developers with 1-3 years experience",
                tone: .technical,
                wordCount: 1200
            )

            print("\n📄 Generated Post Details:")
            print("Title: \(post.title)")
            print("Word Count: \(post.content.split(separator: " ").count)")
            print("Reading Time: \(post.readingTimeMinutes) minutes")
            print("Tone: \(post.tone.rawValue)")

            // Optimize for SEO
            let seoOptimized = try await generator.optimizeForSEO(
                post: post,
                keywords: ["Swift", "concurrency", "async", "await", "actors", "iOS development"]
            )

            print("\n🔍 SEO Optimization Complete!")
            print("Keywords integrated: \(seoOptimized.keywords.joined(separator: ", "))")

            // Generate content calendar
            let calendar = try await generator.generateContentCalendar(
                niche: "iOS Development",
                months: 3,
                postsPerWeek: 2
            )

            print("\n📅 Content Calendar Generated!")
            print("Total posts planned: \(calendar.totalPosts)")
            print("Duration: \(calendar.durationMonths) months")

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
                    print("💡 This might be a temporary API issue")
                }
            }
        }
    }
}
