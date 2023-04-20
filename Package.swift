// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "telnyx-webrtc-ios",
    products: [.library(name: "telnyx-webrtc-ios", targets: ["telnyx-webrtc-ios"])],
    dependencies: [
        .package(url: "https://github.com/team-telnyx/telnyx-webrtc-ios.git", from: "0.1.4"),
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "telnyx-webrtc-ios",
            dependencies: []),
        .testTarget(
            name: "telnyx-webrtc-iosTests",
            dependencies: ["telnyx-webrtc-ios"]),
    ]
)
