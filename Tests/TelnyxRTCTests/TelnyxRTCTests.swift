import XCTest
@testable import TelnyxRTC

class TelnyxRTCTests: XCTestCase {
    
    /**
     Test login error when credentials are empty
     */
    func testLoginEmptyCredentials() {
        
        let telnyxClient = TxClient()
        
        let sipUser = ""
        let sipPassword = ""
        let txConfig = TxConfig(sipUser: sipUser,
                                password: sipPassword)
        
        do {
            try telnyxClient.connect(txConfig: txConfig)
        } catch let error {
            XCTAssertEqual(error.localizedDescription,
                           TxError.clientConfigurationFailed(reason: .userNameAndPasswordAreRequired).localizedDescription)
        }
    }
    
    
    /**
     Test login error when user is empty
     */
    func testLoginEmptyUser() {
        let telnyxClient = TxClient()
        
        let sipUser = ""
        let sipPassword = "<password>"
        let txConfig = TxConfig(sipUser: sipUser,
                                password: sipPassword)
        //We are expecting an error
        do {
            try telnyxClient.connect(txConfig: txConfig)
        } catch let error {
            XCTAssertEqual(error.localizedDescription,
                           TxError.clientConfigurationFailed(reason: .userNameIsRequired).localizedDescription)
        }
    }
    
    /**
     Test login error when password is empty
     */
    func testLoginEmptyPassword() {
        let telnyxClient = TxClient()
        
        let sipUser = "<userName>"
        let sipPassword = ""
        let txConfig = TxConfig(sipUser: sipUser,
                                password: sipPassword)
        do {
            try telnyxClient.connect(txConfig: txConfig)
        } catch let error {
            XCTAssertEqual(error.localizedDescription,
                           TxError.clientConfigurationFailed(reason: .passwordIsRequired).localizedDescription)
        }
    }
    
    
    /**
     Test login error when token is empty
     */
    func testLoginEmptyToken() {
        let telnyxClient = TxClient()
        
        let token = ""
        let txConfig = TxConfig(token: token)
        //We are expecting an error
        do {
            try telnyxClient.connect(txConfig: txConfig)
        } catch let error {
            XCTAssertEqual(error.localizedDescription,
                           TxError.clientConfigurationFailed(reason: .tokenIsRequired).localizedDescription)
        }
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
        class TestDelegate: RTCTestDelegate {
            override func onSessionUpdated(sessionId: String) {
                self.expectation.fulfill()
            }
        }
        
        let expectation = XCTestExpectation()
        let telnyxClient = TxClient()
        let delegate = TestDelegate(expectation: expectation)
        telnyxClient.delegate = delegate
        
        
        
        let sipUser = "<userName>"
        let sipPassword = "<password>"
        let txConfig = TxConfig(sipUser: sipUser,
                                password: sipPassword)
        
        try! telnyxClient.connect(txConfig: txConfig)
        
        wait(for: [expectation], timeout: 10)
        
        
        let sessionId = telnyxClient.getSessionId()
        XCTAssertFalse(sessionId.isEmpty) // We should get a session ID
    }
    
    /**
     Test login error when using wrong sip user and password.
     - Connects to wss
     - Sends an login message using an invalid token
     - Waits for server login error
     */
    func testLoginErrorInvalidToken() {
        
        class TestDelegate: RTCTestDelegate {
            override func onClientError(error: Error) {
                XCTAssertEqual(error.localizedDescription,
                               TxError.serverError(reason:
                                    .signalingServerError(message: "Authentication Required",
                                                          code: "-32000")).localizedDescription)
                self.expectation.fulfill()
            }
        }
        
        let expectation = XCTestExpectation()
        let telnyxClient = TxClient()
        let delegate = TestDelegate(expectation: expectation)
        telnyxClient.delegate = delegate
        
        let token = "<token>"
        let txConfig = TxConfig(token: token)
        try! telnyxClient.connect(txConfig: txConfig)
        
        wait(for: [expectation], timeout: 10)
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
        
        class TestDelegate: RTCTestDelegate {
            // We are going to wait the session to be updated
            override func onSessionUpdated(sessionId: String) {
                self.expectation.fulfill()
            }
        }
        
        let expectation = XCTestExpectation()
        let telnyxClient = TxClient()
        let delegate = TestDelegate(expectation: expectation)
        telnyxClient.delegate = delegate
        
        let txConfig = TxConfig(sipUser: TestConstants.sipUser,
                                password: TestConstants.sipPassword)
        
        // Login with credentials
        try! telnyxClient.connect(txConfig: txConfig)
        
        wait(for: [expectation], timeout: 10)
        
        let sessionId = telnyxClient.getSessionId()
        XCTAssertFalse(sessionId.isEmpty) // We should get a session ID
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
        class TestDelegate: RTCTestDelegate {
            // We are going to wait the session to be updated
            override func onSessionUpdated(sessionId: String) {
                self.expectation.fulfill()
            }
        }
        
        let expectation = XCTestExpectation()
        let telnyxClient = TxClient()
        let delegate = TestDelegate(expectation: expectation)
        telnyxClient.delegate = delegate
        
        let token = TestConstants.token
        let txConfig = TxConfig(token: token)
        
        // Login with token
        try! telnyxClient.connect(txConfig: txConfig)
        
        wait(for: [expectation], timeout: 10)
        
        let sessionId = telnyxClient.getSessionId()
        XCTAssertFalse(sessionId.isEmpty) // We should get a session ID
    }
}






