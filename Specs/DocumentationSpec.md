# Swift Package Documentation Specification: SwiftResponsesDSL

## Overview
This document specifies the documentation requirements for the package named SwiftResponsesDSL

## Requirements
- **Documentation**: Include a README.md with an overview of the project, a summary of what a DSL is, a description of the DSL in the package, and simple usage examples that includes streaming and non-streaming text inference requests. Use DocC for comprehensive documentation, with a `.docc` folder containing articles.

## README.md Structure
The root README.md file must include the following sections in order:

1. **Package Title and Badge Section**
   - Project name and brief tagline
   - Swift version badge: `![Swift](https://img.shields.io/badge/Swift-6.2+-orange.svg)`
   - Platform badges: `![macOS](https://img.shields.io/badge/macOS-12+-blue.svg)` `![iOS](https://img.shields.io/badge/iOS-15+-blue.svg)` `![Linux](https://img.shields.io/badge/Linux-Ubuntu_22.04+-blue.svg)`
   - Build status: `![CI](https://github.com/RichNasz/SwiftResponsesDSL/workflows/CI/badge.svg)`
   - Documentation: `![Documentation](https://github.com/RichNasz/SwiftResponsesDSL/workflows/Documentation/badge.svg)`

2. **Overview Section**
   - Clear description of what SwiftResponsesDSL does
   - Brief explanation of what a DSL (Domain Specific Language) is
   - Key benefits and use cases

3. **Quick Start Section**
   - Installation instructions (Swift Package Manager)
   - Minimal working example (< 10 lines of code)
   - Link to comprehensive documentation

4. **Usage Examples Section**
   - Basic non-streaming example with explanation
   - Basic streaming example with explanation
   - Link to Examples/ folder for more complex scenarios

5. **Documentation Links Section**
   - Link to generated DocC documentation
   - Link to DSL guide for beginners
   - Link to architecture documentation

6. **Requirements Section**
   - Swift version requirements
   - Platform support (macOS 12+, iOS 15+)
   - Dependencies (if any)

7. **API Reference Section**
   - Link to complete API documentation
   - Search functionality for API symbols
   - Code examples for each major API component

8. **Troubleshooting Section**
   - Common error scenarios and solutions
   - Debug mode configuration
   - Logging and diagnostics information

9. **Community and Support Section**
    - GitHub repository: `https://github.com/RichNasz/SwiftResponsesDSL`
    - Issue reporting: `https://github.com/RichNasz/SwiftResponsesDSL/issues`
    - Pull requests: `https://github.com/RichNasz/SwiftResponsesDSL/pulls`
    - Discussions: `https://github.com/RichNasz/SwiftResponsesDSL/discussions`
    - Stack Overflow tags: `[swift-responses-dsl]`
    - Security reporting: `https://github.com/RichNasz/SwiftResponsesDSL/security/advisories`

10. **Changelog Section**
    - Recent changes and improvements
    - Link to full changelog
    - Migration notes for recent versions

11. **Contributing and License Section**
    - Contribution guidelines with detailed process
    - Code of conduct
    - License information
    - Security reporting process

## Documentation Strategy & Planning

### Content Strategy
- **Target Audience Analysis**: Identify and prioritize different user personas:
  - Beginners learning Swift and DSL concepts
  - Intermediate developers integrating LLM APIs
  - Advanced users building complex applications
  - Framework contributors and maintainers
- **Content Maturity Model**: Define documentation progression paths
- **Success Metrics**: Establish KPIs for documentation effectiveness

### Documentation Planning Process
1. **Content Inventory**: Audit existing documentation and identify gaps
2. **User Research**: Gather feedback from target audiences
3. **Content Roadmap**: Plan documentation releases aligned with code releases
4. **Quality Gates**: Establish review processes for documentation changes
5. **Maintenance Schedule**: Regular content updates and reviews

## DocC Documentation
Documentation must be generated using DocC, Apple's documentation compiler for Swift. All public APIs in source files must include triple-slash (///) comments structured with Markdown sections (e.g., Summary, Discussion, Parameters, Returns, Throws) as per Apple standards.

**CRITICAL REQUIREMENT**: The documentation must include a comprehensive DSL (Domain Specific Language) guide that makes SwiftResponsesDSL accessible to developers at all experience levels. The DSL documentation is essential for package adoption and significantly lowers the barrier to entry for new users.

### DocC Best Practices
- **Progressive Disclosure**: Present information from simple to complex
- **Cross-Platform Consistency**: Ensure documentation works across all supported platforms
- **Version Awareness**: Clearly indicate feature availability by platform/version
- **Interactive Elements**: Leverage DocC's capabilities for enhanced user experience

Create a DocC catalog in the target source directory: `Sources/SwiftResponsesDSL/SwiftResponsesDSL.docc/`. **Critical**: The catalog must be located within the target's source directory (`Sources/SwiftResponsesDSL/`) for Xcode's DocC plugin to properly associate documentation with the target and build it automatically. This folder contains markdown articles and resources. To build the DocC archive, run:
```bash
swift package generate-documentation --target SwiftResponsesDSL
```
This produces a `.doccarchive` file for hosting or viewing in Xcode/Preview.

### API Documentation Standards
All public APIs must include comprehensive triple-slash comments following this structure:

```swift
/// Brief summary of what the function/type does (max 120 characters).
///
/// Detailed discussion explaining the purpose, behavior, and any important
/// implementation details. This section can span multiple paragraphs and
/// should include context about when and why to use this API.
///
/// ## Overview
/// Provide additional context about the API's role in the larger system.
///
/// ## Usage Notes
/// Include important usage patterns, best practices, or common pitfalls.
///
/// - Parameters:
///   - parameterName: Description of what this parameter does, including:
///     - Valid ranges or values
///     - Default behavior if optional
///     - Performance implications
///   - anotherParam: Description with constraints or validation rules
/// - Returns: Description of what is returned, including:
///   - Type information and structure
///   - Possible values or ranges
///   - Performance characteristics
/// - Throws: List of specific errors that can be thrown with descriptions:
///   - `SpecificError.case`: Detailed explanation of when this error occurs
///   - Include recovery suggestions when applicable
/// - Note: Additional important information for developers
/// - Warning: Critical warnings about usage or potential issues
/// - Important: Information that developers must be aware of
/// - SeeAlso: References to related APIs or documentation
/// - Precondition: Requirements that must be met before calling
/// - Postcondition: Guarantees about the state after execution
///
/// ## Example Usage
/// ```swift
/// // Preferred usage pattern
/// let example = try SomeType(parameter: "value")
/// let result = try example.someMethod()
///
/// // Alternative approaches
/// if let alternative = try? example.alternativeMethod() {
///     print("Alternative result: \(alternative)")
/// }
/// ```
///
/// ## Performance Considerations
/// - Time complexity: O(n) for typical usage
/// - Space complexity: O(1) additional space required
/// - Thread safety: Safe to call from any thread
///
/// ## Migration Notes
/// - Since version 2.0: This method replaces the deprecated `oldMethod()`
/// - Breaking change in 3.0: Parameter `oldParam` renamed to `newParam`
public func someMethod(parameter: String) throws -> ResultType {
    // Implementation
}
```

### Documentation Metadata Standards
All public symbols must include appropriate metadata:

```swift
/// A configuration parameter for controlling randomness in responses.
///
/// Use this parameter to control the randomness of the model's responses.
/// Higher values (closer to 1.0) make output more random, while lower values
/// make it more focused and deterministic.
///
/// ## Example
/// ```swift
/// let config = Temperature(0.7)  // Balanced creativity and focus
/// ```
public struct Temperature: ResponseConfigParameter {
    /// The temperature value between 0.0 and 2.0
    public let value: Double

    /// Creates a new temperature configuration.
    ///
    /// - Parameter value: The temperature value (0.0-2.0)
    /// - Throws: `LLMError.invalidValue` if value is outside valid range
    public init(_ value: Double) throws
}
```

### Symbol Visibility Guidelines
- **Public**: Core APIs intended for external use
- **Internal**: Implementation details not meant for external consumption
- **Private**: Internal implementation, not visible in documentation
- **Package**: Available within the package but not to external consumers

### DocC Catalog Structure
The catalog structure within the target source directory:
```
SwiftResponsesDSL/                           ← Package root
├── Package.swift
├── README.md                                      ← Root README with quick start
├── Sources/
│   └── SwiftResponsesDSL/                   ← Target source directory
│       ├── SwiftResponsesDSL.docc/         ← DocC catalog here (within target)
│       │   ├── SwiftResponsesDSL.md        ← Main documentation file (target-named, includes introduction)
│       │   ├── Architecture.md                   ← Article (standard Markdown format)
│       │   ├── DSL.md                            ← Article (standard Markdown format) - DSL guide for beginners
│       │   ├── Usage.md                          ← Article (standard Markdown format)
│       │   └── Resources/                        ← Images, diagrams, assets
│       │       ├── architecture-diagram.png
│       │       ├── dsl-flow-chart.svg
│       │       └── code-examples/
│       └── ...                                   ← Source files
├── Tests/
└── Examples/
```

### Resource Management Guidelines
The `Resources/` folder within the DocC catalog should organize assets as follows:
- **Images**: Use `.png` for screenshots, `.svg` for diagrams when possible
- **Code Examples**: Store longer code examples in separate files for reuse
- **Naming Convention**: Use kebab-case with descriptive names (e.g., `streaming-example-diagram.png`)
- **File Size**: Optimize images for web viewing (< 500KB recommended)
- **Documentation**: Include alt-text for all images for accessibility

**Important File Naming Convention**: 
- **Main documentation file** must be named after the target (`SwiftResponsesDSL.md`) for proper Xcode DocC plugin integration
- **Articles** use `.md` extension with standard Markdown format (no special directives required)
All conventions conform to Apple's DocC standards for optimal developer documentation generation.

**Required Documentation Articles**:
- **SwiftResponsesDSL.md** (REQUIRED): Main target documentation file
- **Architecture.md** (REQUIRED): Technical architecture and design patterns
- **DSL.md** (REQUIRED): Critical beginner-friendly Domain Specific Language guide
- **Usage.md** (REQUIRED): Comprehensive usage examples for all experience levels

**Target Source Directory Location Benefits**:
- **Xcode Integration**: DocC plugin automatically discovers and builds documentation when located in target source directory
- **SPM Compatibility**: `swift package generate-documentation` works seamlessly with target-associated documentation
- **Target Association**: Documentation correctly associates with the SwiftResponsesDSL target by being in its source directory
- **Build Automation**: Documentation builds automatically when building the target in Xcode
- **Source Proximity**: Documentation lives alongside the source code it documents, improving maintainability
- **Distribution Ready**: Generated `.doccarchive` is properly structured for hosting with correct target association

The documentation files should be generated with content that aligns with the package's purpose:

### Documentation Article Specifications

- **SwiftResponsesDSL.md**: Main target documentation with the following structure:
  1. Introduction and overview 
  2. Key benefits and getting started guide
  3. **"Learn More About" section** with cross-references to other articles (placed after introductory content, before Topics section)
  4. **Topics section** organizing all API symbols by category
  5. **See Also section** with article descriptions

- **Architecture.md**: Detailed technical explanations of the package architecture using standard Markdown format:
  - Result Builder Pattern implementation
  - Actor-based concurrency model
  - Type-safe configuration system
  - JSON serialization strategy
  - Error handling patterns
  - Extensibility points for custom messages and parameters

- **DSL.md**: **CRITICAL** beginner-friendly guide to the Domain Specific Language using standard Markdown format. This article is essential for package adoption as it makes SwiftResponsesDSL accessible to developers unfamiliar with DSLs. Must include:
  - What DSLs are and why they matter
  - Step-by-step examples starting with simple workflows
  - Common patterns and best practices
  - Practical code examples without assuming prior DSL knowledge
  - Comparison with traditional API approaches
  - Progressive complexity from basic to advanced usage
  - Troubleshooting common DSL mistakes

- **Usage.md**: Practical examples and code snippets for all experience levels using standard Markdown format:
  - **For Beginners** section with non-technical explanations
  - Basic streaming and non-streaming examples
  - Configuration parameter usage
  - Conversation management patterns
  - Error handling examples
  - **Graduating to Advanced** subsection showing how to use all features of the DSL
  - Custom message and parameter extensions
  - Integration with different LLM providers

**Critical Structure**: The "Learn More About" section in SwiftResponsesDSL.md must come after introductory content but before the Topics section to ensure proper navigation flow for developers browsing the documentation.

### Code Example Standards
All code examples in documentation must follow these standards:

- **Language Tags**: Always specify `swift` for Swift code blocks
- **Complete Examples**: Provide runnable code when possible, not fragments
- **Comments**: Include explanatory comments for complex operations
- **Error Handling**: Show proper error handling patterns
- **Imports**: Include necessary import statements
- **Formatting**: Use consistent indentation (4 spaces) and Swift naming conventions

Example format:
```swift
import SwiftResponsesDSL

// Create a client for OpenAI's API
let client = try LLMClient(
    baseURL: "https://api.openai.com/v1/chat/completions",
    apiKey: "your-api-key-here"
)

// Build a request using the DSL
let request = try ChatRequest(model: "gpt-4") {
    try Temperature(0.7)
    try MaxTokens(150)
} messages: {
    TextMessage(role: .system, content: "You are a helpful assistant.")
    TextMessage(role: .user, content: "Explain async/await in Swift.")
}

// Send the request
let response = try await client.complete(request)
print(response.choices.first?.message.content ?? "No response")
```

### DocC Documentation Generation
- **File Extensions**: Articles use `.md` with standard Markdown format
- **Content Structure**: Use standard Markdown headers, lists, code blocks, and formatting
- **Cross-References**: Use `<doc:FileName>` syntax for linking between documentation files
- **Code Examples**: Include practical code examples directly in Markdown code blocks with proper language tags
- **DSL Documentation**: **MANDATORY** creation of DSL.md article explaining Domain Specific Language concepts with beginner-friendly examples, step-by-step tutorials, and practical code samples
- **Generation Command**: Document generation with `swift package generate-documentation --target SwiftResponsesDSL`
- **GitHub Pages**: Deploy documentation to `https://richnasz.github.io/SwiftResponsesDSL/`
- **Repository**: Documentation source at `https://github.com/RichNasz/SwiftResponsesDSL/tree/main/Sources/SwiftResponsesDSL/SwiftResponsesDSL.docc/`

### Version and Release Documentation
- **CHANGELOG.md**: Maintain a changelog following semantic versioning with sections for:
  - Added: New features and capabilities
  - Changed: Modifications to existing functionality
  - Deprecated: Soon-to-be removed features
  - Removed: Deleted features
  - Fixed: Bug fixes
  - Security: Security-related changes
  - Location: `https://github.com/RichNasz/SwiftResponsesDSL/blob/main/CHANGELOG.md`
- **Migration Guides**: Include detailed migration instructions for breaking changes with:
  - Before/after code examples
  - Step-by-step migration process
  - Compatibility matrices
  - Rollback procedures
- **Version Compatibility**: Document Swift and platform version requirements for each release
- **Deprecation Notices**: Clearly mark deprecated APIs with migration paths and timelines

### Additional Documentation Articles
- **Troubleshooting.md**: Common issues and solutions
- **FAQ.md**: Frequently asked questions organized by category
- **Performance.md**: Performance considerations and optimization tips
- **Contributing.md**: Detailed contribution guidelines for documentation
- **Migration.md**: Comprehensive migration guide for major version upgrades

### Advanced DocC Features
- **Custom Themes**: Utilize DocC's theming capabilities for branded documentation
- **Interactive Tutorials**: Include downloadable example projects
- **Code Snippet Testing**: Implement automated testing of documentation code examples
- **Documentation Extensions**: Leverage DocC extensions for enhanced formatting

### CI/CD Integration
- **Automated Documentation Generation**: Set up GitHub Actions for automatic DocC generation
  - Workflow file: `.github/workflows/documentation.yml`
  - Repository: `https://github.com/RichNasz/SwiftResponsesDSL`
- **Link Checking**: Implement automated link validation in CI pipeline
  - Action: `lycheeverse/lychee-action`
- **Documentation Testing**: Automated verification that code examples compile
  - Swift build verification in CI
- **Deployment Automation**: Automated deployment to GitHub Pages
  - Pages URL: `https://richnasz.github.io/SwiftResponsesDSL/`
  - Deployment from `docs/` branch

### Internationalization & Accessibility
- **Localization Support**: Prepare documentation structure for multiple languages
- **Accessibility Standards**: Follow WCAG 2.1 guidelines for web documentation
- **Screen Reader Optimization**: Ensure documentation works with screen readers
- **Keyboard Navigation**: Support full keyboard navigation in web documentation

### Developer Experience Enhancements
- **Quick Reference Cards**: Create printable quick reference guides
- **Video Tutorials**: Include video walkthroughs for complex concepts
- **Interactive Examples**: Provide online playgrounds for experimentation
- **Community Resources**: Link to community discussions, Stack Overflow, etc.

### Quality Assurance
- **Link Validation**: Ensure all cross-references and external links work
  - Use GitHub Actions for automated link checking
- **Code Testing**: Verify all code examples compile and run correctly
  - CI workflow validates example compilation
- **Accessibility**: Include alt-text for images and diagrams, follow WCAG guidelines
  - Accessibility audit: `https://github.com/RichNasz/SwiftResponsesDSL/blob/main/.github/workflows/accessibility.yml`
- **Consistency**: Maintain consistent terminology and formatting throughout
- **SEO Optimization**: Include meta descriptions and structured data for search engines
- **Mobile Responsiveness**: Ensure documentation works well on mobile devices
- **Review Process**: Documentation changes should be reviewed alongside code changes
- **Automated Quality Checks**: Implement tooling for documentation quality validation
  - Quality gates: `https://github.com/RichNasz/SwiftResponsesDSL/blob/main/.github/workflows/docs-quality.yml`

### Documentation Maintenance
- **Version Management**: Tag documentation versions with releases
  - Release tags: `https://github.com/RichNasz/SwiftResponsesDSL/tags`
- **Archival Strategy**: Maintain archives of previous documentation versions
- **Feedback Integration**: Include mechanisms for user feedback and suggestions
  - GitHub Discussions: `https://github.com/RichNasz/SwiftResponsesDSL/discussions`
  - Issues: `https://github.com/RichNasz/SwiftResponsesDSL/issues`
- **Analytics Integration**: Track documentation usage and popular sections
  - GitHub Insights: `https://github.com/RichNasz/SwiftResponsesDSL/pulse`
- **Regular Updates**: Schedule regular documentation review and updates

## Documentation Governance & Workflow

### Review Process
- **Documentation Reviews**: Require documentation review alongside code reviews
- **Technical Accuracy**: Ensure all code examples compile and work as documented
- **Clarity Assessment**: Evaluate documentation for understandability at target skill levels
- **Completeness Check**: Verify all public APIs are documented

### Contribution Workflow
- **Branch Strategy**: Use feature branches for documentation changes
- **Pull Request Template**: Include documentation checklist in PR template
- **Automated Checks**: Implement CI checks for documentation quality
- **Review Assignments**: Assign documentation experts for technical content

### Content Ownership
- **Subject Matter Experts**: Identify SME for different documentation areas
- **Review Cycles**: Establish regular review schedules for different content types
- **Update Triggers**: Define when documentation must be updated (API changes, releases)
- **Stale Content**: Process for identifying and updating outdated documentation

### Quality Metrics
- **Readability Scores**: Use tools to assess documentation readability
- **Completion Rates**: Track tutorial completion rates
- **User Feedback**: Monitor and respond to documentation feedback
- **Search Performance**: Optimize for discoverability of key content

### Tooling & Automation
- **Documentation Linters**: Use tools to check documentation quality
  - `markdownlint`: For Markdown formatting consistency
  - `vale`: For style and grammar checking
- **Link Checkers**: Automate validation of all documentation links
  - `lychee`: Fast link checker for documentation
  - GitHub Action: `lycheeverse/lychee-action`
- **Example Testers**: Automatically test that code examples compile
  - Swift build verification in CI
  - Custom script to extract and test code examples
- **Analytics Tools**: Track documentation usage and effectiveness
  - GitHub Insights: Repository analytics and traffic
  - Google Analytics: For hosted documentation sites