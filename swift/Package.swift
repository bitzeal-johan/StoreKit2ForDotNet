// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SK2ForDotNet",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "SK2ForDotNet", type: .dynamic, targets: ["SK2ForDotNet"]),
    ],
    targets: [
        .target(
            name: "SK2ForDotNet",
            dependencies: []
        ),
    ]
)
