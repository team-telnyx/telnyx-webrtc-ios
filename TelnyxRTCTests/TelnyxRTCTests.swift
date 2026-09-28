import XCTest
@testable import TelnyxRTC

class TelnyxRTCTests: XCTestCase {
    
    func testTxConfigMissedCallNotificationsDefaultsToDisabled() {
        let txConfig = TxConfig(sipUser: "<userName>",
                                password: "<password>")

        XCTAssertFalse(txConfig.enableMissedCallNotifications)
    }

    func testTxConfigCanEnableMissedCallNotificationsForCredentialLogin() {
        let txConfig = TxConfig(sipUser: "<userName>",
                                password: "<password>",
                                enableMissedCallNotifications: true)

        XCTAssertTrue(txConfig.enableMissedCallNotifications)
    }

    func testTxConfigCanEnableMissedCallNotificationsForTokenLogin() {
        let txConfig = TxConfig(token: "<token>",
                                enableMissedCallNotifications: true)

        XCTAssertTrue(txConfig.enableMissedCallNotifications)
    }
    
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
            override func onClientError(error:Error) {
                XCTAssertEqual(error.localizedDescription,
                               TxError.serverError(reason:
                                    .signalingServerError(message: "Login Incorrect",
                                                          code: "-32001")).localizedDescription)
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
                guard case let TxError.serverError(reason) = error,
                      case let .signalingServerError(message, code) = reason else {
                    XCTFail("Expected signaling server error, got \(error)")
                    self.expectation.fulfill()
                    return
                }

                XCTAssertEqual(code, "-32001")
                XCTAssertTrue(
                    ["JWT token authentication failed", "Login Incorrect"].contains(message),
                    "Unexpected invalid-token error message: \(message)"
                )
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
     Test resetablish connection
     */
    func testReconnectUser(){
        
        class TestDelegate: RTCTestDelegate {
            //wait for client error to be called
            override func onClientError(error: Error) {
                self.expectation.fulfill()
            }
            
            // We are going to wait the session to be updated
            override func onSessionUpdated(sessionId: String) {
                self.expectation.fulfill()
            }
        }
        
        class TestError : Error {
            var reason = ""
            init(reason:String){
                self.reason = reason
            }
        }
        
        let errorExpectation = XCTestExpectation()
        let telnyxClient = TxClient()
        let delegate = TestDelegate(expectation: errorExpectation)

        let txConfig = TxConfig(sipUser: TestConstants.sipUser,
                                password: TestConstants.sipPassword,reconnectClient: true)
        
        telnyxClient.delegate = delegate
        try! telnyxClient.connect(txConfig: txConfig)
        telnyxClient.onSocketError(error:TestError(reason: "Socket Error"))

        //Error rcpection should be fulfiled
        wait(for: [errorExpectation], timeout: 10)
        
        let connectExpectation = XCTestExpectation()
        let connectDelegate = TestDelegate(expectation: connectExpectation)
        telnyxClient.delegate = connectDelegate
        
        //The client should be connected without calling connect again.
        wait(for: [connectExpectation], timeout: 10)

        let sessionId = telnyxClient.getSessionId()
        XCTAssertFalse(sessionId.isEmpty) // We should get a session ID
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
        
        wait(for: [expectation], timeout: 15)
        
        let sessionId = telnyxClient.getSessionId()
        XCTAssertFalse(sessionId.isEmpty) // We should get a session ID
    }
}

private final class InMemoryPushTokenRegistrationStore: PushTokenRegistrationStoring {
    var history = StoredPushTokenHistory()

    func load() throws -> StoredPushTokenHistory {
        history
    }

    func save(_ history: StoredPushTokenHistory) throws {
        self.history = history
    }
}

private final class PushCleanupCapturingSocket: Socket {
    private(set) var sentMethods: [String] = []

    override func sendMessage(message: String?) {
        guard let message,
              let data = message.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let method = json["method"] as? String else {
            return
        }
        sentMethods.append(method)
    }
}

final class PushTokenRegistrationTrackerTests: XCTestCase {
    private let accountKey = "sip:alice"

    func testFirstObservedTokenBecomesCurrentWithoutCleanup() throws {
        let store = InMemoryPushTokenRegistrationStore()
        let tracker = PushTokenRegistrationTracker(store: store)
        let current = registration(token: "CURRENT", environment: "debug")

        let cleanup = try tracker.registrationsToCleanup(
            current: current,
            accountKey: accountKey
        )

        XCTAssertTrue(cleanup.isEmpty)
        XCTAssertEqual(store.history.accounts[accountKey]?.current, current)
        XCTAssertTrue(store.history.accounts[accountKey]?.pendingCleanup.isEmpty == true)
    }

    func testTokenRotationQueuesOnlyPreviousRegistration() throws {
        let store = InMemoryPushTokenRegistrationStore()
        let tracker = PushTokenRegistrationTracker(store: store)
        let previous = registration(token: "OLD", environment: "production")
        let current = registration(token: "NEW", environment: "debug")

        _ = try tracker.registrationsToCleanup(current: previous, accountKey: accountKey)
        let cleanup = try tracker.registrationsToCleanup(current: current, accountKey: accountKey)

        XCTAssertEqual(cleanup, [previous])
        XCTAssertEqual(store.history.accounts[accountKey]?.current, current)
        XCTAssertEqual(store.history.accounts[accountKey]?.pendingCleanup, [previous])
    }

    func testEnvironmentChangeQueuesPreviousRegistrationEvenWhenTokenMatches() throws {
        let store = InMemoryPushTokenRegistrationStore()
        let tracker = PushTokenRegistrationTracker(store: store)
        let sandbox = registration(token: "SAME", environment: "debug")
        let production = registration(token: "SAME", environment: "production")

        _ = try tracker.registrationsToCleanup(current: sandbox, accountKey: accountKey)
        let cleanup = try tracker.registrationsToCleanup(current: production, accountKey: accountKey)

        XCTAssertEqual(cleanup, [sandbox])
    }

    func testUnconfirmedCleanupsRemainQueuedAcrossMultipleRotations() throws {
        let store = InMemoryPushTokenRegistrationStore()
        let tracker = PushTokenRegistrationTracker(store: store)
        let first = registration(token: "FIRST", environment: "debug")
        let second = registration(token: "SECOND", environment: "debug")
        let third = registration(token: "THIRD", environment: "debug")

        _ = try tracker.registrationsToCleanup(current: first, accountKey: accountKey)
        _ = try tracker.registrationsToCleanup(current: second, accountKey: accountKey)
        let cleanup = try tracker.registrationsToCleanup(current: third, accountKey: accountKey)

        XCTAssertEqual(cleanup, [first, second])
    }

    func testConfirmedCleanupIsRemovedFromRetryQueue() throws {
        let store = InMemoryPushTokenRegistrationStore()
        let tracker = PushTokenRegistrationTracker(store: store)
        let previous = registration(token: "OLD", environment: "debug")
        let current = registration(token: "NEW", environment: "debug")

        _ = try tracker.registrationsToCleanup(current: previous, accountKey: accountKey)
        _ = try tracker.registrationsToCleanup(current: current, accountKey: accountKey)
        try tracker.markCleanupSucceeded(previous, accountKey: accountKey)

        XCTAssertTrue(store.history.accounts[accountKey]?.pendingCleanup.isEmpty == true)
        XCTAssertEqual(store.history.accounts[accountKey]?.current, current)
    }

    func testRegistrationsAreScopedBySipAccount() throws {
        let store = InMemoryPushTokenRegistrationStore()
        let tracker = PushTokenRegistrationTracker(store: store)
        let alice = registration(token: "ALICE", environment: "debug")
        let bob = registration(token: "BOB", environment: "debug")

        _ = try tracker.registrationsToCleanup(current: alice, accountKey: "sip:alice")
        let bobCleanup = try tracker.registrationsToCleanup(current: bob, accountKey: "sip:bob")

        XCTAssertTrue(bobCleanup.isEmpty)
        XCTAssertEqual(store.history.accounts["sip:alice"]?.current, alice)
        XCTAssertEqual(store.history.accounts["sip:bob"]?.current, bob)
    }

    func testCleanupIsSentOnlyAfterGatewayRegistrationIsConfirmed() throws {
        let store = InMemoryPushTokenRegistrationStore()
        let tracker = PushTokenRegistrationTracker(store: store)
        let previous = registration(token: "OLD", environment: "production")
        let current = registration(token: "NEW", environment: "debug")
        _ = try tracker.registrationsToCleanup(current: previous, accountKey: accountKey)

        let client = TxClient()
        let socket = PushCleanupCapturingSocket()
        client.pushTokenRegistrationTracker = tracker
        client.txConfig = TxConfig(
            sipUser: "alice",
            password: "password",
            pushDeviceToken: current.token,
            pushEnvironment: .debug
        )
        client.setSocketForTesting(socket)

        client.onSocketConnected()

        XCTAssertEqual(socket.sentMethods, [Method.LOGIN.rawValue])
        XCTAssertEqual(store.history.accounts[accountKey]?.current, previous)

        client.onMessageReceived(message: """
        {"jsonrpc":"2.0","id":"gateway-state","result":{"params":{"state":"REGED"}}}
        """)

        XCTAssertEqual(
            socket.sentMethods,
            [Method.LOGIN.rawValue, Method.DISABLE_PUSH.rawValue]
        )
        XCTAssertEqual(store.history.accounts[accountKey]?.current, current)
        XCTAssertEqual(store.history.accounts[accountKey]?.pendingCleanup, [previous])
    }

    private func registration(token: String, environment: String) -> StoredPushTokenRegistration {
        StoredPushTokenRegistration(
            token: token,
            provider: TxPushConfig.PUSH_NOTIFICATION_PROVIDER,
            environment: environment
        )
    }
}
