//
//  CallTests.swift
//  WebRTCSDKTests
//
//  Created by Guillermo Battistel on 19/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import XCTest
import WebRTC
@testable import WebRTCSDK

class CallTests: XCTestCase {
    private weak var expectation: XCTestExpectation!
    private var call: Call?

    override func setUpWithError() throws {
        print("CallTests:: setUpWithError")
        let socket = Socket()
        socket.connect()
        socket.delegate = self
        self.call = Call(callId: UUID.init(), sessionId: "<sessionId>", socket: socket, delegate: self)
    }

    override func tearDownWithError() throws {
        print("CallTests:: tearDownWithError")
        self.expectation = nil
    }

    /**
     Test that the invite message is sent through the socket.
     - Wait socket connection to be compleated.
     - Starts the call process by creating an offer
     - Once the ICE candidates negotiation finishes, we send an invite through the socket.
     - Wait for a server response onMessageReceived.
     - NOTE: Due that we are not sending a valid sessionID we are going to get an "Authentication error" from the server.
     */
    func testNewCall() {
        //Wait for socket connection
        expectation = expectation(description: "socket")
        waitForExpectations(timeout: 10)

        //Wait to send invite message.
        expectation = expectation(description: "newCall")
        self.call?.newCall(callerName: "callerName", callerNumber: "callerNumber", destinationNumber: "destinationNumber")
        waitForExpectations(timeout: 10)
    }
}

// MARK: - CallProtocol
extension CallTests : CallProtocol {
    func callStateUpdated(call: Call) {
        print("CallTests :: CallProtocol callStateUpdated")
    }
}

// MARK: - SocketDelegate
extension CallTests : SocketDelegate {
    func onSocketConnected() {
        print("Socket connected")
        expectation.fulfill()
    }

    func onSocketDisconnected() {
        //
    }

    func onSocketError(error: Error) {
        //
    }

    func onMessageReceived(message: String) {
        print("CallTests :: SocketDelegate onMessageReceived")
        expectation.fulfill()
    }
}
