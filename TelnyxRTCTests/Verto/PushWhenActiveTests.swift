//
//  PushWhenActiveTests.swift
//  TelnyxRTCTests
//
//  Tests for the `pushWhenActive` configuration flag and the iOS SDK's
//  internal handling of the `answered_device_token` field on
//  `telnyx_rtc.answer` for push-when-active multi-device flows. Covers both
//  the SIP-user/password and token-based `TxConfig` inits and verifies that
//  backwards-compatible behaviour is preserved when the flag is left at its
//  default of `false`.
//

import XCTest
@testable import TelnyxRTC

final class PushWhenActiveTests: XCTestCase {

    // MARK: - LoginMessage: pushWhenActive flag emission

    /// When the SIP-user/password login is constructed with `pushWhenActive=true`,
    /// the `userVariables` payload must include `push_when_active = "true"` so the
    /// backend knows this device should be considered active for push routing.
    func testLoginMessageUserPasswordIncludesPushWhenActiveFlag() {
        let message = LoginMessage(user: "alice",
                                   password: "secret",
                                   pushDeviceToken: "<voip-token>",
                                   pushNotificationProvider: TxPushConfig.PUSH_NOTIFICATION_PROVIDER,
                                   sessionId: UUID().uuidString,
                                   pushWhenActive: true)

        let userVariables = message.params?["userVariables"] as? [String: Any]
        XCTAssertNotNil(userVariables, "userVariables should be present")
        XCTAssertEqual(userVariables?["push_when_active"] as? String, "true",
                       "push_when_active must be set to \"true\" when pushWhenActive is enabled")
        XCTAssertEqual(userVariables?["pn_late_fanout"] as? String, "true",
                       "pn_late_fanout must be set to \"true\" when pushWhenActive is enabled")
        // Existing fields must still be there.
        XCTAssertEqual(userVariables?["push_device_token"] as? String, "<voip-token>")
    }

    /// When `pushWhenActive` is left at the default (`false`), the
    /// `push_when_active` field must NOT be emitted at all so existing
    /// single-device behaviour is preserved exactly.
    func testLoginMessageUserPasswordOmitsPushWhenActiveByDefault() {
        let message = LoginMessage(user: "alice",
                                   password: "secret",
                                   pushDeviceToken: "<voip-token>",
                                   sessionId: UUID().uuidString)

        let userVariables = message.params?["userVariables"] as? [String: Any]
        XCTAssertNotNil(userVariables)
        XCTAssertNil(userVariables?["push_when_active"],
                     "push_when_active must not be emitted when pushWhenActive is false (default)")
        XCTAssertNil(userVariables?["pn_late_fanout"],
                     "pn_late_fanout must not be emitted when pushWhenActive is false (default)")
    }

    /// The token-based login init must support the same `pushWhenActive` flow.
    func testLoginMessageTokenIncludesPushWhenActiveFlag() {
        let message = LoginMessage(token: "<jwt-token>",
                                   pushDeviceToken: "<voip-token>",
                                   pushNotificationProvider: TxPushConfig.PUSH_NOTIFICATION_PROVIDER,
                                   sessionId: UUID().uuidString,
                                   pushWhenActive: true)

        let userVariables = message.params?["userVariables"] as? [String: Any]
        XCTAssertEqual(userVariables?["push_when_active"] as? String, "true")
        XCTAssertEqual(userVariables?["pn_late_fanout"] as? String, "true")
    }

    /// When the round-trip JSON serialization is applied, the field must still
    /// survive and be decodable. This guards against the wire payload losing
    /// the new field between encode and decode.
    func testLoginMessagePushWhenActiveRoundTripsThroughJSON() throws {
        let original = LoginMessage(token: "<jwt-token>",
                                    pushDeviceToken: "<voip-token>",
                                    sessionId: UUID().uuidString,
                                    pushWhenActive: true)

        let encoded = try XCTUnwrap(original.encode(),
                                    "LoginMessage encode must produce JSON")
        let decoded = Message().decode(message: encoded)
        let decodedUserVariables = decoded?.params?["userVariables"] as? [String: Any]
        XCTAssertEqual(decodedUserVariables?["push_when_active"] as? String, "true",
                       "push_when_active must survive encode -> JSON -> decode round trip")
        XCTAssertEqual(decodedUserVariables?["pn_late_fanout"] as? String, "true",
                       "pn_late_fanout must survive encode -> JSON -> decode round trip")
    }

    // MARK: - AnswerMessage: answered_device_token emission

    /// When both `pushWhenActive=true` AND a non-empty `pushDeviceToken` are
    /// supplied, the `telnyx_rtc.answer` payload must include the
    /// `answered_device_token` field at the top level of `params`.
    func testAnswerMessageIncludesAnsweredDeviceTokenWhenEnabled() {
        let callInfo = TxCallInfo(callId: UUID())
        let callOptions = TxCallOptions(destinationNumber: "+15551234567")
        let sdp = "v=0\r\no=- 123456 2 IN IP4 127.0.0.1\r\n"

        let message = AnswerMessage(sessionId: "session-1",
                                    sdp: sdp,
                                    callInfo: callInfo,
                                    callOptions: callOptions,
                                    trickle: false,
                                    pushWhenActive: true,
                                    pushDeviceToken: "<voip-token>")

        let token = message.params?["answered_device_token"] as? String
        XCTAssertEqual(token, "<voip-token>",
                       "answered_device_token must be set on params when pushWhenActive is enabled")
    }

    /// Backwards-compatible default: when `pushWhenActive=false` (the default)
    /// the `answered_device_token` field must NOT be added to the payload.
    func testAnswerMessageOmitsAnsweredDeviceTokenByDefault() {
        let callInfo = TxCallInfo(callId: UUID())
        let callOptions = TxCallOptions(destinationNumber: "+15551234567")
        let sdp = "v=0\r\no=- 123456 2 IN IP4 127.0.0.1\r\n"

        let message = AnswerMessage(sessionId: "session-1",
                                    sdp: sdp,
                                    callInfo: callInfo,
                                    callOptions: callOptions)

        XCTAssertNil(message.params?["answered_device_token"],
                     "answered_device_token must not be set when pushWhenActive is false (default)")
    }

    /// If the app opted in but no push token is configured (e.g. call answered
    /// from a session that was started before the VoIP token was registered),
    /// the SDK must not emit an empty / null token — the field is simply
    /// absent.
    func testAnswerMessageOmitsAnsweredDeviceTokenWhenTokenMissing() {
        let callInfo = TxCallInfo(callId: UUID())
        let callOptions = TxCallOptions(destinationNumber: "+15551234567")
        let sdp = "v=0\r\no=- 123456 2 IN IP4 127.0.0.1\r\n"

        let message = AnswerMessage(sessionId: "session-1",
                                    sdp: sdp,
                                    callInfo: callInfo,
                                    callOptions: callOptions,
                                    pushWhenActive: true,
                                    pushDeviceToken: nil)

        XCTAssertNil(message.params?["answered_device_token"],
                     "answered_device_token must not be set when pushDeviceToken is nil")
    }

    /// Empty-string tokens (e.g. an app that initialises `TxConfig` with
    /// `pushDeviceToken: ""`) must also be treated as "no token" so the wire
    /// payload does not carry an empty string the backend would have to
    /// defend against.
    func testAnswerMessageOmitsAnsweredDeviceTokenWhenTokenEmpty() {
        let callInfo = TxCallInfo(callId: UUID())
        let callOptions = TxCallOptions(destinationNumber: "+15551234567")
        let sdp = "v=0\r\no=- 123456 2 IN IP4 127.0.0.1\r\n"

        let message = AnswerMessage(sessionId: "session-1",
                                    sdp: sdp,
                                    callInfo: callInfo,
                                    callOptions: callOptions,
                                    pushWhenActive: true,
                                    pushDeviceToken: "")

        XCTAssertNil(message.params?["answered_device_token"],
                     "answered_device_token must not be set when pushDeviceToken is an empty string")
    }

    /// Whitespace-only tokens must also be treated as absent so the wire payload
    /// does not send an unusable device token.
    func testAnswerMessageOmitsAnsweredDeviceTokenWhenTokenWhitespaceOnly() {
        let callInfo = TxCallInfo(callId: UUID())
        let callOptions = TxCallOptions(destinationNumber: "+15551234567")
        let sdp = "v=0\r\no=- 123456 2 IN IP4 127.0.0.1\r\n"

        let message = AnswerMessage(sessionId: "session-1",
                                    sdp: sdp,
                                    callInfo: callInfo,
                                    callOptions: callOptions,
                                    pushWhenActive: true,
                                    pushDeviceToken: "   \n\t")

        XCTAssertNil(message.params?["answered_device_token"],
                     "answered_device_token must not be set when pushDeviceToken is whitespace-only")
    }

    /// Round-trip safety: the field must survive a JSON encode -> decode pass
    /// so the on-the-wire payload can still be parsed by the backend without
    /// losing the new field.
    func testAnswerMessageAnsweredDeviceTokenRoundTripsThroughJSON() throws {
        let callInfo = TxCallInfo(callId: UUID())
        let callOptions = TxCallOptions(destinationNumber: "+15551234567")
        let sdp = "v=0\r\no=- 123456 2 IN IP4 127.0.0.1\r\n"

        let original = AnswerMessage(sessionId: "session-1",
                                     sdp: sdp,
                                     callInfo: callInfo,
                                     callOptions: callOptions,
                                     trickle: false,
                                     pushWhenActive: true,
                                     pushDeviceToken: "<voip-token>")

        let encoded = try XCTUnwrap(original.encode(),
                                    "AnswerMessage encode must produce JSON")
        let decoded = Message().decode(message: encoded)
        XCTAssertEqual(decoded?.params?["answered_device_token"] as? String, "<voip-token>",
                       "answered_device_token must survive encode -> JSON -> decode round trip")
    }

    // MARK: - TxConfig: flag storage and round-trip

    /// The SIP-user/password init must store `pushWhenActive` on the config so
    /// it can be picked up by `TxClient.performLogin` and propagated into
    /// `LoginMessage`.
    func testTxConfigSipUserStoresPushWhenActive() {
        let config = TxConfig(sipUser: "alice",
                              password: "secret",
                              pushDeviceToken: "<voip-token>",
                              pushWhenActive: true)
        XCTAssertTrue(config.pushWhenActive,
                      "pushWhenActive must be stored on the config")
    }

    /// The token-based init must also store the flag.
    func testTxConfigTokenStoresPushWhenActive() {
        let config = TxConfig(token: "<jwt-token>",
                              pushDeviceToken: "<voip-token>",
                              pushWhenActive: true)
        XCTAssertTrue(config.pushWhenActive)
    }

    /// Backwards-compatible default: when the flag is omitted, it must default
    /// to `false`.
    func testTxConfigDefaultsPushWhenActiveToFalse() {
        let sipConfig = TxConfig(sipUser: "alice", password: "secret")
        let tokenConfig = TxConfig(token: "<jwt-token>")
        XCTAssertFalse(sipConfig.pushWhenActive,
                       "pushWhenActive must default to false on the SIP config init")
        XCTAssertFalse(tokenConfig.pushWhenActive,
                       "pushWhenActive must default to false on the token config init")
    }

    // MARK: - TxClient: picked-off delegate call ID remap

    func testPickedOffCallStateUsesSipCallIdForDelegateCallbacks() {
        let socketCallId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let pushCallId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let client = TxClient()
        let delegate = PickedOffCallIdDelegate()
        client.delegate = delegate

        let call = Call(callId: socketCallId,
                        remoteSdp: "v=0\r\n",
                        sessionId: "session-1",
                        socket: Socket(),
                        delegate: client,
                        iceServers: [],
                        enableCallReports: false)
        client.calls[socketCallId] = call

        let reason = CallTerminationReason(cause: "PICKED_OFF",
                                           causeCode: 805,
                                           sipCode: 487,
                                           sipCallId: pushCallId.uuidString)
        call.updateCallState(callState: .DONE(reason: reason))

        XCTAssertEqual(delegate.callStateUpdatedIds, [pushCallId])
        XCTAssertEqual(delegate.remoteCallEndedIds, [pushCallId])
        XCTAssertNil(client.calls[socketCallId])
    }

    func testNonPickedOffDoneStateUsesSocketCallIdForDelegateCallbacks() {
        let socketCallId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let pushCallId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let client = TxClient()
        let delegate = PickedOffCallIdDelegate()
        client.delegate = delegate

        let call = Call(callId: socketCallId,
                        remoteSdp: "v=0\r\n",
                        sessionId: "session-1",
                        socket: Socket(),
                        delegate: client,
                        iceServers: [],
                        enableCallReports: false)
        client.calls[socketCallId] = call

        let reason = CallTerminationReason(cause: "USER_BUSY",
                                           causeCode: 17,
                                           sipCallId: pushCallId.uuidString)
        call.updateCallState(callState: .DONE(reason: reason))

        XCTAssertEqual(delegate.callStateUpdatedIds, [socketCallId])
        XCTAssertEqual(delegate.remoteCallEndedIds, [socketCallId])
        XCTAssertNil(client.calls[socketCallId])
    }
}

private final class PickedOffCallIdDelegate: TxClientDelegate {
    var callStateUpdatedIds: [UUID] = []
    var remoteCallEndedIds: [UUID] = []

    func onSocketConnected() {}
    func onSocketDisconnected() {}
    func onClientReady() {}
    func onSessionUpdated(sessionId: String) {}
    func onIncomingCall(call: Call) {}
    func onPushCall(call: Call) {}
    func onClientError(error: Error) {}
    func onPushDisabled(success: Bool, message: String) {}
    func onRemoteCallEnded(callId: UUID) {}

    func onCallStateUpdated(callState: CallState, callId: UUID) {
        callStateUpdatedIds.append(callId)
    }

    func onRemoteCallEnded(callId: UUID, reason: CallTerminationReason?) {
        remoteCallEndedIds.append(callId)
    }
}
