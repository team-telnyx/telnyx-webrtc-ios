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
}
