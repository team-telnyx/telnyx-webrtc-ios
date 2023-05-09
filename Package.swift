// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TelnyxRTC",
    platforms: [.iOS(.v13)],
    products: [.library(name: "TelnyxRTC", targets: ["TelnyxRTC"])],
    dependencies: [
        .package(url: "https://github.com/bugsnag/bugsnag-cocoa.git", from: "6.26.2"),
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "3.1.1"),
        .package(url: "https://github.com/stasel/WebRTC.git", branch: "latest")
    ],
    targets: [
        .target(
            name: "TelnyxRTC",
            path: "Sources",
            exclude: ["Info.plsit"]),
        .testTarget(
            name: "TelnyxTests",
            dependencies: ["TelnyxRTC"],
            path: "Tests",
            exclude: ["Info.plist"]),
    ],
    swiftLanguageVersions: [.v5]
)
