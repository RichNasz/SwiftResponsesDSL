# Performance Guide

@Metadata {
    @DisplayName("Performance")
    @PageKind(article)
}

Optimizing performance is crucial for production LLM applications. This guide covers techniques to maximize efficiency, minimize costs, and ensure responsive user experiences with SwiftResponsesDSL.

## Understanding Performance Costs

### Token Usage and Billing

LLM APIs charge based on token usage (input + output):

```swift
// Monitor token usage in responses
let response = try await client.respond(to: request)
if let usage = response.usage {
    print("📊 Input tokens: \(usage.promptTokens)")
    print("📤 Output tokens: \(usage.completionTokens)")
    print("💰 Total cost: $\(calculateCost(tokens: usage.totalTokens, model: "gpt-4"))")
}

func calculateCost(tokens: Int, model: String) -> Double {
    let rates: [String: Double] = [
        "gpt-4": 0.03,        // $0.03 per 1K tokens
        "gpt-3.5-turbo": 0.002  // $0.002 per 1K tokens
    ]
    return Double(tokens) * (rates[model] ?? 0.0) / 1000.0
}
```

### Performance Metrics to Track

```swift
struct PerformanceMetrics {
    var requestCount: Int = 0
    var totalTokens: Int = 0
    var totalLatency: TimeInterval = 0
    var errorCount: Int = 0

    var averageLatency: TimeInterval {
        requestCount > 0 ? totalLatency / Double(requestCount) : 0
    }

    var errorRate: Double {
        requestCount > 0 ? Double(errorCount) / Double(requestCount) : 0
    }

    var costPerRequest: Double {
        requestCount > 0 ? calculateCost(tokens: totalTokens, model: "gpt-4") / Double(requestCount) : 0
    }
}
```

## Optimization Strategies

### 1. Model Selection Optimization

Choose the right model for your use case:

```swift
enum ModelSelector {
    static func selectModel(for task: TaskType, complexity: Complexity) -> String {
        switch (task, complexity) {
        case (.creative, .high):
            return "gpt-4"           // Best quality, highest cost
        case (.creative, .medium):
            return "gpt-4-turbo"     // Good quality, lower cost
        case (.analytical, .high):
            return "gpt-4"           // Complex reasoning
        case (.analytical, .medium):
            return "gpt-3.5-turbo"   // Fast, cost-effective
        case (.simple, _):
            return "gpt-3.5-turbo"   // Fastest, cheapest
        }
    }

    static func estimateCost(model: String, expectedTokens: Int) -> Double {
        let rates: [String: Double] = [
            "gpt-4": 0.03,
            "gpt-4-turbo": 0.01,
            "gpt-3.5-turbo": 0.002
        ]
        return Double(expectedTokens) * (rates[model] ?? 0.0) / 1000.0
    }
}

enum TaskType { case creative, analytical, simple }
enum Complexity { case low, medium, high }
```

### 2. Request Batching and Parallelization

Process multiple requests efficiently:

```swift
class BatchProcessor {
    private let client: LLMClient
    private let maxConcurrent: Int

    init(client: LLMClient, maxConcurrent: Int = 3) {
        self.client = client
        self.maxConcurrent = maxConcurrent
    }

    func processBatch(requests: [BatchRequest]) async throws -> [BatchResponse] {
        // Create async tasks for parallel processing
        let tasks = requests.enumerated().map { index, request in
            Task {
                let startTime = Date()
                do {
                    let response = try await client.respond(to: request.request)
                    let latency = Date().timeIntervalSince(startTime)
                    return BatchResponse(
                        index: index,
                        response: response,
                        latency: latency,
                        success: true
                    )
                } catch {
                    let latency = Date().timeIntervalSince(startTime)
                    return BatchResponse(
                        index: index,
                        response: nil,
                        latency: latency,
                        success: false,
                        error: error
                    )
                }
            }
        }

        // Control concurrency with a semaphore
        let semaphore = AsyncSemaphore(value: maxConcurrent)
        var results: [BatchResponse] = []

        for task in tasks {
            await semaphore.wait()
            Task {
                let result = await task.value
                results.append(result)
                semaphore.signal()
            }
        }

        // Wait for all tasks to complete
        while results.count < tasks.count {
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }

        // Sort by original order
        return results.sorted { $0.index < $1.index }
    }
}

struct BatchRequest {
    let request: ResponseRequest
    let priority: Int
    let metadata: [String: Any]
}

struct BatchResponse {
    let index: Int
    let response: Response?
    let latency: TimeInterval
    let success: Bool
    let error: Error?
}

struct AsyncSemaphore {
    private var value: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private let lock = NSLock()

    init(value: Int) {
        self.value = value
    }

    func wait() async {
        lock.lock()
        if value > 0 {
            value -= 1
            lock.unlock()
        } else {
            await withCheckedContinuation { continuation in
                waiters.append(continuation)
                lock.unlock()
            }
        }
    }

    func signal() {
        lock.lock()
        if let waiter = waiters.first {
            waiters.removeFirst()
            lock.unlock()
            waiter.resume()
        } else {
            value += 1
            lock.unlock()
        }
    }
}
```

### 3. Intelligent Caching Strategy

Cache responses to reduce API calls and latency:

```swift
class ResponseCache {
    private var cache: [String: CachedResponse] = [:]
    private let cacheDuration: TimeInterval

    init(cacheDuration: TimeInterval = 3600) { // 1 hour default
        self.cacheDuration = cacheDuration
    }

    func get(_ key: String) -> Response? {
        guard let cached = cache[key],
              Date().timeIntervalSince(cached.timestamp) < cacheDuration else {
            cache.removeValue(forKey: key)
            return nil
        }
        return cached.response
    }

    func set(_ key: String, response: Response) {
        let cached = CachedResponse(response: response, timestamp: Date())
        cache[key] = cached

        // Limit cache size to prevent memory issues
        if cache.count > 1000 {
            // Remove oldest entries (simple LRU approximation)
            let oldestKey = cache.min { $0.value.timestamp < $1.value.timestamp }?.key
            if let key = oldestKey {
                cache.removeValue(forKey: key)
            }
        }
    }

    func generateKey(for request: ResponseRequest) -> String {
        var hasher = Hasher()
        hasher.combine(request.model)
        hasher.combine(request.input) // This would need proper hashing
        hasher.combine(request.config)
        return String(hasher.finalize())
    }

    func clear() {
        cache.removeAll()
    }
}

struct CachedResponse {
    let response: Response
    let timestamp: Date
}

// Usage in LLMClient
class CachedLLMClient {
    private let client: LLMClient
    private let cache: ResponseCache

    init(client: LLMClient, cache: ResponseCache = ResponseCache()) {
        self.client = client
        self.cache = cache
    }

    func respond(to request: ResponseRequest) async throws -> Response {
        let cacheKey = cache.generateKey(for: request)

        // Check cache first
        if let cachedResponse = cache.get(cacheKey) {
            return cachedResponse
        }

        // Make API call
        let response = try await client.respond(to: request)

        // Cache the response
        cache.set(cacheKey, response: response)

        return response
    }
}
```

### 4. Streaming Optimization

Optimize streaming for better user experience:

```swift
class StreamingOptimizer {
    private let client: LLMClient

    init(client: LLMClient) {
        self.client = client
    }

    func optimizedStream(request: ResponseRequest, uiDelegate: StreamingUIDelegate) async throws {
        let startTime = Date()

        let stream = client.stream(request: request)
        var buffer = ""
        var wordCount = 0

        for try await event in stream {
            switch event {
            case .outputItemAdded(let item):
                if case .message(let message) = item,
                   let content = message.content {

                    buffer += content
                    wordCount += content.split(separator: " ").count

                    // Throttle UI updates for better performance
                    if shouldUpdateUI(wordCount: wordCount) {
                        await uiDelegate.updateContent(buffer)
                        buffer = ""
                    }
                }

            case .completed(let response):
                // Send any remaining content
                if !buffer.isEmpty {
                    await uiDelegate.updateContent(buffer)
                }

                let totalTime = Date().timeIntervalSince(startTime)
                let tokensPerSecond = Double(response.usage?.completionTokens ?? 0) / totalTime

                await uiDelegate.streamCompleted(
                    totalTime: totalTime,
                    tokensPerSecond: tokensPerSecond,
                    usage: response.usage
                )
            }
        }
    }

    private func shouldUpdateUI(wordCount: Int) -> Bool {
        // Update UI every 10 words for smooth experience
        return wordCount >= 10
    }
}

protocol StreamingUIDelegate: Sendable {
    func updateContent(_ content: String) async
    func streamCompleted(totalTime: TimeInterval, tokensPerSecond: Double, usage: Usage?) async
}
```

## Memory Management

### Large Document Processing

Handle large documents efficiently:

```swift
class DocumentChunker {
    private let client: LLMClient
    private let maxChunkSize: Int

    init(client: LLMClient, maxChunkSize: Int = 4000) {
        self.client = client
        self.maxChunkSize = maxChunkSize
    }

    func processLargeDocument(document: String, task: String) async throws -> [ProcessedChunk] {
        let chunks = chunkDocument(document, maxSize: maxChunkSize)
        var results: [ProcessedChunk] = []

        // Process chunks with controlled concurrency
        let semaphore = AsyncSemaphore(value: 3) // Limit concurrent requests

        let tasks = chunks.enumerated().map { index, chunk in
            Task {
                await semaphore.wait()
                defer { semaphore.signal() }

                let processedChunk = try await processChunk(chunk, task: task)
                return ProcessedChunk(
                    index: index,
                    content: chunk,
                    processed: processedChunk,
                    processingTime: Date().timeIntervalSince(Date())
                )
            }
        }

        for task in tasks {
            let result = try await task.value
            results.append(result)
        }

        // Sort by original order
        return results.sorted { $0.index < $1.index }
    }

    private func chunkDocument(_ document: String, maxSize: Int) -> [String] {
        var chunks: [String] = []
        var currentChunk = ""

        let sentences = document.components(separatedBy: ". ")

        for sentence in sentences {
            if currentChunk.count + sentence.count > maxSize && !currentChunk.isEmpty {
                chunks.append(currentChunk)
                currentChunk = sentence
            } else {
                if !currentChunk.isEmpty {
                    currentChunk += ". "
                }
                currentChunk += sentence
            }
        }

        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }

        return chunks
    }

    private func processChunk(_ chunk: String, task: String) async throws -> String {
        let request = ResponseRequest(
            model: "gpt-3.5-turbo", // Use faster model for chunks
            config: {
                Temperature(0.3)
                MaxOutputTokens(500)
            },
            input: {
                system("You are processing a document chunk. \(task)")
                user("Process this chunk: \(chunk)")
            }
        )

        let response = try await client.respond(to: request)
        return response.choices.first?.message.content ?? ""
    }
}

struct ProcessedChunk {
    let index: Int
    let content: String
    let processed: String
    let processingTime: TimeInterval
}
```

### Memory-Efficient Streaming

Handle large streaming responses without memory issues:

```swift
class MemoryEfficientStreamer {
    private let client: LLMClient

    init(client: LLMClient) {
        self.client = client
    }

    func streamToFile(request: ResponseRequest, fileURL: URL) async throws {
        let stream = client.stream(request: request)
        let fileHandle = try FileHandle(forWritingTo: fileURL)

        defer {
            try? fileHandle.close()
        }

        // Write directly to file to minimize memory usage
        for try await event in stream {
            switch event {
            case .outputItemAdded(let item):
                if case .message(let message) = item,
                   let content = message.content?.data(using: .utf8) {
                    fileHandle.write(content)
                }
            case .completed:
                print("✅ Streaming completed, saved to \(fileURL.path)")
            }
        }
    }

    func streamWithMemoryLimit(request: ResponseRequest, memoryLimit: Int = 50 * 1024 * 1024) async throws -> String {
        let stream = client.stream(request: request)
        var buffer = Data()
        var result = ""

        for try await event in stream {
            switch event {
            case .outputItemAdded(let item):
                if case .message(let message) = item,
                   let content = message.content {
                    let contentData = content.data(using: .utf8) ?? Data()
                    buffer.append(contentData)

                    // Check memory usage
                    if buffer.count > memoryLimit {
                        // Process current buffer
                        if let chunk = String(data: buffer, encoding: .utf8) {
                            result += chunk
                        }
                        buffer.removeAll()
                    }
                }
            case .completed:
                // Process remaining buffer
                if let chunk = String(data: buffer, encoding: .utf8) {
                    result += chunk
                }
                return result
            }
        }

        return result
    }
}
```

## Cost Optimization

### Intelligent Model Selection

```swift
class CostOptimizer {
    private let client: LLMClient

    init(client: LLMClient) {
        self.client = client
    }

    func optimizeRequest(request: ResponseRequest, budget: Double? = nil) -> ResponseRequest {
        var optimizedRequest = request

        // Adjust model based on complexity
        let complexity = estimateComplexity(request: request)
        optimizedRequest.model = selectOptimalModel(complexity: complexity, budget: budget)

        // Adjust parameters for cost efficiency
        optimizedRequest.config = optimizeConfig(request.config, complexity: complexity)

        return optimizedRequest
    }

    private func estimateComplexity(request: ResponseRequest) -> Complexity {
        let inputLength = request.input.reduce(0) { $0 + $1.content.count }
        let hasComplexTasks = request.input.contains { message in
            let content = message.content.first?.text ?? ""
            return content.contains("analyze") ||
                   content.contains("compare") ||
                   content.contains("explain") ||
                   content.contains("design")
        }

        if inputLength > 2000 || hasComplexTasks {
            return .high
        } else if inputLength > 500 {
            return .medium
        } else {
            return .low
        }
    }

    private func selectOptimalModel(complexity: Complexity, budget: Double?) -> String {
        let baseModel: String

        switch complexity {
        case .high:
            baseModel = "gpt-4"
        case .medium:
            baseModel = "gpt-4-turbo"
        case .low:
            baseModel = "gpt-3.5-turbo"
        }

        // If budget is specified, might choose cheaper alternative
        if let budget = budget, budget < 0.01 {
            return "gpt-3.5-turbo" // Cheapest option
        }

        return baseModel
    }

    private func optimizeConfig(_ config: [any ResponseConfigParameter], complexity: Complexity) -> [any ResponseConfigParameter] {
        var optimized = config

        // Remove or adjust expensive parameters for simple tasks
        if complexity == .low {
            optimized = optimized.filter { parameter in
                // Keep essential parameters, remove expensive ones
                !(parameter is PresencePenalty) && !(parameter is FrequencyPenalty)
            }
        }

        return optimized
    }
}

enum Complexity {
    case low, medium, high
}
```

### Usage Monitoring and Alerts

```swift
class UsageMonitor {
    private var dailyUsage: [String: Int] = [:]
    private let dailyLimit: Int

    init(dailyLimit: Int = 100_000) { // Default 100K tokens per day
        self.dailyLimit = dailyLimit
    }

    func recordUsage(response: Response, model: String) {
        let tokens = response.usage?.totalTokens ?? 0
        dailyUsage[model, default: 0] += tokens

        // Check limits
        let totalToday = dailyUsage.values.reduce(0, +)
        if totalToday > dailyLimit * 0.8 { // 80% warning
            print("⚠️  Approaching daily token limit: \(totalToday)/\(dailyLimit)")
        }
    }

    func shouldThrottle(model: String) -> Bool {
        let totalToday = dailyUsage.values.reduce(0, +)
        return totalToday > dailyLimit
    }

    func getUsageReport() -> UsageReport {
        let totalTokens = dailyUsage.values.reduce(0, +)
        let cost = calculateCost(tokens: totalTokens)

        return UsageReport(
            dailyUsage: dailyUsage,
            totalTokens: totalTokens,
            estimatedCost: cost,
            withinLimits: totalTokens <= dailyLimit
        )
    }

    private func calculateCost(tokens: Int) -> Double {
        // Simplified cost calculation
        let gpt4Tokens = dailyUsage["gpt-4"] ?? 0
        let gpt35Tokens = dailyUsage["gpt-3.5-turbo"] ?? 0

        return (Double(gpt4Tokens) * 0.03 + Double(gpt35Tokens) * 0.002) / 1000.0
    }
}

struct UsageReport {
    let dailyUsage: [String: Int]
    let totalTokens: Int
    let estimatedCost: Double
    let withinLimits: Bool
}
```

## Advanced Performance Patterns

### Request Deduplication

Prevent duplicate requests for the same content:

```swift
class RequestDeduplicator {
    private var pendingRequests: [String: Task<Response, Error>] = [:]
    private let cache: ResponseCache

    init(cache: ResponseCache = ResponseCache()) {
        self.cache = cache
    }

    func deduplicatedRequest(_ request: ResponseRequest, client: LLMClient) async throws -> Response {
        let key = generateRequestKey(request)

        // Check cache first
        if let cached = cache.get(key) {
            return cached
        }

        // Check for pending identical request
        if let pendingTask = pendingRequests[key] {
            return try await pendingTask.value
        }

        // Create new task
        let task = Task {
            let response = try await client.respond(to: request)
            cache.set(key, response: response)
            pendingRequests.removeValue(forKey: key)
            return response
        }

        pendingRequests[key] = task
        return try await task.value
    }

    private func generateRequestKey(_ request: ResponseRequest) -> String {
        var hasher = Hasher()
        hasher.combine(request.model)
        hasher.combine(request.input.map { $0.role.rawValue + ($0.content.first?.text ?? "") })
        return String(hasher.finalize())
    }
}
```

### Connection Pooling

For high-throughput applications:

```swift
class ConnectionPool {
    private var clients: [LLMClient] = []
    private let maxConnections: Int
    private var currentIndex = 0

    init(maxConnections: Int = 5) {
        self.maxConnections = maxConnections
    }

    func getClient() async throws -> LLMClient {
        // Simple round-robin load balancing
        if clients.isEmpty {
            try await initializeClients()
        }

        let client = clients[currentIndex % clients.count]
        currentIndex += 1
        return client
    }

    private func initializeClients() async throws {
        for _ in 0..<maxConnections {
            let client = try LLMClient(
                baseURLString: "https://api.openai.com/v1/responses",
                apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!
            )
            clients.append(client)
        }
    }
}
```

## Performance Benchmarks

### Expected Performance Metrics

```swift
struct PerformanceBenchmarks {
    static let expectedLatencies: [String: TimeInterval] = [
        "gpt-3.5-turbo": 2.0,    // 2 seconds average
        "gpt-4": 8.0,           // 8 seconds average
        "gpt-4-turbo": 4.0      // 4 seconds average
    ]

    static let tokenLimits: [String: Int] = [
        "gpt-3.5-turbo": 4096,
        "gpt-4": 8192,
        "gpt-4-turbo": 128000
    ]

    static func isPerformanceAcceptable(latency: TimeInterval, model: String) -> Bool {
        guard let expected = expectedLatencies[model] else { return true }
        return latency <= expected * 1.5 // Allow 50% margin
    }
}
```

### Monitoring Integration

```swift
class PerformanceMonitor {
    private var metrics: [String: PerformanceMetrics] = [:]

    func recordRequest(model: String, latency: TimeInterval, tokens: Int, success: Bool) {
        let key = model
        var metric = metrics[key, default: PerformanceMetrics()]

        metric.requestCount += 1
        metric.totalTokens += tokens
        metric.totalLatency += latency

        if !success {
            metric.errorCount += 1
        }

        metrics[key] = metric

        // Log performance warnings
        if !PerformanceBenchmarks.isPerformanceAcceptable(latency: latency, model: model) {
            print("⚠️  Slow response for \(model): \(latency)s")
        }
    }

    func generateReport() -> PerformanceReport {
        var report = PerformanceReport()

        for (model, metric) in metrics {
            let modelReport = ModelPerformanceReport(
                model: model,
                averageLatency: metric.averageLatency,
                totalTokens: metric.totalTokens,
                requestCount: metric.requestCount,
                errorRate: metric.errorRate,
                costPerRequest: metric.costPerRequest
            )
            report.models.append(modelReport)
        }

        return report
    }
}

struct PerformanceReport {
    var models: [ModelPerformanceReport] = []
}

struct ModelPerformanceReport {
    let model: String
    let averageLatency: TimeInterval
    let totalTokens: Int
    let requestCount: Int
    let errorRate: Double
    let costPerRequest: Double
}
```

This comprehensive performance guide provides the tools and strategies needed to optimize SwiftResponsesDSL applications for production use, balancing cost, performance, and user experience.
