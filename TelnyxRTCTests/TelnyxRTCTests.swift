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
    var saved: StoredPushTokenRegistration?
    private(set) var saveCount = 0

    func load() -> StoredPushTokenRegistration? {
        saved
    }

    func save(_ registration: StoredPushTokenRegistration) {
        saved = registration
        saveCount += 1
    }
}

private final class PushCleanupCapturingSocket: Socket {
    private(set) var sentMessages: [[String: Any]] = []

    var sentMethods: [String] {
        sentMessages.compactMap { $0["method"] as? String }
    }

    var disablePushMessages: [[String: Any]] {
        sentMessages.filter { $0["method"] as? String == Method.DISABLE_PUSH.rawValue }
    }

    override func sendMessage(message: String?) {
        guard let data = message?.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        sentMessages.append(json)
    }
}

private final class PushCleanupDelegate: MockTxClientDelegate {
    var pushDisabledCallCount = 0

    override func onPushDisabled(success: Bool, message: String) {
        pushDisabledCallCount += 1
    }
}

/// Regression tests for removing the previous push registration after a token rotates.
final class PushTokenCleanupTests: XCTestCase {
    private let store = InMemoryPushTokenRegistrationStore()
    private let socket = PushCleanupCapturingSocket()

    private var server: String {
        TxServerConfiguration().signalingServer.host ?? ""
    }

    func testFirstLoginSavesTokenWithoutCleanup() {
        register(makeClient(config: sipConfig(token: "CURRENT")))

        XCTAssertTrue(socket.disablePushMessages.isEmpty)
        XCTAssertEqual(store.saved?.token, "CURRENT")
    }

    func testUnchangedRegistrationSendsNothingAndDoesNotWriteKeychain() {
        store.saved = registration(token: "CURRENT")

        register(makeClient(config: sipConfig(token: "CURRENT")))

        XCTAssertTrue(socket.disablePushMessages.isEmpty)
        XCTAssertEqual(store.saveCount, 0)
    }

    func testRotatedTokenDisablesExactPreviousRegistrationOnlyAfterRegistered() throws {
        store.saved = registration(token: "OLD", environment: "production")
        let client = makeClient(config: sipConfig(token: "NEW"))

        client.onSocketConnected()
        XCTAssertEqual(socket.sentMethods, [Method.LOGIN.rawValue])

        register(client)

        XCTAssertEqual(socket.sentMethods, [Method.LOGIN.rawValue, Method.DISABLE_PUSH.rawValue])
        let params = try XCTUnwrap(socket.disablePushMessages.first?["params"] as? [String: Any])
        XCTAssertEqual(params["user"] as? String, "alice")
        let pushVariables = try XCTUnwrap(params["User-Agent"] as? [String: String])
        XCTAssertEqual(pushVariables["push_device_token"], "OLD")
        XCTAssertEqual(pushVariables["push_notification_environment"], "production")
    }

    func testSuccessResponseSavesNewTokenWithoutTellingTheApp() throws {
        store.saved = registration(token: "OLD")
        let delegate = PushCleanupDelegate()
        let client = makeClient(config: sipConfig(token: "NEW"))
        client.delegate = delegate
        register(client)
        XCTAssertEqual(store.saved?.token, "OLD", "Nothing is saved until the server responds")

        client.onMessageReceived(message: """
        {"jsonrpc":"2.0","id":"\(try disablePushId())","method":"\(Method.DISABLE_PUSH.rawValue)","result":{"message":"disable push notification success"}}
        """)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        XCTAssertEqual(store.saved?.token, "NEW")
        XCTAssertEqual(delegate.pushDisabledCallCount, 0)
    }

    func testErrorResponseSavesNewTokenSoItIsNotResentForever() throws {
        store.saved = registration(token: "OLD")
        let delegate = PushCleanupDelegate()
        let client = makeClient(config: sipConfig(token: "NEW"))
        client.delegate = delegate
        register(client)

        client.onMessageReceived(message: """
        {"jsonrpc":"2.0","id":"\(try disablePushId())","error":{"code":-32000,"message":"not found"}}
        """)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

        XCTAssertEqual(store.saved?.token, "NEW")
        XCTAssertFalse(delegate.onClientErrorCalled)

        let nextSocket = PushCleanupCapturingSocket()
        register(makeClient(config: sipConfig(token: "NEW"), socket: nextSocket))
        XCTAssertTrue(nextSocket.disablePushMessages.isEmpty)
    }

    func testDisconnectBeforeResponseRetriesOnNextLogin() throws {
        store.saved = registration(token: "OLD")
        let client = makeClient(config: sipConfig(token: "NEW"))
        register(client)
        let id = try disablePushId()

        client.onSocketConnected()
        client.onMessageReceived(message: """
        {"jsonrpc":"2.0","id":"\(id)","result":{"message":"disable push notification success"}}
        """)
        XCTAssertEqual(store.saved?.token, "OLD", "A new connection forgets the unanswered request")

        let nextSocket = PushCleanupCapturingSocket()
        register(makeClient(config: sipConfig(token: "NEW"), socket: nextSocket))
        XCTAssertEqual(nextSocket.disablePushMessages.count, 1)
    }

    /// If the backend matches on the token alone, disabling the old environment would remove
    /// the registration that was just created, so the phone would stop ringing.
    func testSameTokenInAnotherEnvironmentSavesWithoutCleanup() {
        store.saved = registration(token: "SAME", environment: "production")

        register(makeClient(config: sipConfig(token: "SAME", environment: .debug)))

        XCTAssertTrue(socket.disablePushMessages.isEmpty)
        XCTAssertEqual(store.saved?.environment, PushEnvironment.debug.rawValue)
    }

    /// Login sends a build-based environment when the app sets none, so the record must store
    /// that value. Otherwise a later release build would disable the wrong environment.
    func testLoginWithoutEnvironmentSavesTheEnvironmentLoginSent() {
        register(makeClient(config: TxConfig(sipUser: "alice", password: "password", pushDeviceToken: "CURRENT")))

        XCTAssertEqual(store.saved?.environment, PushEnvironment.debug.rawValue)
    }

    func testDifferentSipUserSavesWithoutCleanup() {
        store.saved = registration(token: "OLD", accountKey: "sip:bob")

        register(makeClient(config: sipConfig(token: "NEW")))

        XCTAssertTrue(socket.disablePushMessages.isEmpty)
        XCTAssertEqual(store.saved?.accountKey, "sip:alice")
    }

    func testDifferentServerSavesWithoutCleanup() {
        store.saved = registration(token: "OLD", server: "another.example.com")

        register(makeClient(config: sipConfig(token: "NEW")))

        XCTAssertTrue(socket.disablePushMessages.isEmpty)
        XCTAssertEqual(store.saved?.server, server)
    }

    func testJwtLoginCleansUpRotatedTokenUsingCurrentJwt() throws {
        store.saved = registration(token: "OLD", accountKey: "jwt")

        register(makeClient(config: TxConfig(token: "REFRESHED_JWT",
                                             pushDeviceToken: "NEW",
                                             pushEnvironment: .debug)))

        let params = try XCTUnwrap(socket.disablePushMessages.first?["params"] as? [String: Any])
        XCTAssertEqual(params["login_token"] as? String, "REFRESHED_JWT")
        let pushVariables = try XCTUnwrap(params["User-Agent"] as? [String: String])
        XCTAssertEqual(pushVariables["push_device_token"], "OLD")
    }

    func testRefreshedJwtWithSameTokenSendsNothing() {
        store.saved = registration(token: "CURRENT", accountKey: "jwt")

        register(makeClient(config: TxConfig(token: "REFRESHED_JWT",
                                             pushDeviceToken: "CURRENT",
                                             pushEnvironment: .debug)))

        XCTAssertTrue(socket.disablePushMessages.isEmpty)
        XCTAssertEqual(store.saveCount, 0)
    }

    func testLoginNotStartedByConnectSendsAndSavesNothing() {
        store.saved = registration(token: "OLD")
        let client = makeClient(config: sipConfig(token: "NEW"))
        client.cleansUpStalePushToken = false

        register(client)

        XCTAssertTrue(socket.disablePushMessages.isEmpty)
        XCTAssertEqual(store.saveCount, 0)
    }

    func testOnlyConnectEnablesCleanup() throws {
        let client = TxClient()
        defer { client.disconnect() }
        let unreachable = TxServerConfiguration(signalingServer: URL(string: "wss://127.0.0.1:9"))

        try client.connect(txConfig: sipConfig(token: "NEW"), serverConfiguration: unreachable)
        XCTAssertTrue(client.cleansUpStalePushToken)

        client.anonymousLogin(targetId: "assistant", serverConfiguration: unreachable)
        XCTAssertFalse(client.cleansUpStalePushToken)

        try client.connect(txConfig: sipConfig(token: "NEW"), serverConfiguration: unreachable)
        try client.processVoIPNotification(txConfig: sipConfig(token: "CACHED"),
                                           serverConfiguration: unreachable,
                                           pushMetaData: ["voice_sdk_id": "test"])
        XCTAssertFalse(client.cleansUpStalePushToken)
    }

    private func makeClient(config: TxConfig, socket: PushCleanupCapturingSocket? = nil) -> TxClient {
        let client = TxClient()
        client.pushTokenRegistrationStore = store
        client.cleansUpStalePushToken = true
        client.txConfig = config
        client.injectSignalingForTesting(socket: socket ?? self.socket, sessionId: client.getSessionId())
        return client
    }

    private func register(_ client: TxClient) {
        client.onMessageReceived(message: """
        {"jsonrpc":"2.0","id":"gateway-state","result":{"params":{"state":"REGED"}}}
        """)
    }

    private func disablePushId() throws -> String {
        try XCTUnwrap(socket.disablePushMessages.first?["id"] as? String)
    }

    private func sipConfig(token: String, environment: PushEnvironment = .debug) -> TxConfig {
        TxConfig(sipUser: "alice", password: "password", pushDeviceToken: token, pushEnvironment: environment)
    }

    private func registration(
        token: String,
        environment: String = PushEnvironment.debug.rawValue,
        accountKey: String = "sip:alice",
        server: String? = nil
    ) -> StoredPushTokenRegistration {
        StoredPushTokenRegistration(
            token: token,
            provider: TxPushConfig.PUSH_NOTIFICATION_PROVIDER,
            environment: environment,
            accountKey: accountKey,
            server: server ?? self.server
        )
    }
}
