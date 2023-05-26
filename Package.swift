// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "telnyx-webrtc-ios",
    products: [
        .library(
            name: "telnyx-webrtc-ios",
            targets: ["TelnyxRTC", "TelnyxRTCTests"]),
    ],
    dependencies: [
        .package(url: "https://github.com/bugsnag/bugsnag-cocoa.git", from: "6.27.0"),
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.4"),
        .package(url: "https://github.com/stasel/WebRTC.git", from: "88.0.0")
    ],
    targets: [
        .target(
            name: "TelnyxRTC",
            dependencies: [
                .product(name: "Bugsnag", package: "bugsnag-cocoa"),
                .product(name: "Starscream", package: "Starscream"),
                .product(name: "WebRTC", package: "WebRTC")
            ],
            path: "TelnyxRTC",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "TelnyxRTCTests",
            dependencies: ["TelnyxRTC"],
            path: "TelnyxRTCTests",
            exclude: ["Info.plist"]),
    ],
    swiftLanguageVersions: [.v5]
)
