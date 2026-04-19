// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CleanMyScreen",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "CleanMyScreen",
            targets: ["CleanMyScreen"]
        ),
        .executable(
            name: "CleanMyScreenVerification",
            targets: ["CleanMyScreenVerification"]
        )
    ],
    targets: [
        .target(
            name: "CleanMyScreenKit",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "CleanMyScreen",
            dependencies: ["CleanMyScreenKit"]
        ),
        .executableTarget(
            name: "CleanMyScreenVerification",
            dependencies: ["CleanMyScreenKit"]
        )
    ]
)
