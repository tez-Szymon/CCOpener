// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CCOpener",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CCOpener", targets: ["CCOpener"])
    ],
    targets: [
        .executableTarget(
            name: "CCOpener",
            path: "Sources/CCOpener"
        ),
        .testTarget(
            name: "CCOpenerTests",
            dependencies: ["CCOpener"],
            path: "Tests/CCOpenerTests"
        )
    ]
)
