// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AIChatApp",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .executable(name: "AIChatApp", targets: ["AIChatApp"])
    ],
    dependencies: [
        // Local dependency - in real project, this would be a remote package
        .package(path: "../../")
    ],
    targets: [
        .executableTarget(
            name: "AIChatApp",
            dependencies: [
                .product(name: "SwiftResponsesDSL", package: "SwiftResponsesDSL")
            ]
        ),
        .testTarget(
            name: "AIChatAppTests",
            dependencies: ["AIChatApp"]
        )
    ]
)
