// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "UmaCore",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "UmaCore", targets: ["UmaCore"])
    ],
    targets: [
        .target(
            name: "UmaCore",
            resources: [
                .process("Resources"),
                .copy("PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "UmaCoreTests",
            dependencies: ["UmaCore"]
        )
    ]
)
