//
//  SocketTests.swift
//  WebRTCSDKTests
//
//  Created by Guillermo Battistel on 17/03/2021.
//

import XCTest
@testable import WebRTCSDK

class SocketTests : XCTestCase, SocketDelegate {

    private var socketConnectedExpectation: XCTestExpectation!
    private var socketDisconnectedExpectation: XCTestExpectation!
    private var socketMessageExpectation: XCTestExpectation!
    private var errorResponse: [String: Any]? = nil

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
    }

    /**
     Test socket connection, sends a message, waits the reponse and disconnects
     */
    func testSocketBasics() {
        print("VertoMessagesTest :: testSocketBasics()")
        socketConnectedExpectation = expectation(description: "socketConnection")
        let socket = Socket()
        socket.delegate = self
        socket.connect()
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
        socket.disconnect()
        waitForExpectations(timeout: 5)
        XCTAssertFalse(socket.isConnected)
    }

}
