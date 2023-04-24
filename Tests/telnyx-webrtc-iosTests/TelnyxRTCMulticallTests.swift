//
//  TelnyxRTCMulticallTests.swift
//  TelnyxRTCTests
//
//  Created by Guillermo Battistel on 27/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import XCTest
@testable import TelnyxRTC

class TelnyxRTCMulticallTests: XCTestCase {
    private weak var expectation: XCTestExpectation!
    private var telnyxClient: TxClient?
    private var serverError: Error?

    //Create a dictonay of calls to be compared with the SDK calls
    private var myCallArray = [UUID: Call]()

    override func setUpWithError() throws {
        print("TelnyxRTCMulticallTests:: setUpWithError")
        //Setup the SDK
        self.telnyxClient = TxClient()
        self.telnyxClient?.delegate = self
        self.serverError = nil
    }

    override func tearDownWithError() throws {
        print("TelnyxRTCMulticallTests:: tearDownWithError")
        self.telnyxClient?.delegate = nil
        self.telnyxClient?.disconnect()
        self.telnyxClient = nil
        self.serverError = nil
        self.expectation = nil
    }
}
// MARK: - HELPER FUNCTIONS
extension TelnyxRTCMulticallTests {
    func connectAndReturnError(txConfig: TxConfig) -> Error? {
        //We are expecting an error
        var error: Error? = nil
        do {
            try self.telnyxClient?.connect(txConfig: txConfig)
        } catch let err {
            print("TelnyxRTCMulticallTests:: connect Error \(err)")
            error = err
        }
        return error
    }
}// TelnyxRTCMulticallTests helper functions

// MARK: - Multiple call tests
extension TelnyxRTCMulticallTests {

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
                                password: TestConstants.sipPassword,
                                logLevel: .info)

        let error: Error? = self.connectAndReturnError(txConfig: txConfig)
        XCTAssertNil(error) // We shouldn't get any error here
        waitForExpectations(timeout: 10)
        let sessionId = self.telnyxClient?.getSessionId() ?? ""
        XCTAssertFalse(sessionId.isEmpty) //We should have a session id after login in

        //Generate a random number
        let numberOfCalls = Int.random(in: 2..<10)

        print("testMultipleOutgoingCalls() Number of calls: \(numberOfCalls)")
        //Generate random number of calls
        for _ in 0...(numberOfCalls - 1) {
            let uuid = UUID.init()
            myCallArray[uuid] = try? self.telnyxClient?.newCall(callerName: "<dummyName>",
                                       callerNumber: "<dummyCallerNumber>",
                                       destinationNumber: "<dummyDestinationNumber>",
                                       callId: uuid)
            
            print("testMultipleOutgoingCalls() added to myCallArray: \(myCallArray.count)")
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
            print("testMultipleOutgoingCalls() hangup")
        }
        
        //Wait until all call ends
        sleep(20)
        print("testMultipleOutgoingCalls() myCallArray count = \(myCallArray.count)")
        print("testMultipleOutgoingCalls() Calls count = \(self.telnyxClient?.calls.count ?? -1)")
        //Check that all the calls has been removed.
        XCTAssertEqual(self.telnyxClient?.calls.count,myCallArray.count)
    }
}

// MARK: - TxClientDelegate
extension TelnyxRTCMulticallTests : TxClientDelegate {

    func onPushCall(call: Call) {
        print("TelnyxRTCMulticallTests :: TxClientDelegate onPushCall()")
    }

    func onSocketConnected() {
        print("TelnyxRTCMulticallTests :: TxClientDelegate onSocketConnected()")
    }

    func onSocketDisconnected() {
        print("TelnyxRTCMulticallTests :: TxClientDelegate onSocketDisconnected()")
    }

    func onClientError(error: Error) {
        print("TelnyxRTCMulticallTests :: TxClientDelegate onClientError()")
        self.serverError = error
        self.expectation?.fulfill()
    }

    func onClientReady() {
        print("TelnyxRTCMulticallTests :: TxClientDelegate onClientReady()")
    }

    func onSessionUpdated(sessionId: String) {
        print("TelnyxRTCMulticallTests :: TxClientDelegate onSessionUpdated()")
        self.expectation?.fulfill()
    }

    func onCallStateUpdated(callState: CallState, callId: UUID) {
        print("TelnyxRTCMulticallTests :: TxClientDelegate onCallStateUpdated()")
    }

    func onIncomingCall(call: Call) {
        print("TelnyxRTCMulticallTests :: TxClientDelegate onIncomingCall()")
    }

    func onRemoteCallEnded(callId: UUID) {
        print("TelnyxRTCMulticallTests :: TxClientDelegate onRemoteCallEnded()")
        print("testMultipleOutgoingCalls() remove from myCallArray: \(myCallArray.count)")
        myCallArray.removeValue(forKey: callId)
    }
}
