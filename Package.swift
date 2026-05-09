// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TextSweepCore",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "TextSweepCore", targets: ["TextSweepCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.19"),
        .package(url: "https://github.com/scinfu/SwiftSoup", from: "2.7.0"),
    ],
    targets: [
        .target(
            name: "TextSweepCore",
            dependencies: [
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
                .product(name: "SwiftSoup", package: "SwiftSoup"),
            ],
            path: "Sources/TextSweepCore"
        ),
        .testTarget(
            name: "TextSweepCoreTests",
            dependencies: [
                "TextSweepCore",
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
            ],
            path: "Tests/TextSweepCoreTests"
        ),
    ]
)
