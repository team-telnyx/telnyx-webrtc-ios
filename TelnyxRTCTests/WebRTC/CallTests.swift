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
        self.call = Call(callId: UUID.init(), sessionId: "<sessionId>", socket: socket, delegate: self, iceServers: InternalConfig.default.webRTCIceServers)
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
     Test that the invite message is sent through the socket.
     - Wait socket connection to be completed.
     - Starts the call process by creating an offer
     - Once the ICE candidates negotiation finishes, we send an invite through the socket.
     - Wait for a server response onMessageReceived.
     - NOTE: Due that we are not sending a valid sessionID we are going to get an "Authentication error" from the server.
     */
    func testCallWithCustomHeaders() {
        //Wait for socket connection
        expectation = expectation(description: "socket")
        waitForExpectations(timeout: 10)

        //Wait to send invite message.
        expectation = expectation(description: "newCall")
        self.call?.newCall(callerName: "callerName", callerNumber: "callerNumber", destinationNumber: "destinationNumber",customHeaders:  ["X-test1":"ios-test1",
            "X-test2":"ios-test2"])
        waitForExpectations(timeout: 10)
        
        let customHeaders = call?.inviteCustomHeaders
        XCTAssertFalse(customHeaders?.isEmpty == true) // We should get a session ID
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
    
    func onSocketDisconnected(reconnect: Bool) {
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
