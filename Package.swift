// swift-tools-version:5.9
import PackageDescription

var package = Package(
    name: "PenguiniBot",
    dependencies: [
        .package(url: "https://github.com/paescebu/SwiftTasksGenAI", from: "0.10.24")
    ]
)

package.targets = [
    .target(
        name: "PenguiniBot",
        dependencies: [
            .product(name: "SwiftTasksGenAI", package: "SwiftTasksGenAI")
        ]
    )
]

package.swiftLanguageVersions = [.v5]
