//
//  VertoMessagesTests.swift
//  WebRTCSDKTests
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

        print("VertoMessagesTest :: Testing LoginMessage token init")
        let loginWithToken: LoginMessage = LoginMessage(token: loginToken)
        let loginEncodedToken : String = loginWithToken.params?["login_token"] as! String
        XCTAssertEqual(loginEncodedToken, loginToken)

        let encodedLogin: String = loginWithToken.encode() ?? ""
        let decodeLogin = Message().decode(message: encodedLogin)
        let decodedToken : String  = decodeLogin?.params?["login_token"] as! String
        XCTAssertEqual(decodedToken, loginToken)

        let decodedMethod = decodeLogin?.method
        XCTAssertEqual(decodedMethod, Method.LOGIN)
    }

    /**
        Test Login Message with Username and password.
     */
    func testLoginMessageUserAndPassword() {
        print("VertoMessagesTest :: testLoginMessageUserAndPassword()")
        let userName = "<my_username>"
        let password = "<my_password>"

        print("VertoMessagesTest :: Testing LoginMessage username and password constructor")
        let loginWidthUserAndPassoword: LoginMessage = LoginMessage(user: userName, password: password)
        let loginUser : String = loginWidthUserAndPassoword.params?["login"] as! String
        let loginPassword : String = loginWidthUserAndPassoword.params?["passwd"] as! String
        XCTAssertEqual(loginUser, userName)
        XCTAssertEqual(loginPassword, password)

        let encodedLogin: String = loginWidthUserAndPassoword.encode() ?? ""
        let decodeLogin = Message().decode(message: encodedLogin)
        let decodedUser : String = decodeLogin?.params?["login"] as! String
        let decodedPassword : String = decodeLogin?.params?["passwd"] as! String
        XCTAssertEqual(decodedUser, userName)
        XCTAssertEqual(decodedPassword, password)

        let decodedMethod = decodeLogin?.method
        XCTAssertEqual(decodedMethod, Method.LOGIN)
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
}
