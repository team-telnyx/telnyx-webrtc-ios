//
//  SocketTests.swift
//  TelnyxRTCTests
//
//  Created by Guillermo Battistel on 17/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import XCTest
@testable import TelnyxRTC

class SocketTests : XCTestCase, SocketDelegate {
    func onSocketDisconnected(reconnect: Bool, region: TelnyxRTC.Region?) {
        //
    }
    
    
    func onSocketDisconnected(reconnect: Bool) {
        //Handle socket disconnected
        socketDisconnectedExpectation.fulfill()
    }
    

    private weak var socketConnectedExpectation: XCTestExpectation!
    private weak var socketPingExpectation: XCTestExpectation!
    private weak var socketDisconnectedExpectation: XCTestExpectation!
    private weak var socketMessageExpectation: XCTestExpectation!
    private var errorResponse: [String: Any]? = nil
    
    var isPing = false

    func onSocketConnected() {
        socketConnectedExpectation.fulfill()
    }

    func onSocketDisconnected() {
        socketDisconnectedExpectation.fulfill()
    }

    func onSocketError(error: Error) {
        //TODO: find a way to force different socket errors.
    }

    func onMessageReceived(message: String) {
        //For now we are not checking the response, just if we get any response.
        let serverResponse = Message().decode(message: message)
        errorResponse = serverResponse?.serverError
        socketMessageExpectation.fulfill()
        
        if serverResponse?.method == .PING {
            isPing = true
        }
    }

    /**
     Test socket connection, sends a message, waits the reponse and disconnects
     */
    func testSocketBasics() {
        print("VertoMessagesTest :: testSocketBasics()")
        socketConnectedExpectation = expectation(description: "socketConnection")
        let socket = Socket()
        socket.delegate = self
        socket.connect(signalingServer: InternalConfig.default.prodSignalingServer)
        waitForExpectations(timeout: 5)
        XCTAssertTrue(socket.isConnected)

        var params = [String: Any]()
        params["my_dummy_param"] = "my_dummy_value"
        let message = Message(params, method: .ECHO)
        socketMessageExpectation = expectation(description: "socketSendMessage")
        //Need to be authenticated to receive the echo response, so we should receive an error from the server
        socket.sendMessage(message: message.encode())
        waitForExpectations(timeout: 5)

        //TODO: This should be changed when implementing an echo without login
        //waiting an error from the server.
        let code = self.errorResponse?["code"] as? Int ?? 0
        XCTAssertEqual(code, -32000) //check auth error

        socketDisconnectedExpectation = expectation(description: "socketDisconnection")
        socket.disconnect(reconnect: false)
        waitForExpectations(timeout: 5)
        XCTAssertFalse(socket.isConnected)
    }
    //MARK: - Test case for not send ping to screen 
    func testPingPong() {
        print("VertoMessagesTest :: testSocketPing()")
        socketPingExpectation = expectation(description: "socketPing")
        socketPingExpectation.fulfill()
        socketDisconnectedExpectation = expectation(description: "socketDisconnection")
        socketDisconnectedExpectation.fulfill()
        socketMessageExpectation = expectation(description: "socketSendMessage")
        socketConnectedExpectation = expectation(description: "socketConnection")
        isPing = false
        let socket = Socket()
        socket.delegate = self
        socket.connect(signalingServer: InternalConfig.default.prodSignalingServer)
        waitForExpectations(timeout: 40)
        XCTAssertTrue(isPing)
    }
}
