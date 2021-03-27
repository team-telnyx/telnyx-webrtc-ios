//
//  WebRTCSDKMulticallTests.swift
//  WebRTCSDKTests
//
//  Created by Guillermo Battistel on 27/03/2021.
//
import XCTest
@testable import WebRTCSDK

class WebRTCSDKMulticallTests: XCTestCase {
    private var expectation: XCTestExpectation!
    private var telnyxClient: TxClient?
    private var serverError: Error?

    //Create a dictonay of calls to be compared with the SDK calls
    private var myCallArray = [UUID: Call]()

    override func setUpWithError() throws {
        print("WebRTCSDKMulticallTests:: setUpWithError")
        //Setup the SDK
        self.telnyxClient = TxClient()
        self.telnyxClient?.delegate = self
        self.serverError = nil
    }

    override func tearDownWithError() throws {
        print("WebRTCSDKMulticallTests:: tearDownWithError")
        self.telnyxClient?.delegate = nil
        self.telnyxClient?.disconnect()
        self.telnyxClient = nil
        self.serverError = nil
        self.expectation = nil
    }
}
// MARK: - HELPER FUNCTIONS
extension WebRTCSDKMulticallTests {
    func connectAndReturnError(txConfig: TxConfig) -> Error? {
        //We are expecting an error
        var error: Error? = nil
        do {
            try self.telnyxClient?.connect(txConfig: txConfig)
        } catch let err {
            print("WebRTCSDKMulticallTests:: connect Error \(err)")
            error = err
        }
        return error
    }
}// WebRTCSDKTests helper functions

// MARK: - Multiple call tests
extension WebRTCSDKMulticallTests {

    /**
     On this test we are:
     - Connecting to wss
     - Login in with sip user and password
     - Wait for sessionID.
     - Start a random number of calls.
     - Wait and compare if calls are been created inside the SDK.
     - Hanging up each call.
     - Check that each call was removed from the SDK.
     */
    func testMultipleOutgoingCalls() {

        //First we need to login before creating the calls
        expectation = expectation(description: "loginTest")

        let txConfig = TxConfig(sipUser: TestConstants.sipUser,
                                password: TestConstants.sipPassword)

        let error: Error? = self.connectAndReturnError(txConfig: txConfig)
        XCTAssertNil(error) // We shouldn't get any error here
        waitForExpectations(timeout: 10)
        let sessionId = self.telnyxClient?.getSessionId() ?? ""
        XCTAssertFalse(sessionId.isEmpty) //We should have a session id after login in

        //Generate a random number
        let numberOfCalls = Int.random(in: 2..<10)

        //Generate random number of calls
        for _ in 0...(numberOfCalls - 1) {
            let uuid = UUID.init()
            myCallArray[uuid] = try? self.telnyxClient?.newCall(callerName: "<dummyName>",
                                       callerNumber: "<dummyCallerNumber>",
                                       destinationNumber: "<dummyDestinationNumber>",
                                       callId: uuid)
        }

        XCTAssertTrue(myCallArray.count == numberOfCalls)
        XCTAssertTrue(myCallArray.count == self.telnyxClient?.calls.count)

        //Check if each created call exists inside the SDK
        for callUUID in myCallArray.keys {
            XCTAssertNotNil(self.telnyxClient?.calls[callUUID])
        }

        //End all calls
        for call in myCallArray.values {
            //calls should tratition to DONE State
            //after hangup()
            call.hangup()
        }
        //Check that all the calls has been removed.
        XCTAssertTrue(myCallArray.count == 0)
        XCTAssertTrue(self.telnyxClient?.calls.count == 0)

    }
}

// MARK: - TxClientDelegate
extension WebRTCSDKMulticallTests : TxClientDelegate {

    func onSocketConnected() {
        print("WebRTCSDKMulticallTests :: TxClientDelegate onSocketConnected()")
    }

    func onSocketDisconnected() {
        print("WebRTCSDKMulticallTests :: TxClientDelegate onSocketDisconnected()")
    }

    func onClientError(error: Error) {
        print("WebRTCSDKMulticallTests :: TxClientDelegate onClientError()")
        self.serverError = error
        self.expectation.fulfill()
    }

    func onClientReady() {
        print("WebRTCSDKMulticallTests :: TxClientDelegate onClientReady()")
    }

    func onSessionUpdated(sessionId: String) {
        print("WebRTCSDKMulticallTests :: TxClientDelegate onSessionUpdated()")
        self.expectation.fulfill()
    }

    func onCallStateUpdated(callState: CallState, callId: UUID) {
        print("WebRTCSDKMulticallTests :: TxClientDelegate onCallStateUpdated()")
        if (callState == .DONE) {
            //Remove each call if exists
            myCallArray.removeValue(forKey: callId)
        }
    }

    func onIncomingCall(call: Call) {
        print("WebRTCSDKMulticallTests :: TxClientDelegate onIncomingCall()")
    }

    func onRemoteCallEnded(callId: UUID) {
        print("WebRTCSDKMulticallTests :: TxClientDelegate onRemoteCallEnded()")
    }
}
