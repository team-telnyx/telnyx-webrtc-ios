//
//  VertoMessagesTests.swift
//  WebRTCSDKTests
//
//  Created by Guillermo Battistel on 16/03/2021.
//

import XCTest
@testable import WebRTCSDK

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
        let callOptions: TxCallOptions = TxCallOptions(destinationNumber: destinationNumber,
                                                       remoteCallerName: remoteCallerName,
                                                       remoteCallerNumber: remoteCallerNumber)

        let inviteMessage: InviteMessage = InviteMessage(sessionId: sessionId, sdp: sdp, callInfo: callInfo, callOptions: callOptions)

        //Encode and decode the Invite message
        let encodedInviteMessage: String = inviteMessage.encode() ?? ""
        let decodedInviteMessage = Message().decode(message: encodedInviteMessage)

        XCTAssertEqual(decodedInviteMessage?.params?["sessionId"] as! String , sessionId)
        XCTAssertEqual(decodedInviteMessage?.params?["sdp"] as! String , sdp)

        let dialogParams = decodedInviteMessage?.params?["dialogParams"] as! [String: Any]

        XCTAssertEqual(dialogParams["callID"] as! String , callId.uuidString.lowercased())
        XCTAssertEqual(dialogParams["destination_number"] as! String , destinationNumber)
        XCTAssertEqual(dialogParams["remote_caller_id_name"] as! String , remoteCallerName)
        XCTAssertEqual(dialogParams["caller_id_name"] as! String , callerName)
        XCTAssertEqual(dialogParams["caller_id_number"] as! String , callerNumber)
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
    }

}
