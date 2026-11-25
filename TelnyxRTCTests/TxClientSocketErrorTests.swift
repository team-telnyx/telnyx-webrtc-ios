//
//  TxClientSocketErrorTests.swift
//  TelnyxRTCTests
//
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import XCTest
import CallKit
import WebRTC
@testable import TelnyxRTC

final class TxClientRoutingIdentityTests: XCTestCase {
    private var client: TxClient!
    private var sockets: [RoutingIdentitySocket] = []

    override func setUp() {
        super.setUp()
        client = TxClient()
        client.makeSocket = { [unowned self] in
            let socket = RoutingIdentitySocket()
            self.sockets.append(socket)
            return socket
        }
    }

    override func tearDown() {
        client.disconnect()
        client = nil
        sockets = []
        super.tearDown()
    }

    private func routingId(_ configuration: TxServerConfiguration) -> String? {
        URLComponents(url: configuration.signalingServer, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "voice_sdk_id" })?.value
    }

    private func loginParams() throws -> [String: Any] {
        client.onSocketConnected()
        let message = try XCTUnwrap(sockets.last?.messages.last { $0["method"] as? String == "login" })
        return try XCTUnwrap(message["params"] as? [String: Any])
    }

    private func authenticate(region: Region = .usCentral) throws {
        try client.connect(txConfig: TxConfig(sipUser: "user", password: "password"),
                           serverConfiguration: TxServerConfiguration(region: region))
        _ = try loginParams()
        client.onMessageReceived(message: """
        {"jsonrpc":"2.0","voice_sdk_id":"server-routing-id","result":{"message":"logged in","sessid":"server-session"}}
        """)
        client.onMessageReceived(message: """
        {"jsonrpc":"2.0","voice_sdk_id":"server-routing-id","result":{"params":{"state":"REGED"},"sessid":"server-session"}}
        """)
    }

    private func push(callId: UUID = UUID(), voiceSdkId: String = "push-routing-id", region: Region = .usWest) throws {
        try client.processVoIPNotification(
            txConfig: TxConfig(sipUser: "user", password: "password"),
            serverConfiguration: TxServerConfiguration(region: region),
            pushMetaData: ["voice_sdk_id": voiceSdkId, "call_id": callId.uuidString])
    }

    func testFreshLoginDoesNotSendGeneratedSessionOrAttach() throws {
        try client.connect(txConfig: TxConfig(sipUser: "user", password: "password"))
        let params = try loginParams()
        XCTAssertNil(params["sessid"])
        XCTAssertNil((params["loginParams"] as? [String: Any])?["attach_call"])
    }

    func testSameRegionReconnectPreservesRoutingAndRealSession() throws {
        try authenticate()
        let reconnect = client.serverConfigurationForConnection(client.serverConfiguration, reconnecting: true)
        XCTAssertEqual(routingId(reconnect), "server-routing-id")
        let params = try loginParams()
        XCTAssertEqual(params["sessid"] as? String, "server-session")
        XCTAssertEqual((params["loginParams"] as? [String: Any])?["attach_call"] as? String, "true")
    }

    func testRegionChangeDropsRoutingAndSessionEvenForReconnect() throws {
        try authenticate()
        let changed = client.serverConfigurationForConnection(TxServerConfiguration(region: .eu), reconnecting: true)
        XCTAssertNil(routingId(changed))
        XCTAssertEqual(changed.signalingServer.host, "eu.rtc.telnyx.com")
        XCTAssertNil(try loginParams()["sessid"])
        let back = client.serverConfigurationForConnection(TxServerConfiguration(region: .usCentral), reconnecting: true)
        XCTAssertNil(routingId(back), "Returning to an old region must not resurrect its discarded ID")
    }

    func testEnvironmentChangeDropsRoutingAndSession() throws {
        try authenticate()
        let changed = client.serverConfigurationForConnection(
            TxServerConfiguration(environment: .development, region: .usCentral), reconnecting: true)
        XCTAssertNil(routingId(changed))
        XCTAssertNil(try loginParams()["sessid"])
    }

    func testOrdinaryFreshLoginDoesNotReusePreviousPushRouting() throws {
        try push()
        _ = try loginParams()
        client.onMessageReceived(message: """
        {"jsonrpc":"2.0","voice_sdk_id":"push-routing-id","result":{"message":"logged in","sessid":"push-session"}}
        """)
        try client.connect(txConfig: TxConfig(sipUser: "user", password: "password"),
                           serverConfiguration: TxServerConfiguration(region: .usWest))
        XCTAssertNil(routingId(client.serverConfiguration))
        XCTAssertNil(client.serverConfiguration.pushMetaData)
        let params = try loginParams()
        XCTAssertEqual(params["from_push"] as? Bool, false)
        XCTAssertNil(params["sessid"])
        XCTAssertNil((params["loginParams"] as? [String: Any])?["attach_call"])
    }

    func testNewPushPreservesItsAuthoritativeRoutingWithoutOldSession() throws {
        try authenticate()
        try push(region: .eu)
        XCTAssertEqual(routingId(client.serverConfiguration), "push-routing-id")
        XCTAssertEqual(client.serverConfiguration.region, .eu)
        let params = try loginParams()
        XCTAssertEqual(params["from_push"] as? Bool, true)
        XCTAssertNil(params["sessid"])
        XCTAssertEqual((params["loginParams"] as? [String: Any])?["attach_call"] as? String, "true")
    }

    func testConsecutivePushesDoNotReusePreviousRoutingMetadata() throws {
        try push(voiceSdkId: "first-push")
        let oldSocket = try XCTUnwrap(sockets.last)
        _ = try loginParams()
        try push(voiceSdkId: "second-push")
        XCTAssertNil(oldSocket.delegate)
        XCTAssertEqual(routingId(client.serverConfiguration), "second-push")
        XCTAssertEqual(client.serverConfiguration.pushMetaData?["voice_sdk_id"] as? String, "second-push")
        XCTAssertEqual(try loginParams()["from_push"] as? Bool, true)
    }

    func testDisconnectClearsPushRoutingAndSession() throws {
        try push()
        _ = try loginParams()
        client.disconnect()
        XCTAssertNil(routingId(client.serverConfiguration))
        XCTAssertNil(client.serverConfiguration.pushMetaData)
        let configuration = client.serverConfigurationForConnection(TxServerConfiguration(region: .usWest), reconnecting: true)
        XCTAssertNil(routingId(configuration))
    }

    func testPushInviteClearsTransientMetadataButKeepsSessionForRecovery() throws {
        let callId = UUID()
        try push(callId: callId)
        _ = try loginParams()
        client.onMessageReceived(message: """
        {"jsonrpc":"2.0","voice_sdk_id":"push-routing-id","result":{"message":"logged in","sessid":"push-session"}}
        """)
        client.onMessageReceived(message: """
        {"jsonrpc":"2.0","voice_sdk_id":"push-routing-id","method":"telnyx_rtc.invite","params":{"callID":"\(callId.uuidString)","sdp":"v=0"}}
        """)
        XCTAssertNil(client.serverConfiguration.pushMetaData)
        XCTAssertNil(routingId(client.serverConfiguration))
        let reconnect = client.serverConfigurationForConnection(client.serverConfiguration, reconnecting: true)
        XCTAssertEqual(routingId(reconnect), "push-routing-id")
        let params = try loginParams()
        XCTAssertEqual(params["sessid"] as? String, "push-session")
        XCTAssertEqual(params["from_push"] as? Bool, false)
    }

    func testPendingPushReconnectUsesServerConfirmedRoutingIdentity() throws {
        try push()
        _ = try loginParams()
        client.onMessageReceived(message: """
        {"jsonrpc":"2.0","voice_sdk_id":"selected-server-id","result":{"message":"logged in","sessid":"push-session"}}
        """)
        let reconnect = client.serverConfigurationForConnection(client.serverConfiguration, reconnecting: true)
        XCTAssertEqual(routingId(reconnect), "selected-server-id")
        XCTAssertEqual(try loginParams()["sessid"] as? String, "push-session")
    }

    func testPushDelegateStartingNewFlowDoesNotLoseNewMetadata() throws {
        let firstCallId = UUID()
        try push(callId: firstCallId)
        _ = try loginParams()
        client.onMessageReceived(message: """
        {"jsonrpc":"2.0","voice_sdk_id":"push-routing-id","result":{"message":"logged in","sessid":"push-session"}}
        """)
        let delegate = RoutingIdentityPushDelegate()
        delegate.receivedPush = { [unowned self] in
            self.client.disconnect()
            do { try self.push(voiceSdkId: "newer-push") } catch { XCTFail("\(error)") }
        }
        client.delegate = delegate
        client.onMessageReceived(message: """
        {"jsonrpc":"2.0","voice_sdk_id":"push-routing-id","method":"telnyx_rtc.invite","params":{"callID":"\(firstCallId.uuidString)","sdp":"v=0"}}
        """)
        XCTAssertEqual(routingId(client.serverConfiguration), "newer-push")
        XCTAssertEqual(client.serverConfiguration.pushMetaData?["voice_sdk_id"] as? String, "newer-push")
        XCTAssertEqual(try loginParams()["from_push"] as? Bool, true)
    }

    func testAutomaticReconnectUsesExistingRoutingAndSession() throws {
        try authenticate()
        let connected = expectation(description: "reconnect socket created")
        client.makeSocket = { [unowned self] in
            let socket = RoutingIdentitySocket()
            self.sockets.append(socket)
            connected.fulfill()
            return socket
        }
        client.onSocketDisconnected(reconnect: true, region: nil)
        wait(for: [connected], timeout: 3)
        XCTAssertEqual(routingId(client.serverConfiguration), "server-routing-id")
        XCTAssertEqual(try loginParams()["sessid"] as? String, "server-session")
    }

    func testRegionalFallbackDropsOldRoutingAndSession() throws {
        try authenticate()
        let connected = expectation(description: "fallback socket created")
        client.makeSocket = { [unowned self] in
            let socket = RoutingIdentitySocket()
            self.sockets.append(socket)
            connected.fulfill()
            return socket
        }
        client.onSocketDisconnected(reconnect: true, region: .auto)
        wait(for: [connected], timeout: 3)
        XCTAssertEqual(client.serverConfiguration.region, .auto)
        XCTAssertEqual(client.serverConfiguration.signalingServer.host, "rtc.telnyx.com")
        XCTAssertNil(routingId(client.serverConfiguration))
        XCTAssertNil(try loginParams()["sessid"])
    }

    func testOldScheduledReconnectCannotReplaceNewPush() throws {
        try authenticate()
        client.onSocketDisconnected(reconnect: true, region: .auto)
        try push(voiceSdkId: "new-push")
        let newSocket = try XCTUnwrap(sockets.last)
        let settled = expectation(description: "old reconnect delay elapsed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { settled.fulfill() }
        wait(for: [settled], timeout: 3)
        XCTAssertTrue(sockets.last === newSocket)
        XCTAssertEqual(routingId(client.serverConfiguration), "new-push")
    }

    func testDelayedDeclineCannotDisconnectNewPush() throws {
        let oldCallId = UUID()
        try push(callId: oldCallId)
        client.endCallFromCallkit(endAction: CXEndCallAction(call: oldCallId))
        client.onSocketConnected()
        try push(voiceSdkId: "next-push")
        let newSocket = try XCTUnwrap(sockets.last)
        let settled = expectation(description: "old decline delay elapsed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { settled.fulfill() }
        wait(for: [settled], timeout: 3)
        XCTAssertTrue(newSocket.isConnected)
        XCTAssertTrue(sockets.last === newSocket)
        XCTAssertEqual(routingId(client.serverConfiguration), "next-push")
        XCTAssertEqual(try loginParams()["from_push"] as? Bool, true)
    }

    func testDeclineDelegateStartingNewPushDoesNotClearOrDisconnectIt() throws {
        let oldCallId = UUID()
        try push(callId: oldCallId)
        let delegate = RoutingIdentityPushDelegate()
        delegate.endedCall = { [unowned self] in
            do { try self.push(voiceSdkId: "next-push") } catch { XCTFail("\(error)") }
        }
        client.delegate = delegate

        client.endCallFromCallkit(endAction: CXEndCallAction(call: oldCallId))

        XCTAssertEqual(delegate.doneCallIds, [oldCallId])
        XCTAssertEqual(routingId(client.serverConfiguration), "next-push")
        let nextSocket = try XCTUnwrap(sockets.last)
        let settled = expectation(description: "old decline delay elapsed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { settled.fulfill() }
        wait(for: [settled], timeout: 3)
        XCTAssertTrue(nextSocket.isConnected)
        XCTAssertEqual(routingId(client.serverConfiguration), "next-push")
        XCTAssertEqual(try loginParams()["from_push"] as? Bool, true)
    }

    func testAttachFailureClearsPushRoutingMetadata() throws {
        let callId = UUID()
        try push(callId: callId)
        let delegate = RoutingIdentityPushDelegate()
        client.delegate = delegate
        _ = try loginParams()
        client.onMessageReceived(message: """
        {"jsonrpc":"2.0","voice_sdk_id":"push-routing-id","result":{"params":{"state":"REGED"}}}
        """)
        let attachId = try XCTUnwrap(client.pendingAttachCallIdForTesting)
        client.onMessageReceived(message: """
        {"jsonrpc":"2.0","id":"\(attachId)","error":{"code":-1,"message":"Call failed"}}
        """)
        XCTAssertNil(client.serverConfiguration.pushMetaData)
        XCTAssertEqual(delegate.remoteEndedCallIds, [callId])
        XCTAssertEqual(delegate.doneCallIds, [callId])
        XCTAssertNil(client.getCall(callId: callId))
        XCTAssertNil(routingId(client.serverConfiguration))
    }

    func testAttachFailureDelegateStartingNewPushDoesNotClearIt() throws {
        let oldCallId = UUID()
        try push(callId: oldCallId)
        _ = try loginParams()
        client.onMessageReceived(message: """
        {"jsonrpc":"2.0","voice_sdk_id":"push-routing-id","result":{"params":{"state":"REGED"}}}
        """)
        let attachId = try XCTUnwrap(client.pendingAttachCallIdForTesting)
        let delegate = RoutingIdentityPushDelegate()
        delegate.remoteEndedCall = { [unowned self] in
            do { try self.push(voiceSdkId: "next-push") } catch { XCTFail("\(error)") }
        }
        client.delegate = delegate

        client.onMessageReceived(message: """
        {"jsonrpc":"2.0","id":"\(attachId)","error":{"code":-1,"message":"Call failed"}}
        """)

        XCTAssertEqual(delegate.remoteEndedCallIds, [oldCallId])
        XCTAssertTrue(delegate.doneCallIds.isEmpty)
        XCTAssertNil(client.getCall(callId: oldCallId))
        XCTAssertEqual(routingId(client.serverConfiguration), "next-push")
        XCTAssertEqual(client.serverConfiguration.pushMetaData?["voice_sdk_id"] as? String, "next-push")
        XCTAssertEqual(try loginParams()["from_push"] as? Bool, true)
    }

    func testInviteTimeoutDelegateStartingNewPushPreservesItsAnswer() throws {
        let callId = UUID()
        let oldAnswer = TrackingAnswerCallAction(call: callId)
        let newAnswer = TrackingAnswerCallAction(call: callId)
        client.inviteTimeoutInterval = 0.01
        try push(callId: callId)
        client.answerFromCallkit(answerAction: oldAnswer)
        let terminated = expectation(description: "old push timed out")
        let delegate = RoutingIdentityPushDelegate()
        delegate.remoteEndedCall = { [unowned self] in
            do { try self.push(callId: callId, voiceSdkId: "next-push") } catch { XCTFail("\(error)") }
            self.client.answerFromCallkit(answerAction: newAnswer)
            terminated.fulfill()
        }
        client.delegate = delegate

        client.onMessageReceived(message: """
        {"jsonrpc":"2.0","result":{"params":{"state":"REGED"}}}
        """)
        wait(for: [terminated], timeout: 1)

        XCTAssertEqual(delegate.remoteEndedCallIds, [callId])
        XCTAssertTrue(delegate.doneCallIds.isEmpty)
        XCTAssertEqual(oldAnswer.failCallCount, 1)
        XCTAssertEqual(newAnswer.failCallCount, 0)
        XCTAssertTrue(client.hasPendingAnswerActionForTesting(callId: callId))
        XCTAssertEqual(routingId(client.serverConfiguration), "next-push")
    }

    func testRemovingEmbeddedRoutingHintPreservesCustomURL() {
        var configuration = TxServerConfiguration()
        configuration.signalingServer = URL(string: "wss://example.test:8443/custom/socket?option=one&voice_sdk_id=stale")!
        let cleared = configuration.replacingVoiceSdkId(nil, clearPushMetadata: true)
        XCTAssertEqual(cleared.signalingServer.absoluteString, "wss://example.test:8443/custom/socket?option=one")
        XCTAssertEqual(routingId(cleared.replacingVoiceSdkId("new-id")), "new-id")
    }
}

private final class RoutingIdentityPushDelegate: PingTestDelegate {
    var receivedPush: (() -> Void)?
    var endedCall: (() -> Void)?
    var remoteEndedCall: (() -> Void)?

    override func onPushCall(call: Call) { receivedPush?() }

    override func onCallStateUpdated(callState: CallState, callId: UUID) {
        super.onCallStateUpdated(callState: callState, callId: callId)
        if case .DONE = callState {
            let callback = endedCall
            endedCall = nil
            callback?()
        }
    }

    override func onRemoteCallEnded(callId: UUID, reason: CallTerminationReason?) {
        super.onRemoteCallEnded(callId: callId, reason: reason)
        let callback = remoteEndedCall
        remoteEndedCall = nil
        callback?()
    }
}

final class RoutingIdentitySocket: Socket {
    var messages: [[String: Any]] = []

    override func connect(signalingServer: URL) {
        self.signalingServer = signalingServer
        isConnected = true
    }

    override func disconnect(reconnect: Bool) {
        isConnected = false
    }

    override func sendMessage(message: String?) {
        guard let message, let data = message.data(using: .utf8),
              let decoded = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        messages.append(decoded)
    }
}

/// Tests verifying that the SDK does not reply to server pings on an
/// unauthenticated socket. Sending pong before login triggers a 401
/// error from the server which corrupts SDK state.
class TxClientPingAuthTests: XCTestCase {

    var txClient: TxClient!
    var mockDelegate: PingTestDelegate!

    override func setUp() {
        super.setUp()
        txClient = TxClient()
        mockDelegate = PingTestDelegate()
        txClient.delegate = mockDelegate
    }

    override func tearDown() {
        txClient.delegate = nil
        txClient = nil
        mockDelegate = nil
        super.tearDown()
    }

    /// When the gateway is not registered (unauthenticated socket),
    /// receiving a PING message should NOT send a pong reply.
    /// This prevents the 401 error that corrupts SDK state during push flow.
    func testPingIgnoredWhenNotAuthenticated() {
        // Gateway state defaults to NOREG (not registered / unauthenticated).
        // Simulate receiving a telnyx_rtc.ping message.
        let pingMessage = "{\"jsonrpc\":\"2.0\",\"method\":\"telnyx_rtc.ping\",\"params\":{}}"
        txClient.onMessageReceived(message: pingMessage)

        // The client should NOT have crashed or entered a bad state.
        // Since we can't directly observe whether a message was sent on the socket
        // (socket is nil in test), we verify the client remains functional.
        XCTAssertFalse(txClient.isConnected())
    }

    /// After push flow setup, the gateway is still NOREG (login hasn't happened).
    /// PING messages should be ignored until the user answers and login completes.
    func testPingIgnoredDuringPushFlowBeforeAuth() throws {
        let txConfig = TxConfig(sipUser: "test_user", password: "test_password")
        let serverConfig = TxServerConfiguration()
        let pushMetaData: [String: Any] = [
            "voice_sdk_id": "test-sdk-id",
            "call_id": UUID().uuidString
        ]

        try txClient.processVoIPNotification(
            txConfig: txConfig,
            serverConfiguration: serverConfig,
            pushMetaData: pushMetaData
        )

        // At this point: socket is connected but unauthenticated (NOREG).
        // A ping arrives — SDK should NOT reply.
        let pingMessage = "{\"jsonrpc\":\"2.0\",\"method\":\"telnyx_rtc.ping\",\"params\":{}}"
        txClient.onMessageReceived(message: pingMessage)

        // Client should still be in a valid state, no 401 triggered.
        // The delegate should NOT have received an error.
        XCTAssertFalse(mockDelegate.onClientErrorCalled,
                       "No error should occur — ping should be silently ignored on unauthenticated socket")
    }

    func testFreshPushVoiceSdkIdTakesPrecedenceOverCachedIdOnConnect() throws {
        txClient.onMessageReceived(message: """
        {"jsonrpc":"2.0","voice_sdk_id":"stale-sdk-id","result":{"params":{"state":"REGED"}}}
        """)

        let txConfig = TxConfig(sipUser: "test_user", password: "test_password")
        let serverConfiguration = TxServerConfiguration(
            pushMetaData: [
                "voice_sdk_id": "fresh-push-sdk-id",
                "call_id": UUID().uuidString
            ]
        )

        try txClient.connect(txConfig: txConfig, serverConfiguration: serverConfiguration)

        XCTAssertEqual(
            txClient.serverConfiguration.pushMetaData?["voice_sdk_id"] as? String,
            "fresh-push-sdk-id"
        )
        let queryItems = URLComponents(
            url: txClient.serverConfiguration.signalingServer,
            resolvingAgainstBaseURL: false
        )?.queryItems
        XCTAssertEqual(
            queryItems?.first(where: { $0.name == "voice_sdk_id" })?.value,
            "fresh-push-sdk-id"
        )
    }

    func testDeclinePushDoneUsesEndActionUUIDWhenCallIdIsNotProvided() throws {
        let callUUID = UUID()
        try startPushFlow(callId: callUUID)

        let endAction = CXEndCallAction(call: callUUID)
        txClient.endCallFromCallkit(endAction: endAction)
        txClient.onSocketConnected()

        XCTAssertEqual(mockDelegate.doneCallIds, [callUUID])
    }

    func testPendingDeclineClearsOnSocketErrorBeforeDeclineLogin() throws {
        let callUUID = UUID()
        try startPushFlow(callId: callUUID)

        let endAction = CXEndCallAction(call: callUUID)
        txClient.endCallFromCallkit(endAction: endAction)
        txClient.onSocketError(error: NSError(domain: "TxClientPingAuthTests", code: 1))
        txClient.onSocketConnected()

        XCTAssertTrue(mockDelegate.doneCallIds.isEmpty)
    }

    func testAnsweredPushInviteTimeoutUsesPushUUIDAndFailsAnswerAction() throws {
        let callUUID = UUID()
        txClient.inviteTimeoutInterval = 0.01
        try startPushFlow(callId: callUUID)

        let answerAction = TrackingAnswerCallAction(call: callUUID)
        txClient.answerFromCallkit(answerAction: answerAction)
        txClient.onMessageReceived(message: gatewayStateMessage(state: "REGED"))

        let timeoutExpectation = expectation(description: "VoIP push INVITE timeout handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            timeoutExpectation.fulfill()
        }
        wait(for: [timeoutExpectation], timeout: 1.0)

        XCTAssertEqual(mockDelegate.remoteEndedCallIds, [callUUID])
        XCTAssertEqual(mockDelegate.doneCallIds, [callUUID])
        XCTAssertEqual(answerAction.fulfillCallCount, 0)
        XCTAssertEqual(answerAction.failCallCount, 1)
    }

    func testPassivePushInviteTimeoutUsesPushUUIDWithoutAnswerAction() throws {
        let callUUID = UUID()
        txClient.inviteTimeoutInterval = 0.01
        try startPushFlow(callId: callUUID)

        txClient.onSocketConnected()
        txClient.onMessageReceived(message: gatewayStateMessage(state: "REGED"))

        let timeoutExpectation = expectation(description: "Passive VoIP push INVITE timeout handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            timeoutExpectation.fulfill()
        }
        wait(for: [timeoutExpectation], timeout: 1.0)

        XCTAssertEqual(mockDelegate.remoteEndedCallIds, [callUUID])
        XCTAssertEqual(mockDelegate.doneCallIds, [callUUID])
    }

    func testMalformedInviteDoesNotCancelPushWatchdog() throws {
        let callUUID = UUID()
        txClient.inviteTimeoutInterval = 0.01
        try startPushFlow(callId: callUUID)
        txClient.onMessageReceived(message: gatewayStateMessage(state: "REGED"))

        txClient.onMessageReceived(message: """
        {"jsonrpc":"2.0","method":"telnyx_rtc.invite","params":{"callID":"\(UUID().uuidString)"}}
        """)
        waitForWatchdog()

        XCTAssertEqual(mockDelegate.remoteEndedCallIds, [callUUID])
        XCTAssertEqual(mockDelegate.doneCallIds, [callUUID])
    }

    func testAttachErrorCancelsPushWatchdogAfterSingleCleanup() throws {
        let callUUID = UUID()
        txClient.inviteTimeoutInterval = 0.01
        try startPushFlow(callId: callUUID)
        txClient.onMessageReceived(message: gatewayStateMessage(state: "REGED"))

        let attachId = try XCTUnwrap(txClient.pendingAttachCallIdForTesting)
        txClient.onMessageReceived(message: """
        {"jsonrpc":"2.0","id":"\(attachId)","error":{"code":-1,"message":"Call failed"}}
        """)
        waitForWatchdog()

        XCTAssertEqual(mockDelegate.remoteEndedCallIds, [callUUID])
        XCTAssertEqual(mockDelegate.doneCallIds, [callUUID])
    }

    func testAttachSuccessCancelsPushWatchdogWithoutTerminalCleanup() throws {
        let pushCallUUID = UUID()
        let signalingCallUUID = UUID()
        txClient.inviteTimeoutInterval = 0.01
        try startPushFlow(callId: pushCallUUID)
        txClient.onMessageReceived(message: gatewayStateMessage(state: "REGED"))

        txClient.onMessageReceived(message: """
        {"jsonrpc":"2.0","method":"telnyx_rtc.attach","params":{"sdp":"v=0\\r\\n","callID":"\(signalingCallUUID.uuidString)"}}
        """)
        waitForWatchdog()

        XCTAssertTrue(mockDelegate.remoteEndedCallIds.isEmpty)
        XCTAssertTrue(mockDelegate.doneCallIds.isEmpty)
    }

    func testAttachConsumesOnlyItsMatchingPendingAnswer() throws {
        let pushCallUUID = UUID()
        let unrelatedCallUUID = UUID()
        try startPushFlow(callId: pushCallUUID)

        let pushAnswerAction = TrackingAnswerCallAction(call: pushCallUUID)
        txClient.answerFromCallkit(answerAction: pushAnswerAction)
        let unrelatedAnswerAction = TrackingAnswerCallAction(call: unrelatedCallUUID)
        txClient.answerFromCallkit(answerAction: unrelatedAnswerAction)

        // ATTACH follows successful login; the client must not invent a pre-login sessid.
        txClient.onMessageReceived(message: """
        {"jsonrpc":"2.0","result":{"message":"logged in","sessid":"push-session"}}
        """)

        txClient.onMessageReceived(message: """
        {"jsonrpc":"2.0","method":"telnyx_rtc.attach","params":{"sdp":"v=0\\r\\n","callID":"\(UUID().uuidString)"}}
        """)

        XCTAssertFalse(txClient.hasPendingAnswerActionForTesting(callId: pushCallUUID))
        XCTAssertTrue(txClient.hasPendingAnswerActionForTesting(callId: unrelatedCallUUID))
        XCTAssertEqual(unrelatedAnswerAction.failCallCount, 0)
        XCTAssertEqual(unrelatedAnswerAction.fulfillCallCount, 0)
    }

    /// A push placeholder that never got an INVITE, answer, or decline is still `currentCallId`
    /// when the next push arrives on a connected socket. The teardown in
    /// `processVoIPNotification` ends it, which resets push state; the new push must keep its own.
    func testPushOnConnectedSocketKeepsStateWhenStalePushPlaceholderEnds() throws {
        let stalePushUUID = UUID()
        try startPushFlow(callId: stalePushUUID)
        let staleSocket = try XCTUnwrap(txClient.calls[stalePushUUID]?.socket)
        staleSocket.isConnected = true

        let newPushUUID = UUID()
        try startPushFlow(callId: newPushUUID)

        XCTAssertEqual(mockDelegate.doneCallIds, [stalePushUUID])
        XCTAssertNil(txClient.calls[stalePushUUID])
        XCTAssertNotNil(txClient.calls[newPushUUID])

        // Declining needs the stored push config to connect and send the decline_push login.
        txClient.endCallFromCallkit(endAction: CXEndCallAction(call: newPushUUID))
        txClient.onSocketConnected()

        XCTAssertEqual(mockDelegate.doneCallIds, [stalePushUUID, newPushUUID])
    }

    /// VSUP-308: CallKit owns the action deadline. The SDK keeps an early
    /// answer scoped to its UUID instead of starting a second timeout.
    func testAnswerWithoutPushWaitsForMatchingCallUUID() {
        let callUUID = UUID()
        txClient.inviteTimeoutInterval = 0.01

        let answerAction = TrackingAnswerCallAction(call: callUUID)
        txClient.answerFromCallkit(answerAction: answerAction)
        waitForWatchdog()

        XCTAssertEqual(answerAction.failCallCount, 0)
        XCTAssertEqual(answerAction.fulfillCallCount, 0)
        XCTAssertTrue(txClient.hasPendingAnswerActionForTesting(callId: callUUID))
        XCTAssertTrue(mockDelegate.remoteEndedCallIds.isEmpty)
        XCTAssertTrue(mockDelegate.doneCallIds.isEmpty)
    }

    func testExpiredAnswerIsPrunedBeforeNextPush() throws {
        let oldCallUUID = UUID()
        let answerAction = TrackingAnswerCallAction(call: oldCallUUID)
        txClient.answerFromCallkit(answerAction: answerAction)
        txClient.prunePendingAnswerActionsForTesting(now: .distantFuture)

        try startPushFlow(callId: UUID())

        XCTAssertFalse(txClient.hasPendingAnswerActionForTesting)
        XCTAssertEqual(answerAction.failCallCount, 1)
    }

    /// Apps can report the call to CallKit and get the answer before calling `processVoIPNotification`.
    func testAnswerBeforeProcessVoIPNotificationIsKeptForThePush() throws {
        let callUUID = UUID()
        txClient.inviteTimeoutInterval = 0.01

        let answerAction = TrackingAnswerCallAction(call: callUUID)
        txClient.answerFromCallkit(answerAction: answerAction)
        try startPushFlow(callId: callUUID)
        waitForWatchdog()

        XCTAssertTrue(txClient.hasPendingAnswerActionForTesting(callId: callUUID))
        XCTAssertEqual(answerAction.failCallCount, 0)
        XCTAssertTrue(mockDelegate.doneCallIds.isEmpty)
    }

    /// An incomplete action for A may represent a legitimate concurrent call.
    /// A later push for B must neither consume nor fail it.
    func testUnrelatedPushDoesNotConsumeOrFailPendingAnswer() throws {
        let firstCallUUID = UUID()
        let newPushUUID = UUID()

        let firstAnswerAction = TrackingAnswerCallAction(call: firstCallUUID)
        txClient.answerFromCallkit(answerAction: firstAnswerAction)
        try startPushFlow(callId: newPushUUID)

        XCTAssertEqual(firstAnswerAction.failCallCount, 0)
        XCTAssertEqual(firstAnswerAction.fulfillCallCount, 0)
        XCTAssertTrue(txClient.hasPendingAnswerActionForTesting(callId: firstCallUUID))
        XCTAssertFalse(txClient.hasPendingAnswerActionForTesting(callId: newPushUUID))
        XCTAssertEqual(txClient.currentCallIdForTesting, newPushUUID)
        XCTAssertTrue(mockDelegate.remoteEndedCallIds.isEmpty)
        XCTAssertTrue(mockDelegate.doneCallIds.isEmpty)
        XCTAssertNotNil(txClient.calls[newPushUUID])
    }

    /// The INVITE watchdog armed for push call A must not terminate the newer push flow B
    /// that arrived before A's timer fired (VSUP-308).
    func testStaleInviteTimerCannotTerminateNextPushFlow() throws {
        let stalePushUUID = UUID()
        let newPushUUID = UUID()
        txClient.inviteTimeoutInterval = 0.01

        // Push flow for A, answered and registered - arms the INVITE watchdog for A.
        try startPushFlow(callId: stalePushUUID)
        txClient.onSocketConnected()
        let staleAnswerAction = TrackingAnswerCallAction(call: stalePushUUID)
        txClient.answerFromCallkit(answerAction: staleAnswerAction)
        txClient.onMessageReceived(message: gatewayStateMessage(state: "REGED"))

        // The next push arrives BEFORE A's watchdog fires. The socket is down, so the
        // connected-socket teardown does not run and A's timer stays armed.
        try startPushFlow(callId: newPushUUID)
        waitForWatchdog()

        // A's pending action remains scoped to A and cannot affect B.
        XCTAssertEqual(staleAnswerAction.failCallCount, 0)
        XCTAssertEqual(staleAnswerAction.fulfillCallCount, 0)
        XCTAssertTrue(txClient.hasPendingAnswerActionForTesting(callId: stalePushUUID))
        // ...and A's delayed watchdog did not terminate the newer push flow.
        XCTAssertTrue(mockDelegate.remoteEndedCallIds.isEmpty)
        XCTAssertTrue(mockDelegate.doneCallIds.isEmpty)
        XCTAssertNotNil(txClient.calls[newPushUUID])
    }

    /// A pending CallKit answer for a different call must not be consumed to
    /// auto-answer this push INVITE. It remains available for its own call.
    func testMismatchedPendingAnswerIsIsolatedFromPushInvite() throws {
        let pushCallUUID = UUID()
        try startPushFlow(callId: pushCallUUID)

        // CallKit answer for an unrelated call arrives after the push was processed.
        let otherCallUUID = UUID()
        let otherAnswerAction = TrackingAnswerCallAction(call: otherCallUUID)
        txClient.answerFromCallkit(answerAction: otherAnswerAction)

        // INVITE for the push flow arrives - signaling callID differs from the push call_id.
        txClient.onMessageReceived(message: """
        {"jsonrpc":"2.0","method":"telnyx_rtc.invite","params":{"sdp":"v=0\\r\\n","callID":"\(UUID().uuidString)","caller_id_name":"","caller_id_number":"","telnyx_session_id":"","telnyx_leg_id":""}}
        """)

        XCTAssertEqual(otherAnswerAction.failCallCount, 0)
        XCTAssertEqual(otherAnswerAction.fulfillCallCount, 0)
        XCTAssertTrue(txClient.hasPendingAnswerActionForTesting(callId: otherCallUUID))
        XCTAssertFalse(txClient.hasPendingAnswerActionForTesting(callId: pushCallUUID))
        // The push call was created and propagated, but not auto-answered.
        XCTAssertNotNil(txClient.calls[pushCallUUID])
    }

    private func waitForWatchdog() {
        let expectation = expectation(description: "Wait beyond INVITE watchdog")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)
    }

    private func startPushFlow(callId: UUID) throws {
        let txConfig = TxConfig(sipUser: "test_user", password: "test_password")
        let serverConfig = TxServerConfiguration()
        let pushMetaData: [String: Any] = [
            "voice_sdk_id": "test-sdk-id",
            "call_id": callId.uuidString
        ]

        try txClient.processVoIPNotification(
            txConfig: txConfig,
            serverConfiguration: serverConfig,
            pushMetaData: pushMetaData
        )
    }

    private func gatewayStateMessage(state: String) -> String {
        """
        {"jsonrpc":"2.0","id":"gateway-state","result":{"params":{"state":"\(state)"}}}
        """
    }
}

// These tests generate local WebRTC offers and call the real answerFromCallkit
// path. No SIP account, signaling connection, or physical CallKit UI is used.
final class TxClientCallWaitingTests: XCTestCase {
    private var client: TxClient!
    private var socket: Socket!

    override func setUp() {
        super.setUp()
        client = TxClient()
        socket = Socket()
    }

    override func tearDown() {
        for call in client.calls.values {
            call.peer?.dispose()
        }
        client.calls.removeAll()
        client = nil
        socket = nil
        super.tearDown()
    }

    func testAnswersSecondCallAfterFirstCallIsHeld() throws {
        let offer = try makeOffer()
        let first = makeCall(offer: offer)
        let firstAction = answerAction(for: first, description: "A answered")
        client.answerFromCallkit(answerAction: firstAction.action)
        wait(for: [firstAction.done], timeout: 10)
        XCTAssertEqual(first.callState, .ACTIVE)

        first.hold()
        // Model the server's successful hold acknowledgment.
        first.updateCallState(callState: .HELD)
        let second = makeCall(offer: offer)
        let secondAction = answerAction(for: second, description: "B answered while A held")
        client.answerFromCallkit(answerAction: secondAction.action)
        wait(for: [secondAction.done], timeout: 10)

        XCTAssertEqual(first.callState, .HELD)
        XCTAssertEqual(second.callState, .ACTIVE)
        XCTAssertEqual(firstAction.action.fulfillCallCount, 1)
        XCTAssertEqual(secondAction.action.fulfillCallCount, 1)
        XCTAssertEqual(firstAction.action.failCallCount, 0)
        XCTAssertEqual(secondAction.action.failCallCount, 0)
        XCTAssertEqual(client.calls.count, 2)
    }

    func testAnswersSecondCallRightAfterHoldIsSentBeforeServerAcknowledgment() throws {
        let offer = try makeOffer()
        let first = makeCall(offer: offer)
        let firstAction = answerAction(for: first, description: "A answered")
        client.answerFromCallkit(answerAction: firstAction.action)
        wait(for: [firstAction.done], timeout: 10)

        // hold() sends the hold request and marks the call HELD locally right away;
        // the SDK has no state for "hold sent, awaiting server acknowledgment".
        // Answer B immediately, before any acknowledgment for A is modeled.
        first.hold()
        XCTAssertEqual(first.callState, .HELD)

        let second = makeCall(offer: offer)
        let secondAction = answerAction(for: second, description: "B answered during hold")
        client.answerFromCallkit(answerAction: secondAction.action)
        wait(for: [secondAction.done], timeout: 10)

        XCTAssertEqual(first.callState, .HELD)
        XCTAssertEqual(firstAction.action.fulfillCallCount, 1)
        XCTAssertEqual(second.callState, .ACTIVE)
        XCTAssertEqual(secondAction.action.fulfillCallCount, 1)
        XCTAssertEqual(secondAction.action.failCallCount, 0)
        XCTAssertEqual(client.calls.count, 2)
    }

    func testOverlappingAnswersCompleteTheirOwnActionsAndTargetTheirUUIDs() throws {
        let offer = try makeOffer()
        let first = makeCall(offer: offer)
        let second = makeCall(offer: offer)
        let a = answerAction(for: first, description: "A action completed")
        let b = answerAction(for: second, description: "B action completed")
        client.answerFromCallkit(answerAction: a.action, customHeaders: ["X-Test": "A"])
        client.answerFromCallkit(answerAction: b.action, customHeaders: ["X-Test": "B"])
        wait(for: [a.done, b.done], timeout: 10)

        XCTAssertEqual(first.answerCustomHeaders?["X-Test"], "A")
        XCTAssertEqual(second.answerCustomHeaders?["X-Test"], "B")
        XCTAssertEqual(a.action.fulfillCallCount, 1)
        XCTAssertEqual(b.action.fulfillCallCount, 1)
        XCTAssertEqual(a.action.failCallCount, 0)
        XCTAssertEqual(b.action.failCallCount, 0)
    }

    private func makeCall(offer: String) -> Call {
        let callId = UUID()
        let call = Call(callId: callId, remoteSdp: offer, sessionId: "test-session",
                        socket: socket, delegate: client, iceServers: [],
                        enableCallReports: false)
        client.calls[callId] = call
        return call
    }

    private func answerAction(for call: Call, description: String)
        -> (action: TrackingAnswerCallAction, done: XCTestExpectation) {
        let done = expectation(description: description)
        let action = TrackingAnswerCallAction(call: call.callInfo!.callId)
        action.onFulfill = { done.fulfill() }
        return (action, done)
    }

    private func makeOffer() throws -> String {
        let factory = RTCPeerConnectionFactory()
        let configuration = RTCConfiguration()
        configuration.sdpSemantics = .unifiedPlan
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let peer = try XCTUnwrap(factory.peerConnection(with: configuration,
                                                        constraints: constraints, delegate: nil))
        defer { peer.close() }
        let source = factory.audioSource(with: constraints)
        let track = factory.audioTrack(with: source, trackId: "test-audio")
        peer.add(track, streamIds: ["test-stream"])
        let ready = expectation(description: "Local WebRTC offer generated")
        var offer: RTCSessionDescription?
        var offerError: Error?
        peer.offer(for: constraints) { sdp, error in
            offer = sdp
            offerError = error
            ready.fulfill()
        }
        wait(for: [ready], timeout: 10)
        XCTAssertNil(offerError)
        return try XCTUnwrap(offer).sdp
    }
}

// MARK: - Test Helpers

private final class TrackingAnswerCallAction: CXAnswerCallAction {
    private(set) var fulfillCallCount = 0
    private(set) var failCallCount = 0
    var onFulfill: (() -> Void)?

    override func fulfill() {
        fulfillCallCount += 1
        super.fulfill()
        onFulfill?()
    }

    override func fail() {
        failCallCount += 1
        super.fail()
    }
}

class PingTestDelegate: TxClientDelegate {
    var onClientErrorCalled = false
    var doneCallIds: [UUID] = []
    var remoteEndedCallIds: [UUID] = []

    func onSocketConnected() {}
    func onSocketDisconnected() {}
    func onClientReady() {}
    func onSessionUpdated(sessionId: String) {}
    func onIncomingCall(call: Call) {}
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        if case .DONE = callState {
            doneCallIds.append(callId)
        }
    }
    func onRemoteCallEnded(callId: UUID) {}
    func onRemoteCallEnded(callId: UUID, reason: CallTerminationReason?) {
        remoteEndedCallIds.append(callId)
    }
    func onPushDisabled(success: Bool, message: String) {}
    func onPushCall(call: Call) {}

    func onClientError(error: Error) {
        onClientErrorCalled = true
    }
}
