// swift-tools-version:5.9
import PackageDescription

var package = Package(
    name: "PenguiniBot",
    dependencies: [
        .package(url: "https://github.com/google-ai-edge/LiteRT-LM", from: "0.13.1")
    ]
)

package.targets = [
    .target(
        name: "PenguiniBot",
        dependencies: [
            .product(name: "LiteRTLM", package: "LiteRT-LM")
        ]
    )
]

package.swiftLanguageVersions = [.v5]
