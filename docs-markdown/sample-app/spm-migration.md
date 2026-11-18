# Demo app: CocoaPods to Swift Package Manager

Related to [VSDK-1057](https://linear.app/telnyx/issue/VSDK-1057/ios-migrate-demo-app-from-cocoapods-to-spm).

## Scope

Open `TelnyxRTC.xcodeproj` and select `TelnyxWebRTCDemo`. The demo no longer needs `pod install`, generated Pods xcconfigs, Pods build phases, or a CocoaPods workspace. Local SDK development/tests and the SDK podspec/publishing workflow remain unchanged.

The demo uses these exact package versions:

- `https://github.com/team-telnyx/telnyx-webrtc-ios.git`: **4.2.4**, product `telnyx-webrtc-ios` (Swift import remains `TelnyxRTC`). This was the latest published SDK release when the migration was prepared.
- `https://github.com/firebase/firebase-ios-sdk.git`: **11.15.0**, products `FirebaseCore` and `FirebaseAnalytics`. Retaining Analytics preserves the former `Firebase/Core` default integration rather than silently dropping it. This is a deliberate compatible pin, not a claim that it is the latest Firebase release.
- `https://github.com/ashleymills/Reachability.swift.git`: **5.2.1**, product/import `Reachability` (the old pod name was `ReachabilitySwift`).

## Build validation

From a clean checkout without a `Pods/` directory or generated root workspace:

```sh
xcodebuild -resolvePackageDependencies -project TelnyxRTC.xcodeproj -scheme TelnyxWebRTCDemo
xcodebuild -project TelnyxRTC.xcodeproj -scheme TelnyxWebRTCDemo \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Device/UI-test builds use the same project via `fastlane build_for_testing`. The Firebase UI workflow resolves packages instead of installing pods. SDK unit-test lanes intentionally continue using their CocoaPods workspace.

Xcode resolution generates a real `Package.resolved` at `TelnyxRTC.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`. The migration includes this lockfile to pin transitive dependencies; exact top-level versions alone do not pin all transitives. `.gitignore` allows this specific lockfile while continuing to exclude generated workspace and user data. Do not hand-author a lockfile with guessed revisions.

## Customer migration gotchas

- Remove the app's old Telnyx pod integration and stale linked/embedded frameworks before adding the package. Do not link CocoaPods and SPM copies of TelnyxRTC/WebRTC/Starscream into the same app.
- The Xcode package product is `telnyx-webrtc-ios`; application source still uses `import TelnyxRTC`.
- This repository contains a same-named local `TelnyxRTC` framework target. The demo removes its target dependency and manual framework embedding, and disables implicit dependencies in its shared scheme to avoid selecting the local framework. External customer projects normally do not have that local target.
- Keep the existing iOS 15.6 demo deployment target, Firebase plist, microphone permission, VoIP/audio background modes, push entitlement, signing setup, and PushKit/CallKit delegates. Dependency-manager migration does not configure APNS or change the calling lifecycle.
- To test local SDK changes in the demo, explicitly override the package in Xcode for development; do not accidentally use an unreleased branch as evidence for released-package compatibility.

## Evidence and remaining acceptance checks

The migration was structurally validated with Ruby's `xcodeproj` library, then resumed with Xcode 27.1 after license acceptance. Native package resolution succeeded and generated 18 real package pins. Simulator Debug build and simulator `build-for-testing` both succeeded without Pods, using the released SDK 4.2.4 package rather than the local SDK target.

The first local checkout lacked the untracked `TelnyxWebRTCDemo/GoogleService-Info.plist` (CI normally decodes it from `TEST_UI_FIREBASE_PLIST_BASE64`). Initial compile-only builds explicitly excluded that resource. After the supplied real plist was installed locally, simulator Debug build and simulator `build-for-testing` both succeeded with only `CODE_SIGNING_ALLOWED=NO` and no resource exclusion. The built app contains the supplied plist, which remains git-ignored and untracked. No placeholder configuration was created.

The app was installed and launched on an iPhone 17 Pro simulator running iOS 26.5, and its process remained running in a subsequent check. This is launch-smoke evidence, not call/audio/push or Firebase functional validation. The supplied Firebase plist's `BUNDLE_ID` does not match the demo's `com.telnyx.webrtcapp`; obtain the Firebase configuration registered for that bundle ID before claiming Firebase parity. Neither identifier was changed to hide the mismatch.

Before closing VSDK-1057, attach normal build logs and complete these device checks against SDK 4.2.4:

- [x] Clean SPM resolution and compile-only simulator Debug/UI-test builds, without installing pods (missing Firebase resource explicitly excluded).
- [x] Normal simulator build with the supplied real Firebase plist and no resource exclusion; app launch smoke checked (Firebase bundle-ID mismatch remains unresolved).
- [ ] Device build/run and UI test build from `TelnyxRTC.xcodeproj`.
- [ ] Credential/token login; outgoing and incoming calls; bidirectional audio.
- [ ] Foreground/background/terminated-app VoIP push and CallKit answer/end actions.
- [ ] Call reports upload and expected report data.
- [ ] Firebase initialization and Reachability behavior remain functional.
- [ ] Record transitive package pins and customer migration findings in the ticket.
