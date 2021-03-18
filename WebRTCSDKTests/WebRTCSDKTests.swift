//
//  WebRTCSDKTests.swift
//  WebRTCSDKTests
//
//  Created by Guillermo Battistel on 01/03/2021.
//

import XCTest
@testable import WebRTCSDK

class WebRTCSDKTests: XCTestCase {
    private var telnyxClient : TxClient?

    override func setUpWithError() throws {
        print("WebRTCSDKTests:: setUpWithError")
        //Setup the SDK
        self.telnyxClient = TxClient()
    }

    override func tearDownWithError() throws {
        print("WebRTCSDKTests:: tearDownWithError")
        self.telnyxClient?.delegate = nil
        self.telnyxClient?.disconnect()
        self.telnyxClient = nil
    }

    // MARK: - HELPER FUNCTIONS
    func connectAndReturnError(txConfig: TxConfig) -> Error? {
        //We are expecting an error
        var error: Error? = nil
        do {
            try self.telnyxClient?.connect(txConfig: txConfig)
        } catch let err {
            print("ViewController:: connect Error \(err)")
            error = err
        }
        return error
    }

    // MARK: - LOGIN RELATED TESTS

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

}
