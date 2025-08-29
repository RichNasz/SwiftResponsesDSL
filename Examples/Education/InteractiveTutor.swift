//
//  InteractiveTutor.swift
//  SwiftResponsesDSL Examples
//
//  This example demonstrates an intelligent tutoring system that adapts
//  to student learning patterns and provides personalized education.
//
//  Created by SwiftResponsesDSL Example Generator.
//  https://github.com/RichNasz/SwiftResponsesDSL
//

import SwiftResponsesDSL

/// An intelligent tutoring system that adapts to student needs
class InteractiveTutor {
    private let client: LLMClient
    private var studentProfile: StudentProfile
    private var learningSession: LearningSession

    init(studentProfile: StudentProfile) throws {
        self.client = try LLMClient(
            baseURLString: "https://api.openai.com/v1/responses",
            apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!
        )
        self.studentProfile = studentProfile
        self.learningSession = LearningSession(
            studentId: studentProfile.id,
            subject: studentProfile.currentSubject,
            startedAt: Date()
        )
    }

    /// Provide personalized lesson based on student profile
    func startPersonalizedLesson(topic: String) async throws -> Lesson {
        print("🎓 Starting personalized lesson for \(studentProfile.name)")
        print("📚 Topic: \(topic)")
        print("📊 Skill Level: \(studentProfile.skillLevel.rawValue)")

        let lessonRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.3)        // Educational and factual
                MaxOutputTokens(1500)   // Comprehensive lesson
                TopP(0.85)             // Balanced explanations
            },
            input: {
                system("""
                You are an expert adaptive tutor who creates personalized learning experiences.
                Tailor your teaching approach to the student's profile:

                STUDENT PROFILE:
                - Name: \(studentProfile.name)
                - Skill Level: \(studentProfile.skillLevel.rawValue)
                - Learning Style: \(studentProfile.learningStyle.rawValue)
                - Current Subject: \(studentProfile.currentSubject)
                - Previous Topics: \(studentProfile.completedTopics.joined(separator: ", "))
                - Strengths: \(studentProfile.strengths.joined(separator: ", "))
                - Areas for Improvement: \(studentProfile.areasForImprovement.joined(separator: ", "))

                ADAPTIVE TEACHING STRATEGY:
                - Adjust complexity based on skill level
                - Use preferred learning style (visual, practical, theoretical)
                - Build on existing knowledge and completed topics
                - Address specific areas for improvement
                - Provide appropriate examples and analogies
                - Include interactive elements and practice exercises

                Create engaging, personalized lessons that match the student's abilities and preferences.
                """)
                user("""
                Create a personalized lesson on: \(topic)

                Lesson Structure:
                1. **Warm-up**: Quick review of prerequisites
                2. **Main Content**: Core concepts with examples
                3. **Practice Activities**: Interactive exercises
                4. **Summary**: Key takeaways and next steps
                5. **Assessment**: Quick knowledge check

                Make it engaging and adapted to \(studentProfile.name)'s learning style.
                Include 2-3 practice questions at the end.
                """)
            }
        )

        let response = try await client.respond(to: lessonRequest)
        let lessonContent = response.choices.first?.message.content ?? ""

        let lesson = Lesson(
            id: UUID(),
            topic: topic,
            content: lessonContent,
            studentId: studentProfile.id,
            difficulty: adaptDifficulty(for: topic),
            createdAt: Date()
        )

        learningSession.lessonsCompleted += 1
        print("✅ Personalized lesson created!")
        print("📈 Adapted difficulty: \(lesson.difficulty.rawValue)")

        return lesson
    }

    /// Generate adaptive quiz based on student performance
    func generateAdaptiveQuiz(topic: String, previousScores: [Double]) async throws -> Quiz {
        print("📝 Generating adaptive quiz for: \(topic)")
        print("📊 Previous scores: \(previousScores.map { String(format: "%.1f", $0) }.joined(separator: ", "))")

        let averageScore = previousScores.isEmpty ? 0.7 : previousScores.reduce(0, +) / Double(previousScores.count)

        let quizRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.4)        // Balanced question generation
                MaxOutputTokens(1200)
            },
            input: {
                system("""
                You are an expert educational assessment designer who creates adaptive quizzes.
                Analyze student performance and create appropriately challenging questions.

                STUDENT PERFORMANCE ANALYSIS:
                - Average Score: \(String(format: "%.1f", averageScore))
                - Recent Performance: \(previousScores.suffix(3).map { String(format: "%.1f", $0) }.joined(separator: ", "))
                - Learning Pattern: \(analyzeLearningPattern(previousScores))

                ADAPTIVE QUESTION DESIGN:
                - Adjust difficulty based on performance
                - Include questions slightly above current ability
                - Mix question types (multiple choice, short answer, coding problems)
                - Focus on weak areas identified in previous assessments
                - Include explanations for correct answers
                """)
                user("""
                Create an adaptive quiz for: \(topic)

                Quiz Specifications:
                - 8-12 questions total
                - Mix of difficulty levels based on performance
                - Include answer explanations
                - Provide study recommendations
                - Adaptive difficulty: aim for 70-85% success rate

                Performance Context:
                - Average previous score: \(String(format: "%.1f", averageScore))
                - Adjust difficulty accordingly

                Format as structured JSON with questions, options, answers, and explanations.
                """)
            }
        )

        let response = try await client.respond(to: quizRequest)
        let quizContent = response.choices.first?.message.content ?? "{}"

        return Quiz(
            id: UUID(),
            topic: topic,
            questions: parseQuizQuestions(from: quizContent),
            studentId: studentProfile.id,
            adaptiveDifficulty: calculateAdaptiveDifficulty(averageScore),
            createdAt: Date()
        )
    }

    /// Provide personalized feedback on student work
    func provideFeedback(submission: StudentSubmission) async throws -> Feedback {
        print("📋 Analyzing submission for: \(submission.topic)")
        print("👤 Student: \(studentProfile.name)")
        print("📝 Submission type: \(submission.type.rawValue)")

        let feedbackRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.2)        // Constructive and factual
                MaxOutputTokens(1000)
            },
            input: {
                system("""
                You are an expert educational feedback provider who gives constructive, personalized feedback.
                Focus on:
                - Specific strengths and achievements
                - Areas for improvement with concrete suggestions
                - Learning objectives alignment
                - Encouragement and motivation
                - Next steps for development
                - Individual learning style considerations

                STUDENT CONTEXT:
                - Name: \(studentProfile.name)
                - Skill Level: \(studentProfile.skillLevel.rawValue)
                - Learning Style: \(studentProfile.learningStyle.rawValue)
                - Strengths: \(studentProfile.strengths.joined(separator: ", "))
                - Areas to improve: \(studentProfile.areasForImprovement.joined(separator: ", "))

                Provide balanced, constructive feedback that helps the student grow.
                """)
                user("""
                Provide detailed feedback on this student submission:

                TOPIC: \(submission.topic)
                SUBMISSION TYPE: \(submission.type.rawValue)

                STUDENT WORK:
                \(submission.content)

                Provide feedback that includes:
                1. **Overall Assessment**: Quality rating and summary
                2. **Strengths**: What the student did well
                3. **Areas for Improvement**: Specific suggestions
                4. **Learning Objectives**: How well they were met
                5. **Next Steps**: Concrete recommendations
                6. **Encouragement**: Motivational closing remarks

                Be specific, actionable, and encouraging.
                """)
            }
        )

        let response = try await client.respond(to: feedbackRequest)
        let feedbackContent = response.choices.first?.message.content ?? ""

        return Feedback(
            id: UUID(),
            submissionId: submission.id,
            studentId: studentProfile.id,
            content: feedbackContent,
            feedbackType: .comprehensive,
            createdAt: Date()
        )
    }

    /// Generate personalized study plan
    func createStudyPlan(goals: [LearningGoal], durationWeeks: Int = 4) async throws -> StudyPlan {
        print("📚 Creating study plan for \(studentProfile.name)")
        print("🎯 Goals: \(goals.map { $0.description }.joined(separator: ", "))")
        print("⏰ Duration: \(durationWeeks) weeks")

        let goalsText = goals.map { "- \($0.description) (Priority: \($0.priority.rawValue))" }.joined(separator: "\n")

        let planRequest = ResponseRequest(
            model: "gpt-4",
            config: {
                Temperature(0.3)        // Structured and practical
                MaxOutputTokens(1500)
            },
            input: {
                system("""
                You are an expert educational planner who creates personalized study plans.
                Design comprehensive learning paths that consider:

                STUDENT PROFILE:
                - Name: \(studentProfile.name)
                - Skill Level: \(studentProfile.skillLevel.rawValue)
                - Learning Style: \(studentProfile.learningStyle.rawValue)
                - Daily Available Time: \(studentProfile.dailyStudyTimeMinutes) minutes
                - Weekly Schedule: \(studentProfile.schedulePreferences.joined(separator: ", "))

                PLANNING PRINCIPLES:
                - Balance theory with practical application
                - Include regular assessment and review
                - Build on existing knowledge and strengths
                - Address identified areas for improvement
                - Include breaks and sustainable pace
                - Adapt to preferred learning style
                """)
                user("""
                Create a personalized \(durationWeeks)-week study plan for:

                STUDENT: \(studentProfile.name)
                CURRENT SUBJECT: \(studentProfile.currentSubject)
                SKILL LEVEL: \(studentProfile.skillLevel.rawValue)

                LEARNING GOALS:
                \(goalsText)

                Study Plan Requirements:
                - Daily study time: \(studentProfile.dailyStudyTimeMinutes) minutes
                - Preferred schedule: \(studentProfile.schedulePreferences.joined(separator: ", "))
                - Learning style: \(studentProfile.learningStyle.rawValue)

                Include:
                1. **Weekly Breakdown**: Day-by-day schedule
                2. **Topic Progression**: Logical learning sequence
                3. **Practice Activities**: Hands-on exercises
                4. **Assessment Points**: Regular check-ins
                5. **Resource Recommendations**: Books, videos, tools
                6. **Motivation Strategies**: Staying engaged
                7. **Flexibility Options**: Adjustments for busy weeks

                Make it realistic, achievable, and motivating.
                """)
            }
        )

        let response = try await client.respond(to: planRequest)
        let planContent = response.choices.first?.message.content ?? ""

        return StudyPlan(
            id: UUID(),
            studentId: studentProfile.id,
            goals: goals,
            durationWeeks: durationWeeks,
            content: planContent,
            createdAt: Date()
        )
    }

    // Helper methods
    private func adaptDifficulty(for topic: String) -> Difficulty {
        // Adapt difficulty based on student profile and topic
        let baseDifficulty = studentProfile.skillLevel.baseDifficulty

        // Adjust based on completed topics and performance
        if studentProfile.completedTopics.contains(where: { topic.contains($0) }) {
            return baseDifficulty.nextLevel()
        }

        return baseDifficulty
    }

    private func analyzeLearningPattern(_ scores: [Double]) -> String {
        if scores.isEmpty { return "New learner" }

        let recent = scores.suffix(3)
        let improving = recent.sorted().last == recent.last
        let consistent = scores.allSatisfy { abs($0 - scores[0]) < 0.2 }

        if improving { return "Improving performance" }
        if consistent { return "Consistent performance" }
        return "Variable performance - needs stabilization"
    }

    private func calculateAdaptiveDifficulty(_ averageScore: Double) -> Difficulty {
        switch averageScore {
        case 0.8...: return .advanced
        case 0.6..<0.8: return .intermediate
        default: return .beginner
        }
    }

    private func parseQuizQuestions(from jsonString: String) -> [QuizQuestion] {
        // Simplified parsing - in production, use proper JSON parsing
        // This would parse the AI-generated JSON into structured questions
        return []
    }
}

// Supporting types
struct StudentProfile {
    let id: UUID
    let name: String
    let skillLevel: SkillLevel
    let learningStyle: LearningStyle
    let currentSubject: String
    let completedTopics: [String]
    let strengths: [String]
    let areasForImprovement: [String]
    let dailyStudyTimeMinutes: Int
    let schedulePreferences: [String]

    var displayName: String { name }
}

enum SkillLevel: String {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var baseDifficulty: Difficulty {
        switch self {
        case .beginner: return .beginner
        case .intermediate: return .intermediate
        case .advanced: return .advanced
        }
    }
}

enum LearningStyle: String {
    case visual = "Visual"
    case practical = "Hands-on/Practical"
    case theoretical = "Theoretical/Conceptual"
    case mixed = "Mixed approaches"
}

enum Difficulty: String {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    func nextLevel() -> Difficulty {
        switch self {
        case .beginner: return .intermediate
        case .intermediate: return .advanced
        case .advanced: return .advanced
        }
    }
}

struct LearningGoal {
    let description: String
    let priority: Priority
    let timeframe: String
}

enum Priority: String {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

struct Lesson {
    let id: UUID
    let topic: String
    let content: String
    let studentId: UUID
    let difficulty: Difficulty
    let createdAt: Date
}

struct Quiz {
    let id: UUID
    let topic: String
    let questions: [QuizQuestion]
    let studentId: UUID
    let adaptiveDifficulty: Difficulty
    let createdAt: Date
}

struct QuizQuestion {
    let id: UUID
    let question: String
    let options: [String]?
    let correctAnswer: String
    let explanation: String
}

struct StudentSubmission {
    let id: UUID
    let studentId: UUID
    let topic: String
    let content: String
    let type: SubmissionType
    let submittedAt: Date
}

enum SubmissionType: String {
    case homework = "Homework"
    case quiz = "Quiz"
    case project = "Project"
    case exercise = "Exercise"
}

struct Feedback {
    let id: UUID
    let submissionId: UUID
    let studentId: UUID
    let content: String
    let feedbackType: FeedbackType
    let createdAt: Date
}

enum FeedbackType: String {
    case quick = "Quick Feedback"
    case comprehensive = "Comprehensive Review"
    case peer = "Peer Review"
}

struct StudyPlan {
    let id: UUID
    let studentId: UUID
    let goals: [LearningGoal]
    let durationWeeks: Int
    let content: String
    let createdAt: Date
}

struct LearningSession {
    let studentId: UUID
    let subject: String
    var lessonsCompleted: Int = 0
    var quizzesTaken: Int = 0
    var averageScore: Double = 0.0
    let startedAt: Date
}

// Demo usage
@main
struct InteractiveTutorDemo {
    static func main() async {
        print("🎓 SwiftResponsesDSL Interactive Tutor Demo")
        print("===========================================")

        // Create a sample student profile
        let student = StudentProfile(
            id: UUID(),
            name: "Alex Johnson",
            skillLevel: .intermediate,
            learningStyle: .practical,
            currentSubject: "Swift Programming",
            completedTopics: ["Variables", "Functions", "Classes", "Optionals"],
            strengths: ["Problem-solving", "Code organization", "Debugging"],
            areasForImprovement: ["Async programming", "UI design", "Testing"],
            dailyStudyTimeMinutes: 60,
            schedulePreferences: ["Evenings", "Weekends", "Short daily sessions"]
        )

        do {
            let tutor = try InteractiveTutor(studentProfile: student)

            // Generate a personalized lesson
            let lesson = try await tutor.startPersonalizedLesson(topic: "Swift Concurrency with Async/Await")

            print("\n📖 Personalized Lesson Generated!")
            print("Topic: \(lesson.topic)")
            print("Difficulty: \(lesson.difficulty.rawValue)")
            print("Length: \(lesson.content.count) characters")

            // Generate an adaptive quiz
            let quiz = try await tutor.generateAdaptiveQuiz(
                topic: "Swift Concurrency",
                previousScores: [0.75, 0.82, 0.78]
            )

            print("\n📝 Adaptive Quiz Created!")
            print("Questions: \(quiz.questions.count)")
            print("Adaptive Difficulty: \(quiz.adaptiveDifficulty.rawValue)")

            // Create a study plan
            let goals = [
                LearningGoal(
                    description: "Master async/await patterns",
                    priority: .high,
                    timeframe: "2 weeks"
                ),
                LearningGoal(
                    description: "Understand actor model",
                    priority: .medium,
                    timeframe: "1 week"
                )
            ]

            let studyPlan = try await tutor.createStudyPlan(goals: goals, durationWeeks: 3)

            print("\n📚 Study Plan Created!")
            print("Goals: \(studyPlan.goals.count)")
            print("Duration: \(studyPlan.durationWeeks) weeks")

        } catch {
            print("❌ Error: \(error.localizedDescription)")

            if let llmError = error as? LLMError {
                switch llmError {
                case .authenticationFailed:
                    print("💡 Check your OPENAI_API_KEY environment variable")
                case .rateLimit:
                    print("💡 You've hit the API rate limit. Try again later.")
                default:
                    print("💡 Check your network connection and API configuration")
                }
            }
        }
    }
}
