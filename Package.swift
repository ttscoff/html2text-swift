// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "html2text-swift",
    platforms: [.iOS(.v15), .macOS(.v11)],
    products: [
        .library(name: "HTML2Text", targets: ["HTML2Text"]),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.0.0"),
    ],
    targets: [
        .target(name: "HTML2Text", dependencies: ["SwiftSoup"]),
        .testTarget(
            name: "HTML2TextTests",
            dependencies: ["HTML2Text"])
    ]
)
