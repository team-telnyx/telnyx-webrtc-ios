//
//  PeerConnectionTests.swift
//  TelnyxRTCTests
//
//  Created by Guillermo Battistel on 19/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import XCTest
import WebRTC
@testable import TelnyxRTC

class PeerConnectionTests: XCTestCase {
    private var peerConnection: Peer?

    override func setUpWithError() throws {
        print("PeerConnectionTests:: setUpWithError")
        //Setup the SDK
        let config = InternalConfig.default
        self.peerConnection = Peer(iceServers: config.webRTCIceServers)
    }

    override func tearDownWithError() throws {
        print("PeerConnectionTests:: tearDownWithError")
        self.peerConnection?.connection.close()
        self.peerConnection = nil
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
    }

    /**
     Test offer creation.
     - We should get an SDP if everythigng is correctly setup
     - Wait until ICE negotiation finishes onICECandidate should be called after that
     */
    func testCreateOffer() {
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

        // Creating an offer takes a short time, lets wait a few seconds for it.
        sleep(5)
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

        // Creating an offer takes a short time, lets wait a few seconds for it.
        sleep(5)

        //SDP should contain ICE Candidates. At least one is required to start calling
        let sdpAfterNegotiation = self.peerConnection?.connection.localDescription
        XCTAssertNotNil(sdpAfterNegotiation)
        XCTAssertTrue(sdpAfterNegotiation?.sdp.contains("ice-") ?? false)
    }
}
