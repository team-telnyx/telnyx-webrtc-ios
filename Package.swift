// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "telnyx-webrtc-ios",
    products: [
        .library(
            name: "telnyx-webrtc-ios",
            targets: ["TelnyxRTC"]),
    ],
    dependencies: [
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.6"),
        .package(url: "https://github.com/stasel/WebRTC.git", from: "124.0.0")
    ],
    targets: [
        .target(
            name: "TelnyxRTC",
            dependencies: [
                .product(name: "Starscream", package: "Starscream"),
                .product(name: "WebRTC", package: "WebRTC")
            ],
            path: "TelnyxRTC",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        )
    ],
    swiftLanguageVersions: [.v5]
)
