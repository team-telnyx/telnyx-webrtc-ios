// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "telnyx_webrtc_ios",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "telnyx_webrtc_ios",
            targets: ["telnyx_webrtc_ios"]),
    ],
    dependencies: [
         .package(url: "https://github.com/team-telnyx/telnyx-webrtc-ios.git", from: "0.1.3"),
    ],
    targets: [
        .target(
            name: "telnyx_webrtc_ios",
            path: "Sources"),
    ]
)
