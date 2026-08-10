//
//  TxClientRouteObserverTests.swift
//  TelnyxRTCTests
//
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//

import XCTest
import AVFoundation
@testable import TelnyxRTC

/// Regression tests for IOS-C26 / VSDK-337.
///
/// `TxClient.disconnect()` used to call
/// `NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, ...)`
/// without re-registering the observer on subsequent `connect()` calls. After a single
/// disconnect/reconnect cycle, audio route tracking (speaker state, Bluetooth headset
/// toggles, etc.) silently stopped working because the observer was gone.
///
/// The fix removes the `removeObserver` call from `disconnect()`; observer cleanup is
/// exclusively handled in `deinit`. These tests pin the new behavior so the regression
/// cannot reappear unnoticed.
final class TxClientRouteObserverTests: XCTestCase {

    private var txClient: TxClient!

    override func setUp() {
        super.setUp()
        txClient = TxClient()
    }

    override func tearDown() {
        txClient.delegate = nil
        // `NetworkMonitor.shared` can retain a client beyond the test method. Remove
        // this fixture's observer explicitly so another test client cannot satisfy a
        // later notification expectation.
        NotificationCenter.default.removeObserver(
            txClient as Any,
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        txClient = nil
        super.tearDown()
    }

    /// Calling `disconnect()` repeatedly must be safe — the previous behavior
    /// double-removed observers from NotificationCenter, which is harmless but wasted
    /// work; the new behavior should also tolerate repeat calls without crashing or
    /// leaking observers.
    func testDisconnectIsIdempotent() {
        txClient.disconnect()
        XCTAssertNoThrow(txClient.disconnect(),
                         "Calling disconnect() twice must not throw (VSDK-337 regression)")
    }

    /// After `disconnect()`, a route change must still be observed and forwarded as an
    /// `audioRouteChanged` notification. This tests the registration itself rather than
    /// the private selector implementation.
    func testPostingRouteChangeNotificationAfterDisconnectIsObserved() throws {
        guard AVAudioSession.sharedInstance().currentRoute.outputs.first != nil else {
            throw XCTSkip("The current test audio route has no output port")
        }

        let expectation = expectation(description: "route change remains observed after disconnect")
        let observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name(InternalConfig.NotificationNames.audioRouteChanged),
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        txClient.disconnect()

        NotificationCenter.default.post(
            name: AVAudioSession.routeChangeNotification,
            object: nil,
            userInfo: [
                AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.override.rawValue
            ]
        )

        wait(for: [expectation], timeout: 1.0)
    }
}
