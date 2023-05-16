// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "TelnyxRTC",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "TelnyxRTC",
            targets: ["TelnyxRTC"])
    ],
    dependencies: [
        .package(url: "https://github.com/bugsnag/bugsnag-cocoa.git", .upToNextMajor(from: "6.9.1")),
        .package(url: "https://github.com/daltoniam/Starscream.git", .upToNextMajor(from: "4.0.4")),
        .package(url: "https://github.com/alexpiezo/WebRTC.git", .upToNextMajor(from: "1.1.31567"))
    ],
    targets: [
        .target(
            name: "TelnyxRTC",
            dependencies: [
                .product(name: "Bugsnag", package: "bugsnag-cocoa"),
                "Starscream",
                "WebRTC"
            ],
            path: "TelnyxRTC"),
        .testTarget(
            name: "TelnyxRTCTests",
            dependencies: [
                "TelnyxRTC"
            ],
            path: "TelnyxRTCTests"
        )
    ]
)
