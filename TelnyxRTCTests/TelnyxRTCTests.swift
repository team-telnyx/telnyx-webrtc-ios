//
//  TelnyxRTCTests.swift
//  TelnyxRTCTests
//
//  Created by Guillermo Battistel on 01/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import XCTest
@testable import TelnyxRTC

class TelnyxRTCTests: XCTestCase {
    private weak var expectation: XCTestExpectation!
    private var telnyxClient: TxClient?
    private var serverError: Error?

    override func setUpWithError() throws {
        print("TelnyxRTCTests:: setUpWithError")
        //Setup the SDK
        self.telnyxClient = TxClient()
        self.telnyxClient?.delegate = self
        self.serverError = nil
    }

    override func tearDownWithError() throws {
        print("TelnyxRTCTests:: tearDownWithError")
        self.telnyxClient?.delegate = nil
        self.telnyxClient?.disconnect()
        self.telnyxClient = nil
        self.serverError = nil
        self.expectation = nil
    }
}

// MARK: - HELPER FUNCTIONS
extension TelnyxRTCTests {
    func connectAndReturnError(txConfig: TxConfig) -> Error? {
        //We are expecting an error
        var error: Error? = nil
        do {
            try self.telnyxClient?.connect(txConfig: txConfig)
        } catch let err {
            print("TelnyxRTCTests:: connect Error \(err)")
            error = err
        }
        return error
    }
}// TelnyxRTCTests helper functions

// MARK: - LOGIN RELATED TESTS
extension TelnyxRTCTests {
    /**
     Test login error when credentials are empty
     */
    func testLoginEmptyCredentials() {
        let sipUser = ""
        let sipPassword = ""
        let txConfig = TxConfig(sipUser: sipUser,
                                password: sipPassword)
        //We are expecting an error
        let error: Error? = self.connectAndReturnError(txConfig: txConfig)
        XCTAssertEqual(error?.localizedDescription,
                       TxError.clientConfigurationFailed(reason: .userNameAndPasswordAreRequired).localizedDescription)
    }

    /**
     Test login error when user is empty
     */
    func testLoginEmptyUser() {
        let sipUser = ""
        let sipPassword = "<password>"
        let txConfig = TxConfig(sipUser: sipUser,
                                password: sipPassword)
        //We are expecting an error
        let error: Error? = self.connectAndReturnError(txConfig: txConfig)
        XCTAssertEqual(error?.localizedDescription,
                       TxError.clientConfigurationFailed(reason: .userNameIsRequired).localizedDescription)
    }

    /**
     Test login error when password is empty
     */
    func testLoginEmptyPassword() {
        let sipUser = "<userName>"
        let sipPassword = ""
        let txConfig = TxConfig(sipUser: sipUser,
                                password: sipPassword)
        //We are expecting an error
        let error: Error? = self.connectAndReturnError(txConfig: txConfig)
        XCTAssertEqual(error?.localizedDescription,
                       TxError.clientConfigurationFailed(reason: .passwordIsRequired).localizedDescription)
    }

    /**
     Test login error when token is empty
     */
    func testLoginEmptyToken() {
        let token = ""
        let txConfig = TxConfig(token: token)
        //We are expecting an error
        let error: Error? = self.connectAndReturnError(txConfig: txConfig)
        XCTAssertEqual(error?.localizedDescription,
                       TxError.clientConfigurationFailed(reason: .tokenIsRequired).localizedDescription)
    }

    /**
     Test login error when using wrong sip user and password.
     - Connects to wss
     - Sends an login message using user and password.
     - Waits for server login error
     */
    func testLoginErrorInvalidCredentials() {
        //This needs to be solved from the Server side
        //Currently this test case will fail due that the server.
        //is returning a success message:
        //{"jsonrpc":"2.0","id":"3bdc03f2-03a3-44b0-aea3-326fcca9d066","result":{"message":"logged in","sessid":"9af493a1-2f9f-4f73-bffc-db2bc25f66f8"}}
        expectation = expectation(description: "loginTest")
        let sipUser = "<userName>"
        let sipPassword = "<password>"
        let txConfig = TxConfig(sipUser: sipUser,
                                password: sipPassword)

        let error: Error? = self.connectAndReturnError(txConfig: txConfig)
        XCTAssertNil(error)
        waitForExpectations(timeout: 10)
        let sessionId = self.telnyxClient?.getSessionId() ?? ""
        XCTAssertFalse(sessionId.isEmpty) // We should get a session ID
        //TODO: CHECK ERROR HERE. We should receive an error from the server in the future
    }

    /**
     Test login error when using wrong sip user and password.
     - Connects to wss
     - Sends an login message using an invalid token
     - Waits for server login error
     */
    func testLoginErrorInvalidToken() {
        expectation = expectation(description: "loginTest")
        let token = "<token>"
        let txConfig = TxConfig(token: token)
        let error: Error? = self.connectAndReturnError(txConfig: txConfig)
        XCTAssertNil(error)
        waitForExpectations(timeout: 10)
        XCTAssertNotNil(serverError)
        //Check error returned by the server
        XCTAssertEqual(serverError?.localizedDescription,
                       TxError.serverError(reason:
                                            .signalingServerError(message: "Authentication Required",
                                                                  code: "-32000")).localizedDescription)
    }

    /**
     Test login with valid credentials
     - Connects to wss
     - Sends an login message using valid credentials
     - Waits for sessionId
     */
    func testLoginValidCredentials() {
        //TODO: Replace sipUser and sipPassword with valid credentials.
        //TODO: Implement custom Environment Variables.
        //TODO: Currently this test is not failing with invalid credentials. The server is returning a sessionId.
        expectation = expectation(description: "loginTest")

        let txConfig = TxConfig(sipUser: TestConstants.sipUser,
                                password: TestConstants.sipPassword)

        let error: Error? = self.connectAndReturnError(txConfig: txConfig)
        XCTAssertNil(error) // We shouldn't get any error here
        waitForExpectations(timeout: 10)
        let sessionId = self.telnyxClient?.getSessionId() ?? ""
        XCTAssertFalse(sessionId.isEmpty) //We should have a session id after login in
    }

    /**
     Test login with valid token
     - Connects to wss
     - Sends an login message using a valid token
     - Waits for sessionId
     */
    func testLoginValidToken() {
        //TODO: We should request token through the SDK.
        //TODO: Replace with a valid token
        expectation = expectation(description: "loginTest")
        let token = TestConstants.token
        let txConfig = TxConfig(token: token)
        let error: Error? = self.connectAndReturnError(txConfig: txConfig)
        XCTAssertNil(error)
        waitForExpectations(timeout: 10)
        let sessionId = self.telnyxClient?.getSessionId() ?? ""
        XCTAssertFalse(sessionId.isEmpty) //We should have a session id after login in
    }
}// End TelnyxRTCTests LOGIN TESTS

// MARK: - TxClientDelegate
extension TelnyxRTCTests : TxClientDelegate {
    func onPushCall(call: Call) {
        print("TelnyxRTCTests :: TxClientDelegate onPushCall()")
    }

    func onSocketConnected() {
        print("TelnyxRTCTests :: TxClientDelegate onSocketConnected()")
    }

    func onSocketDisconnected() {
        print("TelnyxRTCTests :: TxClientDelegate onSocketDisconnected()")
    }

    func onClientError(error: Error) {
        print("TelnyxRTCTests :: TxClientDelegate onClientError()")
        self.serverError = error
        self.expectation.fulfill()
    }

    func onClientReady() {
        print("TelnyxRTCTests :: TxClientDelegate onClientReady()")
    }

    func onSessionUpdated(sessionId: String) {
        print("TelnyxRTCTests :: TxClientDelegate onSessionUpdated()")
        self.expectation.fulfill()
    }

    func onCallStateUpdated(callState: CallState, callId: UUID) {
        print("TelnyxRTCTests :: TxClientDelegate onCallStateUpdated()")
    }

    func onIncomingCall(call: Call) {
        print("TelnyxRTCTests :: TxClientDelegate onIncomingCall()")
    }

    func onRemoteCallEnded(callId: UUID) {
        print("TelnyxRTCTests :: TxClientDelegate onRemoteCallEnded()")
    }
}
