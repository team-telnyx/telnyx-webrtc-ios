//
//  CallTests.swift
//  TelnyxRTCTests
//
//  Created by Guillermo Battistel on 19/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import XCTest
import WebRTC
@testable import TelnyxRTC

class CallTests: XCTestCase {
    private weak var expectation: XCTestExpectation?
    private var call: Call?
    private var socket: Socket?

    override func setUpWithError() throws {
        print("CallTests:: setUpWithError")
        self.socket = Socket()
        self.socket?.delegate = self
        self.socket?.connect(signalingServer: InternalConfig.default.prodSignalingServer)
        guard let socket = self.socket else { return }
        self.call = Call(callId: UUID.init(), sessionId: "<sessionId>", socket: socket, delegate: self, iceServers: InternalConfig.default.prodWebRTCIceServers)
    }

    override func tearDownWithError() throws {
        print("CallTests:: tearDownWithError")
        self.expectation = nil
    }

    /**
     Test that the invite message is sent through the socket.
     - Wait socket connection to be completed.
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
    
    /**
     Test that the invite message is sent through the socket with custom headers.
     - Wait socket connection to be completed.
     - Starts the call process by creating an offer with custom headers
     - Once the ICE candidates negotiation finishes, we send an invite through the socket.
     - Wait for a server response onMessageReceived.
     - Verify that custom headers are properly set on the call.
     - NOTE: Due that we are not sending a valid sessionID we are going to get an "Authentication error" from the server.

     This test uses increased timeout to handle timing issues in CI environments where resources may be limited.
     */
    func testCallWithCustomHeaders() {
        // Detect CI environment and adjust timeout accordingly
        let isCI = ProcessInfo.processInfo.environment["CI"] != nil
        let timeout: TimeInterval = isCI ? 30.0 : 10.0

        //Wait for socket connection
        expectation = expectation(description: "socket")
        waitForExpectations(timeout: timeout)

        //Wait to send invite message.
        expectation = expectation(description: "newCall")

        let customHeaders = [
            "X-test1": "ios-test1",
            "X-test2": "ios-test2"
        ]

        self.call?.newCall(
            callerName: "callerName",
            callerNumber: "callerNumber",
            destinationNumber: "destinationNumber",
            customHeaders: customHeaders
        )

        waitForExpectations(timeout: timeout)

        // Verify custom headers
        let callCustomHeaders = call?.inviteCustomHeaders
        XCTAssertNotNil(callCustomHeaders, "Custom headers should not be nil")
        XCTAssertFalse(callCustomHeaders?.isEmpty == true, "Custom headers should not be empty")
        XCTAssertEqual(callCustomHeaders?["X-test1"], "ios-test1", "X-test1 header should match")
        XCTAssertEqual(callCustomHeaders?["X-test2"], "ios-test2", "X-test2 header should match")
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
    func onSocketDisconnected(reconnect: Bool, region: TelnyxRTC.Region?) {
        //
    }
    
    func onSocketReconnectSuggested() {
       //
    }
    
    func onSocketConnected() {
        print("Socket connected")
        expectation?.fulfill()
    }

    func onSocketDisconnected() {
        //
    }

    func onSocketError(error: Error) {
        //
    }

    func onMessageReceived(message: String) {
        print("CallTests :: SocketDelegate onMessageReceived")
        expectation?.fulfill()
    }
}
