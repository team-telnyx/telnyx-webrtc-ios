//
//  PeerConnectionTests.swift
//  WebRTCSDKTests
//
//  Created by Guillermo Battistel on 19/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import XCTest
import WebRTC
@testable import WebRTCSDK

class PeerConnectionTests: XCTestCase {
    private weak var createOfferExpectation: XCTestExpectation!
    private weak var createAnswerExpectation: XCTestExpectation!
    private var peerConnection: Peer?

    override func setUpWithError() throws {
        print("PeerConnectionTests:: setUpWithError")
        //Setup the SDK
        let config = InternalConfig.default
        self.peerConnection = Peer(iceServers: config.webRTCIceServers)
        self.peerConnection?.delegate = self
    }

    override func tearDownWithError() throws {
        print("PeerConnectionTests:: tearDownWithError")
        self.peerConnection?.connection.close()
        self.peerConnection = nil
        self.createOfferExpectation = nil
        self.createAnswerExpectation = nil
    }

    /**
     Test peer initialization. We are checkin if Peer is fully configured
     */
    func testPeerInit() {
        //Check if connection was created
        XCTAssertNotNil(self.peerConnection?.connection)

        //Check valid semantics
        let semantics = self.peerConnection?.connection.configuration.sdpSemantics
        XCTAssertEqual(semantics, .planB) //Currently we support planB for video calls.
                                          //Unified plan for video calls is currently not supported from the backend.

        //Check valid audio sender
        let audio = self.peerConnection?.connection.senders
            .compactMap { return $0.track as? RTCAudioTrack }.first // Search for Audio track
        XCTAssertNotNil(audio)

        //Check valid video sender
        let video = self.peerConnection?.connection.senders
            .compactMap { return $0.track as? RTCVideoTrack }.first // Search for Audio track
        XCTAssertNotNil(video)
    }

    /**
     Test offer creation.
     - We should get an SDP if everythigng is correctly setup
     - Wait until ICE negotiation finishes onICECandidate should be called after that
     */
    func testCreateOffer() {
        createOfferExpectation = expectation(description: "createOffer")

        //SDP should be nil when creating the first offer
        let sdpPreviousNegotiation = self.peerConnection?.connection.localDescription
        XCTAssertNil(sdpPreviousNegotiation)
        self.peerConnection?.offer(completion: { (sdp, error)  in

            if let error = error {
                print("Error creating the offer: \(error)")
                return
            }

            guard let sdp = sdp else {
                return
            }
            print("Error creating the offer: \(sdp)")
        })

        waitForExpectations(timeout: 10)
        //SDP should contain ICE Candidates. At least one is required to start calling
        let sdpAfterNegotiation = self.peerConnection?.connection.localDescription
        XCTAssertNotNil(sdpAfterNegotiation)
        XCTAssertTrue(sdpAfterNegotiation?.sdp.contains("ice-") ?? false)
    }

    /**
     Test Peer create answer after receiving a remote SDP
     - Set the remote description.
     - Create the answer and wait for the local SDP after the ICE negotiation
     */
    func testCreateAnwser() {
        // Create SDP from file.
        let remoteDescription = RTCSessionDescription(type: .offer, sdp: TestConstants.REMOTE_SDP)

        //Set the incoming remote SDP
        self.peerConnection?.connection.setRemoteDescription(remoteDescription, completionHandler: { (error) in
            guard let error = error else {
                return
            }
            print("Error setting remote description: \(error)")
        })

        //Answer the call
        createAnswerExpectation = expectation(description: "createAnswer")
        self.peerConnection?.answer(completion: { (sdp, error)  in

            if let error = error {
                print("Error creating the answering: \(error)")
                return
            }

            guard let sdp = sdp else {
                return
            }
            print("Answer completed >> SDP: \(sdp)")
        })
        waitForExpectations(timeout: 10)
        //SDP should contain ICE Candidates. At least one is required to start calling
        let sdpAfterNegotiation = self.peerConnection?.connection.localDescription
        XCTAssertNotNil(sdpAfterNegotiation)
        XCTAssertTrue(sdpAfterNegotiation?.sdp.contains("ice-") ?? false)
    }
}

// MARK: - PeerDelegate
extension PeerConnectionTests : PeerDelegate {

    func onICECandidate(sdp: RTCSessionDescription?, iceCandidate: RTCIceCandidate) {
        print("PeerConnectionTests:: PeerDelegate onICECandidate")
        if self.createOfferExpectation?.description == "createOffer",
           self.createOfferExpectation?.expectedFulfillmentCount ?? 0 > 0 {
            self.createOfferExpectation?.fulfill()
        }

        if self.createAnswerExpectation?.description == "createAnswer",
           self.createAnswerExpectation?.expectedFulfillmentCount ?? 0 > 0 {
            self.createAnswerExpectation?.fulfill()
        }
    }
}
