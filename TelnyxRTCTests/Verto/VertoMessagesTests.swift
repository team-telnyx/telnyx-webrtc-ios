//
//  VertoMessagesTests.swift
//  TelnyxRTCTests
//
//  Created by Guillermo Battistel on 16/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import XCTest
@testable import TelnyxRTC

class VertoMessagesTests: XCTestCase {

    /**
     Test Login Message with token.
     */
    func testLoginMessageToken() {
        print("VertoMessagesTest :: testLoginMessageToken()")
        let loginToken = "<my_token>"
        let pushDeviceToken = "<push_device_token>"
        let pushNotificationProvider = TxPushConfig.PUSH_NOTIFICATION_PROVIDER

        print("VertoMessagesTest :: Testing LoginMessage token init")
        let loginWithToken: LoginMessage = LoginMessage(token: loginToken,
                                                        pushDeviceToken: pushDeviceToken,
                                                        pushNotificationProvider: pushNotificationProvider, sessionId: UUID().uuidString)
        let loginEncodedToken : String = loginWithToken.params?["login_token"] as! String
        let userVariables = loginWithToken.params?["userVariables"] as? [String: Any]
        let loginEncodedPushToken : String = userVariables?["push_device_token"] as! String
        let loginEncodedPushProvider : String = userVariables?["push_notification_provider"] as! String

        XCTAssertEqual(loginEncodedToken, loginToken)
        XCTAssertEqual(loginEncodedPushToken, pushDeviceToken)
        XCTAssertEqual(loginEncodedPushProvider, pushNotificationProvider)

        let encodedLogin: String = loginWithToken.encode() ?? ""
        let decodeLogin = Message().decode(message: encodedLogin)
        let decodedToken : String  = decodeLogin?.params?["login_token"] as! String

        let userVariablesDecoded = decodeLogin?.params?["userVariables"] as? [String: Any]
        let decodedPushToken : String = userVariablesDecoded?["push_device_token"] as! String
        let decodedPushProvider : String = userVariablesDecoded?["push_notification_provider"] as! String

        XCTAssertEqual(decodedToken, loginToken)
        XCTAssertEqual(decodedPushToken, pushDeviceToken)
        XCTAssertEqual(decodedPushProvider, pushNotificationProvider)

        let decodedMethod = decodeLogin?.method
        XCTAssertEqual(decodedMethod, Method.LOGIN)
        
        // Test User-Agent format
        let userAgent = loginWithToken.params?["User-Agent"] as? String
        XCTAssertNotNil(userAgent, "User-Agent should not be nil")
        XCTAssertTrue(userAgent!.hasPrefix("iOS-"), "User-Agent should start with 'iOS-'")
        XCTAssertEqual(userAgent, Message.USER_AGENT, "User-Agent should match Message.USER_AGENT computed property")
    }

    /**
        Test Login Message with Username and password.
     */
    func testLoginMessageUserAndPassword() {
        print("VertoMessagesTest :: testLoginMessageUserAndPassword()")
        let userName = "<my_username>"
        let password = "<my_password>"
        let pushDeviceToken = "<push_device_token>"
        let pushNotificationProvider = TxPushConfig.PUSH_NOTIFICATION_PROVIDER

        print("VertoMessagesTest :: Testing LoginMessage username and password constructor")
        let loginWithUserAndPassoword: LoginMessage = LoginMessage(user: userName,
                                                                    password: password,
                                                                    pushDeviceToken: pushDeviceToken,
                                                                   pushNotificationProvider: pushNotificationProvider, sessionId: UUID().uuidString)
        let loginUser : String = loginWithUserAndPassoword.params?["login"] as! String
        let loginPassword : String = loginWithUserAndPassoword.params?["passwd"] as! String

        let userVariables = loginWithUserAndPassoword.params?["userVariables"] as? [String: Any]
        let loginEncodedPushToken : String = userVariables?["push_device_token"] as! String
        let loginEncodedPushProvider : String = userVariables?["push_notification_provider"] as! String
        let environment : String = userVariables?["push_notification_environment"] as! String

        XCTAssertEqual(loginUser, userName)
        XCTAssertEqual(loginPassword, password)
        XCTAssertEqual(loginEncodedPushToken, pushDeviceToken)
        XCTAssertEqual(loginEncodedPushProvider, pushNotificationProvider)
        #if DEBUG
        XCTAssertEqual(environment, "debug")
        #else
        XCTAssertEqual(environment, "production")
        #endif

        let encodedLogin: String = loginWithUserAndPassoword.encode() ?? ""
        let decodeLogin = Message().decode(message: encodedLogin)
        let decodedUser : String = decodeLogin?.params?["login"] as! String
        let decodedPassword : String = decodeLogin?.params?["passwd"] as! String

        let userVariablesDecoded = decodeLogin?.params?["userVariables"] as? [String: Any]
        let decodedPushToken : String = userVariablesDecoded?["push_device_token"] as! String
        let decodedPushProvider : String = userVariablesDecoded?["push_notification_provider"] as! String
        let decodedEnvironment : String = userVariablesDecoded?["push_notification_environment"] as! String

        #if DEBUG
        XCTAssertEqual(decodedEnvironment, "debug")
        #else
        XCTAssertEqual(decodedEnvironment, "production")
        #endif

        XCTAssertEqual(decodedUser, userName)
        XCTAssertEqual(decodedPassword, password)
        XCTAssertEqual(decodedPushToken, pushDeviceToken)
        XCTAssertEqual(decodedPushProvider, pushNotificationProvider)

        let decodedMethod = decodeLogin?.method
        XCTAssertEqual(decodedMethod, Method.LOGIN)
        
        // Test User-Agent format
        let userAgent = loginWithUserAndPassoword.params?["User-Agent"] as? String
        XCTAssertNotNil(userAgent, "User-Agent should not be nil")
        XCTAssertTrue(userAgent!.hasPrefix("iOS-"), "User-Agent should start with 'iOS-'")
        XCTAssertEqual(userAgent, Message.USER_AGENT, "User-Agent should match Message.USER_AGENT computed property")
    }

    /**
     Test verto Invite
     */
    func testInviteMessage() {
        print("VertoMessagesTest :: testInviteMessage()")

        let sessionId = "<sessionId>"
        let sdp = "<SDP>"

        // Setup callInfo
        let callId = UUID.init()
        let callerName = "<callerName>"
        let callerNumber = "<callerNumber>"
        let callInfo: TxCallInfo = TxCallInfo(callId: callId,
                                              callerName: callerName,
                                              callerNumber: callerNumber)
        // Setup callOptions
        let destinationNumber = "<destinationNumber>"
        let remoteCallerName = "<remoteCallerName>"
        let remoteCallerNumber = "<remoteCallerNumber>"

        var userVariables = [String: Any]()
        userVariables["dummy_var_1"] = "dummy_var_1_value"
        userVariables["dummy_var_2"] = "dummy_var_2_value"

        //Client state must be base64 encoded
        let CLIENT_STATE_DUMMY_STRING = "Hello my friend"
        let clientState = CLIENT_STATE_DUMMY_STRING.base64Encoded()
        let callOptions: TxCallOptions = TxCallOptions(destinationNumber: destinationNumber,
                                                       remoteCallerName: remoteCallerName,
                                                       remoteCallerNumber: remoteCallerNumber,
                                                       clientState: clientState,
                                                       audio: true,
                                                       video: false,
                                                       attach: false,
                                                       useStereo: false,
                                                       screenShare: false,
                                                       userVariables: userVariables)

        let inviteMessage: InviteMessage = InviteMessage(sessionId: sessionId, sdp: sdp, callInfo: callInfo, callOptions: callOptions)

        //Encode and decode the Invite message
        let encodedInviteMessage: String = inviteMessage.encode() ?? ""
        let decodedInviteMessage = Message().decode(message: encodedInviteMessage)

        XCTAssertEqual(decodedInviteMessage?.params?["sessionId"] as! String , sessionId)
        XCTAssertEqual(decodedInviteMessage?.params?["sdp"] as! String , sdp)

        let dialogParams = decodedInviteMessage?.params?["dialogParams"] as! [String: Any]

        //TODO: Validate this with the JS SDK
        XCTAssertEqual(dialogParams["callID"] as! String , callId.uuidString.lowercased())
        XCTAssertEqual(dialogParams["destination_number"] as! String , destinationNumber)
        XCTAssertEqual(dialogParams["remote_caller_id_name"] as! String , remoteCallerName)
        XCTAssertEqual(dialogParams["caller_id_name"] as! String , callerName)
        XCTAssertEqual(dialogParams["caller_id_number"] as! String , callerNumber)
        XCTAssertEqual(dialogParams["audio"] as! Bool , true)
        XCTAssertEqual(dialogParams["video"] as! Bool , false)
        XCTAssertEqual(dialogParams["attach"] as! Bool , false)
        XCTAssertEqual(dialogParams["useStereo"] as! Bool , false)
        XCTAssertEqual(dialogParams["screenShare"] as! Bool , false)
        XCTAssertEqual(dialogParams["clientState"] as? String , clientState)
        XCTAssertEqual((dialogParams["clientState"] as! String).base64Decoded(), CLIENT_STATE_DUMMY_STRING)

        let vars = dialogParams["userVariables"] as! [String: Any]
        XCTAssertEqual(vars["dummy_var_1"] as! String , "dummy_var_1_value")
        XCTAssertEqual(vars["dummy_var_2"] as! String , "dummy_var_2_value")

        let decodedMethod = decodedInviteMessage?.method
        XCTAssertEqual(decodedMethod, Method.INVITE)
    }

    /**
     Test verto Bye
     */
    func testByeMessage() {
        print("VertoMessagesTest :: testByeMessage()")

        let sessionId = "<sessionId>"
        let callId = UUID.init().uuidString.lowercased()
        let causeCode = CauseCode.USER_BUSY
        let byeMessage = ByeMessage(sessionId: sessionId, callId: callId, causeCode: causeCode)

        //Encode and decode the Bye message
        let encodedMessage: String = byeMessage.encode() ?? ""
        let decodedMessage = Message().decode(message: encodedMessage)

        XCTAssertEqual(decodedMessage?.params?["sessId"] as! String , sessionId)
        XCTAssertEqual(decodedMessage?.params?["causeCode"] as! Int , causeCode.rawValue)

        let dialogParams = decodedMessage?.params?["dialogParams"] as! [String: Any]
        XCTAssertEqual(dialogParams["callID"] as! String , callId)

        let decodedMethod = decodedMessage?.method
        XCTAssertEqual(decodedMethod, Method.BYE)
    }

    /**
     Test verto Answer
     */
    func testAnswerMessage() {
        print("VertoMessagesTest :: testAnswerMessage()")

        let sessionId = "<sessionId>"
        let sdp = "<SDP>"

        // Setup callInfo
        let callId = UUID.init()
        let callerName = "<callerName>"
        let callerNumber = "<callerNumber>"
        let callInfo: TxCallInfo = TxCallInfo(callId: callId,
                                              callerName: callerName,
                                              callerNumber: callerNumber)
        // Setup callOptions
        let destinationNumber = "<destinationNumber>"
        let remoteCallerName = "<remoteCallerName>"
        let remoteCallerNumber = "<remoteCallerNumber>"

        var userVariables = [String: Any]()
        userVariables["dummy_var_1"] = "dummy_var_1_value"
        userVariables["dummy_var_2"] = "dummy_var_2_value"

        let callOptions: TxCallOptions = TxCallOptions(destinationNumber: destinationNumber,
                                                       remoteCallerName: remoteCallerName,
                                                       remoteCallerNumber: remoteCallerNumber,
                                                       audio: true,
                                                       video: false,
                                                       attach: false,
                                                       useStereo: false,
                                                       screenShare: false,
                                                       userVariables: userVariables)

        let answerMessage = AnswerMessage(sessionId: sessionId, sdp: sdp, callInfo: callInfo, callOptions: callOptions)

        //Encode and decode the message
        let encodedMessage: String = answerMessage.encode() ?? ""
        let decodedMessage = Message().decode(message: encodedMessage)

        XCTAssertEqual(decodedMessage?.params?["sessionId"] as! String , sessionId)
        XCTAssertEqual(decodedMessage?.params?["sdp"] as! String , sdp)

        let dialogParams = decodedMessage?.params?["dialogParams"] as! [String: Any]

        //TODO: Validate this with the JS SDK
        XCTAssertEqual(dialogParams["callID"] as! String , callId.uuidString.lowercased())
        XCTAssertEqual(dialogParams["remote_caller_id_name"] as! String , remoteCallerName) //check this
        XCTAssertEqual(dialogParams["caller_id_name"] as! String , callerName) // check this
        XCTAssertEqual(dialogParams["caller_id_number"] as! String , remoteCallerNumber) //check this
        XCTAssertEqual(dialogParams["audio"] as! Bool , true)
        XCTAssertEqual(dialogParams["video"] as! Bool , false)
        XCTAssertEqual(dialogParams["attach"] as! Bool , false)
        XCTAssertEqual(dialogParams["useStereo"] as! Bool , false)
        XCTAssertEqual(dialogParams["screenShare"] as! Bool , false)

        let vars = dialogParams["userVariables"] as! [String: Any]
        XCTAssertEqual(vars["dummy_var_1"] as! String , "dummy_var_1_value")
        XCTAssertEqual(vars["dummy_var_2"] as! String , "dummy_var_2_value")

        let decodedMethod = decodedMessage?.method
        XCTAssertEqual(decodedMethod, Method.ANSWER)
    }

    /**
     Test verto Modify
     */
    func testModifyMessage() {
        print("VertoMessagesTest :: testByeMessage()")

        let sessionId = "<sessionId>"
        let callId = UUID.init().uuidString.lowercased()
        let action = ModifyAction.HOLD
        let modifyMessage = ModifyMessage(sessionId: sessionId, callId: callId, action: action)

        //Encode and decode the Bye message
        let encodedMessage: String = modifyMessage.encode() ?? ""
        let decodedMessage = Message().decode(message: encodedMessage)

        XCTAssertEqual(decodedMessage?.params?["sessionId"] as! String , sessionId)
        XCTAssertEqual(decodedMessage?.params?["action"] as! String , action.rawValue)

        let dialogParams = decodedMessage?.params?["dialogParams"] as! [String: Any]
        XCTAssertEqual(dialogParams["callID"] as! String , callId)

        let decodedMethod = decodedMessage?.method
        XCTAssertEqual(decodedMethod, Method.MODIFY)
    }

    /**
     Test dtmf message
     */
    func testDtmfMessage() {
        print("VertoMessagesTest :: testDtmfMessage()")

        let sessionId = "<sessionId>"
        let callId = UUID.init()
        let dtmf = "1"

        let callInfo = TxCallInfo(callId: callId, callerName: "<caller_name>", callerNumber: "<caller_number>")
        let callOptions = TxCallOptions(destinationNumber: "<destination_number>", audio: true)
        let infoMessage = InfoMessage(sessionId: sessionId, dtmf: dtmf, callInfo: callInfo, callOptions: callOptions)

        //Encode and decode the Bye message
        let encodedMessage: String = infoMessage.encode() ?? ""
        let decodedMessage = Message().decode(message: encodedMessage)

        XCTAssertEqual(decodedMessage?.params?["sessid"] as! String, sessionId)
        XCTAssertEqual(decodedMessage?.params?["dtmf"] as! String, dtmf)

        let dialogParams = decodedMessage?.params?["dialogParams"] as! [String: Any]
        XCTAssertEqual(dialogParams["callID"] as! String , callInfo.callId.uuidString.lowercased())
        XCTAssertEqual(dialogParams["remote_caller_id_number"] as? String , callOptions.remoteCallerNumber)
        XCTAssertEqual(dialogParams["audio"] as? Bool , callOptions.audio)

        let decodedMethod = decodedMessage?.method
        XCTAssertEqual(decodedMethod, Method.INFO)
    }
    
    /**
     Test Anonymous Login Message
     */
    func testAnonymousLoginMessage() {
        print("VertoMessagesTest :: testAnonymousLoginMessage()")
        
        let targetId = "assistant-9be2960c-df97-4cbb-9f1a-28c87d0ab77e"
        let targetType = "ai_assistant"
        let targetVersionId = "version-123"
        let sessionId = UUID().uuidString
        let userVariables = ["custom_var": "custom_value"]
        let reconnection = false
        
        let anonymousLoginMessage = AnonymousLoginMessage(
            targetType: targetType,
            targetId: targetId,
            targetVersionId: targetVersionId,
            sessionId: sessionId,
            userVariables: userVariables,
            reconnection: reconnection
        )
        
        // Test encoding and decoding
        let encodedMessage: String = anonymousLoginMessage.encode() ?? ""
        let decodedMessage = Message().decode(message: encodedMessage)
        
        // Verify parameters
        XCTAssertEqual(decodedMessage?.params?["target_type"] as! String, targetType)
        XCTAssertEqual(decodedMessage?.params?["target_id"] as! String, targetId)
        XCTAssertEqual(decodedMessage?.params?["target_version_id"] as! String, targetVersionId)
        XCTAssertEqual(decodedMessage?.params?["sessid"] as! String, sessionId)
        XCTAssertEqual(decodedMessage?.params?["reconnection"] as! Bool, reconnection)
        
        // Verify User-Agent structure
        let userAgent = decodedMessage?.params?["User-Agent"] as! [String: Any]
        XCTAssertNotNil(userAgent["sdkVersion"])
        XCTAssertNotNil(userAgent["data"])
        
        // Verify user variables
        let decodedUserVariables = decodedMessage?.params?["userVariables"] as! [String: Any]
        XCTAssertEqual(decodedUserVariables["custom_var"] as! String, "custom_value")
        
        // Verify method
        let decodedMethod = decodedMessage?.method
        XCTAssertEqual(decodedMethod, Method.ANONYMOUS_LOGIN)
    }
    
    /**
     Test Anonymous Login Message with minimal parameters
     */
    func testAnonymousLoginMessageMinimal() {
        print("VertoMessagesTest :: testAnonymousLoginMessageMinimal()")
        
        let targetId = "assistant-minimal-test"
        let sessionId = UUID().uuidString
        
        let anonymousLoginMessage = AnonymousLoginMessage(
            targetId: targetId,
            sessionId: sessionId
        )
        
        // Test encoding and decoding
        let encodedMessage: String = anonymousLoginMessage.encode() ?? ""
        let decodedMessage = Message().decode(message: encodedMessage)
        
        // Verify parameters
        XCTAssertEqual(decodedMessage?.params?["target_type"] as! String, "ai_assistant") // default value
        XCTAssertEqual(decodedMessage?.params?["target_id"] as! String, targetId)
        XCTAssertEqual(decodedMessage?.params?["sessid"] as! String, sessionId)
        XCTAssertEqual(decodedMessage?.params?["reconnection"] as! Bool, false) // default value
        XCTAssertNil(decodedMessage?.params?["target_version_id"]) // should not be present
        
        // Verify User-Agent structure
        let userAgent = decodedMessage?.params?["User-Agent"] as! [String: Any]
        XCTAssertNotNil(userAgent["sdkVersion"])
        XCTAssertNotNil(userAgent["data"])
        
        // Verify method
        let decodedMethod = decodedMessage?.method
        XCTAssertEqual(decodedMethod, Method.ANONYMOUS_LOGIN)
    }

    /**
     Test verto Candidate message (Trickle ICE)
     */
    func testCandidateMessage() {
        print("VertoMessagesTest :: testCandidateMessage()")

        let sessionId = "<sessionId>"
        let callId = UUID.init().uuidString.lowercased()
        let candidate = "candidate:1 1 UDP 2130706431 192.168.1.1 54321 typ host"
        let sdpMid = "0"
        let sdpMLineIndex: Int32 = 0

        let candidateMessage = CandidateMessage(
            callId: callId,
            sessionId: sessionId,
            candidate: candidate,
            sdpMid: sdpMid,
            sdpMLineIndex: sdpMLineIndex
        )

        // Encode and decode the Candidate message
        let encodedMessage: String = candidateMessage.encode() ?? ""
        let decodedMessage = Message().decode(message: encodedMessage)


        // Verify candidate parameters
        XCTAssertEqual(decodedMessage?.params?["candidate"] as! String, candidate)
        XCTAssertEqual(decodedMessage?.params?["sdpMid"] as! String, sdpMid)
        XCTAssertEqual(decodedMessage?.params?["sdpMLineIndex"] as! Int32, sdpMLineIndex)

        // Verify dialogParams
        let dialogParams = decodedMessage?.params?["dialogParams"] as! [String: Any]
        XCTAssertEqual(dialogParams["callID"] as! String, callId)

        // Verify method
        let decodedMethod = decodedMessage?.method
        XCTAssertEqual(decodedMethod, Method.CANDIDATE)
    }

    /**
     Test verto End of Candidates message (Trickle ICE)
     */
    func testEndOfCandidatesMessage() {
        print("VertoMessagesTest :: testEndOfCandidatesMessage()")

        let sessionId = "<sessionId>"
        let callId = UUID.init().uuidString.lowercased()

        let endOfCandidatesMessage = EndOfCandidatesMessage(
            callId: callId,
            sessionId: sessionId
        )

        // Encode and decode the End of Candidates message
        let encodedMessage: String = endOfCandidatesMessage.encode() ?? ""
        let decodedMessage = Message().decode(message: encodedMessage)


        // Verify dialogParams
        let dialogParams = decodedMessage?.params?["dialogParams"] as! [String: Any]
        XCTAssertEqual(dialogParams["callID"] as! String, callId)

        // Verify method
        let decodedMethod = decodedMessage?.method
        XCTAssertEqual(decodedMethod, Method.END_OF_CANDIDATES)
    }

    func testUserAgentIncludesMissedCallNotificationTagWhenEnabled() {
        let ua = Message.userAgent(enableMissedCallNotifications: true)
        XCTAssertEqual(ua, "iOS-mpn-\(Message.SDK_VERSION)")
    }

    func testUserAgentDefaultsToStandardFormatWhenMissedCallNotificationsDisabled() {
        let ua = Message.userAgent(enableMissedCallNotifications: false)
        XCTAssertEqual(ua, "iOS-\(Message.SDK_VERSION)")
    }

    func testLoginMessageTokenUsesMpnUserAgentWhenEnabled() {
        let login = LoginMessage(token: "test_token",
                                 sessionId: UUID().uuidString,
                                 enableMissedCallNotifications: true)
        let userAgent = login.params?["User-Agent"] as? String
        XCTAssertEqual(userAgent, "iOS-mpn-\(Message.SDK_VERSION)")
    }

    func testLoginMessageUserPasswordUsesMpnUserAgentWhenEnabled() {
        let login = LoginMessage(user: "test_user",
                                 password: "test_pass",
                                 sessionId: UUID().uuidString,
                                 enableMissedCallNotifications: true)
        let userAgent = login.params?["User-Agent"] as? String
        XCTAssertEqual(userAgent, "iOS-mpn-\(Message.SDK_VERSION)")
    }

    func testLoginMessageTokenUsesStandardUserAgentWhenDisabled() {
        let login = LoginMessage(token: "test_token",
                                 sessionId: UUID().uuidString,
                                 enableMissedCallNotifications: false)
        let userAgent = login.params?["User-Agent"] as? String
        XCTAssertEqual(userAgent, "iOS-\(Message.SDK_VERSION)")
    }

    // MARK: - VSDK-768 mobile-SDK identity contract tests
    //
    // The following tests pin the VSDK-768 / VSDK-764 cross-SDK "Commons Lib
    // Usage Telemetry" contract:
    //
    //   * Every covered signaling message emits `mobile_sdk_name = "webrtc-ios"`
    //     and `mobile_sdk_version = Message.SDK_VERSION` as independent
    //     top-level params, wired centrally in `Message.init(_:method:)`.
    //   * The legacy `User-Agent` payload is byte-for-byte compatible with
    //     the pre-change behavior (`iOS-<version>` or `iOS-mpn-<version>`
    //     for missed-call notifications) for all messages whose UA is a
    //     string, and the structured UA payloads (AnonymousLoginMessage
    //     object, DisablePushMessage push-vars dict) are preserved
    //     unchanged.
    //   * The version-string source-of-truth is `Message.SDK_VERSION`; no
    //     test or message references a hardcoded `"4.2.2"` literal — every
    //     read goes through the constant.

    func testMobileSdkIdentityExposesCanonicalPair() {
        let identity = Message.mobileSdkIdentity()
        XCTAssertEqual(identity[Message.MOBILE_SDK_NAME_KEY], "webrtc-ios",
                       "mobile_sdk_name must be the canonical iOS SDK identifier")
        XCTAssertEqual(identity[Message.MOBILE_SDK_VERSION_KEY], Message.SDK_VERSION,
                       "mobile_sdk_version must resolve to Message.SDK_VERSION")
        XCTAssertFalse(Message.SDK_VERSION.isEmpty,
                       "Message.SDK_VERSION must not be empty")
        XCTAssertEqual(Message.MOBILE_SDK_NAME, "webrtc-ios",
                       "MOBILE_SDK_NAME constant must equal \"ios\"")
    }

    func testUserAgentAndMobileSdkIdentityShareSameVersionSource() {
        // Version-source consistency: USER_AGENT and mobileSdkIdentity()
        // both pull from `Message.SDK_VERSION` so any future version bump
        // propagates atomically.
        let ua = Message.USER_AGENT
        let identity = Message.mobileSdkIdentity()
        XCTAssertTrue(ua.hasSuffix(Message.SDK_VERSION),
                      "USER_AGENT (\(ua)) must end with Message.SDK_VERSION (\(Message.SDK_VERSION))")
        XCTAssertEqual(identity[Message.MOBILE_SDK_VERSION_KEY], Message.SDK_VERSION)
    }

    func testMessageBaseInitAddsMobileSdkIdentityForCoveredMethod() {
        // The base `Message.init(_:method:)` is the single source of truth
        // for the mobile-SDK identity pair. A bare Message constructed via
        // the params init must emit the identity without any subclass
        // involvement — this is the central-wiring contract.
        let message = Message(["sentinel": "value"], method: .LOGIN)
        XCTAssertEqual(message.params?[Message.MOBILE_SDK_NAME_KEY] as? String, "webrtc-ios")
        XCTAssertEqual(message.params?[Message.MOBILE_SDK_VERSION_KEY] as? String, Message.SDK_VERSION)
        // Caller-provided keys must still be preserved alongside identity.
        XCTAssertEqual(message.params?["sentinel"] as? String, "value")
    }

    func testMessageBaseInitDoesNotAddMobileSdkIdentityToUnrelatedMethods() {
        let unrelatedMethods: [TelnyxRTC.Method] = [
            .BYE,
            .CANDIDATE,
            .END_OF_CANDIDATES,
            .MODIFY,
            .RINGING_ACK,
            .GATEWAY_STATE,
            .INFO,
            .AI_CONVERSATION,
        ]

        for method in unrelatedMethods {
            let message = Message(["sentinel": "value"], method: method)
            XCTAssertNil(message.params?[Message.MOBILE_SDK_NAME_KEY],
                         "\(method.rawValue) must not receive mobile_sdk_name")
            XCTAssertNil(message.params?[Message.MOBILE_SDK_VERSION_KEY],
                         "\(method.rawValue) must not receive mobile_sdk_version")
            XCTAssertEqual(message.params?["sentinel"] as? String, "value")
        }
    }

    func testMessageBaseInitDoesNotMutateCallersParamsDict() {
        // Defensive contract: the identity injection in the base init must
        // not mutate the caller's `params` dict. This protects callers who
        // reuse the same dict across multiple Message constructions (e.g.
        // TxClient log/cache paths).
        var callerParams: [String: Any] = ["login_token": "t", "sessid": "s"]
        let callerParamsCopy = callerParams
        _ = Message(callerParams, method: .LOGIN)
        XCTAssertEqual(callerParams as NSDictionary, callerParamsCopy as NSDictionary,
                       "Message.init(_:method:) must not mutate the caller's params dict")
        XCTAssertNil(callerParams[Message.MOBILE_SDK_NAME_KEY],
                     "Caller's params dict must not receive mobile_sdk_name")
        XCTAssertNil(callerParams[Message.MOBILE_SDK_VERSION_KEY],
                     "Caller's params dict must not receive mobile_sdk_version")
    }

    func testLoginMessageCredentialEmitsMobileSdkIdentity() {
        let login = LoginMessage(user: "u", password: "p", sessionId: "s")
        XCTAssertEqual(login.params?[Message.MOBILE_SDK_NAME_KEY] as? String, "webrtc-ios")
        XCTAssertEqual(login.params?[Message.MOBILE_SDK_VERSION_KEY] as? String, Message.SDK_VERSION)
        // Legacy User-Agent is byte-for-byte preserved.
        XCTAssertEqual(login.params?["User-Agent"] as? String,
                       Message.userAgent(enableMissedCallNotifications: false))
    }

    func testLoginMessageTokenEmitsMobileSdkIdentity() {
        let login = LoginMessage(token: "t", sessionId: "s")
        XCTAssertEqual(login.params?[Message.MOBILE_SDK_NAME_KEY] as? String, "webrtc-ios")
        XCTAssertEqual(login.params?[Message.MOBILE_SDK_VERSION_KEY] as? String, Message.SDK_VERSION)
        XCTAssertEqual(login.params?["User-Agent"] as? String,
                       Message.userAgent(enableMissedCallNotifications: false))
    }

    func testLoginMessageMpnUserAgentPreservedAlongsideMobileSdkIdentity() {
        // The `mpn` form of User-Agent (used for missed-call push routing)
        // must remain byte-for-byte compatible. We assert both legacy
        // User-Agent and the new identity pair coexist.
        let login = LoginMessage(user: "u",
                                 password: "p",
                                 sessionId: "s",
                                 enableMissedCallNotifications: true)
        XCTAssertEqual(login.params?["User-Agent"] as? String,
                       Message.userAgent(enableMissedCallNotifications: true))
        XCTAssertEqual(login.params?[Message.MOBILE_SDK_NAME_KEY] as? String, "webrtc-ios")
        XCTAssertEqual(login.params?[Message.MOBILE_SDK_VERSION_KEY] as? String, Message.SDK_VERSION)
    }

    func testInviteMessageEmitsMobileSdkIdentity() {
        let invite = InviteMessage(sessionId: "s",
                                   sdp: "v=0\r\n",
                                   callInfo: TxCallInfo(callId: UUID(),
                                                        callerName: "c",
                                                        callerNumber: "n"),
                                   callOptions: TxCallOptions(destinationNumber: "d", audio: true))
        XCTAssertEqual(invite.params?[Message.MOBILE_SDK_NAME_KEY] as? String, "webrtc-ios")
        XCTAssertEqual(invite.params?[Message.MOBILE_SDK_VERSION_KEY] as? String, Message.SDK_VERSION)
        XCTAssertEqual(invite.params?["User-Agent"] as? String, Message.USER_AGENT)
    }

    func testAnswerMessageEmitsMobileSdkIdentity() {
        let answer = AnswerMessage(sessionId: "s",
                                   sdp: "v=0\r\n",
                                   callInfo: TxCallInfo(callId: UUID(),
                                                        callerName: "c",
                                                        callerNumber: "n"),
                                   callOptions: TxCallOptions(destinationNumber: "d", audio: true))
        XCTAssertEqual(answer.params?[Message.MOBILE_SDK_NAME_KEY] as? String, "webrtc-ios")
        XCTAssertEqual(answer.params?[Message.MOBILE_SDK_VERSION_KEY] as? String, Message.SDK_VERSION)
        XCTAssertEqual(answer.params?["User-Agent"] as? String, Message.USER_AGENT)
    }

    func testReAttachMessageEmitsMobileSdkIdentity() {
        let attach = ReAttachMessage(sessionId: "s",
                                     sdp: "v=0\r\n",
                                     callInfo: TxCallInfo(callId: UUID(),
                                                          callerName: "c",
                                                          callerNumber: "n"),
                                     callOptions: TxCallOptions(destinationNumber: "d", audio: true, attach: true))
        XCTAssertEqual(attach.params?[Message.MOBILE_SDK_NAME_KEY] as? String, "webrtc-ios")
        XCTAssertEqual(attach.params?[Message.MOBILE_SDK_VERSION_KEY] as? String, Message.SDK_VERSION)
        XCTAssertEqual(attach.params?["User-Agent"] as? String, Message.USER_AGENT)
    }

    func testAnonymousLoginMessageEmitsMobileSdkIdentityAndPreservesObjectShapedUserAgent() {
        let anonymous = AnonymousLoginMessage(targetId: "tid", sessionId: "s")
        XCTAssertEqual(anonymous.params?[Message.MOBILE_SDK_NAME_KEY] as? String, "webrtc-ios")
        XCTAssertEqual(anonymous.params?[Message.MOBILE_SDK_VERSION_KEY] as? String, Message.SDK_VERSION)

        // Anonymous login must keep its existing object-shaped User-Agent
        // payload (TS-style). Adding mobile_sdk_* must not perturb it.
        guard let ua = anonymous.params?["User-Agent"] as? [String: Any] else {
            XCTFail("AnonymousLoginMessage User-Agent must remain an object payload")
            return
        }
        XCTAssertNotNil(ua["sdkVersion"])
        XCTAssertEqual(ua["data"] as? String, Message.USER_AGENT)
    }

    func testDisablePushMessageEmitsMobileSdkIdentity() {
        let disable = DisablePushMessage(user: "u")
        XCTAssertEqual(disable.params?[Message.MOBILE_SDK_NAME_KEY] as? String, "webrtc-ios")
        XCTAssertEqual(disable.params?[Message.MOBILE_SDK_VERSION_KEY] as? String, Message.SDK_VERSION)
        // The DisablePush `User-Agent` field is the push-variable dict
        // (backend convention quirk). Adding mobile_sdk_* must not
        // overwrite or restructure it.
        XCTAssertNotNil(disable.params?["User-Agent"] as? [String: Any])
    }

    func testDisablePushMessageTokenLoginEmitsMobileSdkIdentity() {
        let disable = DisablePushMessage(loginToken: "t")
        XCTAssertEqual(disable.params?[Message.MOBILE_SDK_NAME_KEY] as? String, "webrtc-ios")
        XCTAssertEqual(disable.params?[Message.MOBILE_SDK_VERSION_KEY] as? String, Message.SDK_VERSION)
    }

    func testAttachCallMessageEmitsMobileSdkIdentity() {
        let attach = AttachCallMessage()
        XCTAssertEqual(attach.params?[Message.MOBILE_SDK_NAME_KEY] as? String, "webrtc-ios")
        XCTAssertEqual(attach.params?[Message.MOBILE_SDK_VERSION_KEY] as? String, Message.SDK_VERSION)
    }

    func testCoveredMessagesEncodeMobileSdkIdentityOnWire() {
        // End-to-end: encode() round-trip must surface the new fields.
        // This catches any case where the params dict is short-circuited
        // before reaching JSONSerialization.
        let login = LoginMessage(token: "t", sessionId: "s")
        let encoded = login.encode() ?? ""
        let decoded = Message().decode(message: encoded)
        XCTAssertEqual(decoded?.params?[Message.MOBILE_SDK_NAME_KEY] as? String, "webrtc-ios")
        XCTAssertEqual(decoded?.params?[Message.MOBILE_SDK_VERSION_KEY] as? String, Message.SDK_VERSION)
    }
}
