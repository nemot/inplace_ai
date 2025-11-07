// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "InplaceAI",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "InplaceAI", targets: ["InplaceAI"])
    ],
    targets: [
        .executableTarget(
            name: "InplaceAI",
            path: "Sources"
        )
    ]
)
