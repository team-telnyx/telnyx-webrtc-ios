// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "telnyx-webrtc-ios",
    platforms: [.iOS(.v13)],
    products: [.library(name: "telnyx-webrtc-ios", targets: ["Telnyx"])],
    targets: [
        .target(
            name: "Telnyx",
            path: "Sources",
            exclude: ["Info.plsit"]),
        .testTarget(
            name: "TelnyxRTCTests",
            path: "Tests",
            exclude: ["Info.plist"]),
    ],
    swiftLanguageVersions: [.v5]
)
