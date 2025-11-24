//
//  AudioConstraintsTests.swift
//  TelnyxRTCTests
//
//  Unit tests for AudioConstraints functionality
//

import XCTest
@testable import TelnyxRTC

final class AudioConstraintsTests: XCTestCase {
    
    // MARK: - AudioConstraints Initialization Tests
    
    func testAudioConstraintsDefaultInitialization() {
        // Test default initialization (all constraints should be true)
        let audioConstraints = AudioConstraints()
        
        XCTAssertTrue(audioConstraints.echoCancellation, "Echo cancellation should be true by default")
        XCTAssertTrue(audioConstraints.noiseSuppression, "Noise suppression should be true by default")
        XCTAssertTrue(audioConstraints.autoGainControl, "Auto gain control should be true by default")
    }
    
    func testAudioConstraintsCustomInitialization() {
        // Test custom initialization
        let audioConstraints = AudioConstraints(
            echoCancellation: false,
            noiseSuppression: true,
            autoGainControl: false
        )
        
        XCTAssertFalse(audioConstraints.echoCancellation, "Echo cancellation should be false")
        XCTAssertTrue(audioConstraints.noiseSuppression, "Noise suppression should be true")
        XCTAssertFalse(audioConstraints.autoGainControl, "Auto gain control should be false")
    }
    
    func testAudioConstraintsPartialInitialization() {
        // Test partial initialization (should use defaults for unspecified parameters)
        let audioConstraints = AudioConstraints(
            echoCancellation: false
            // noiseSuppression and autoGainControl should default to true
        )
        
        XCTAssertFalse(audioConstraints.echoCancellation, "Echo cancellation should be false")
        XCTAssertTrue(audioConstraints.noiseSuppression, "Noise suppression should default to true")
        XCTAssertTrue(audioConstraints.autoGainControl, "Auto gain control should default to true")
    }
    
    // MARK: - Peer Audio Constraints Tests
    
    func testPeerWithAudioConstraints() {
        // Test that Peer properly handles audio constraints
        let audioConstraints = AudioConstraints(
            echoCancellation: true,
            noiseSuppression: false,
            autoGainControl: true
        )
        
        let iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        let peer = Peer(
            iceServers: iceServers,
            forceRelayCandidate: false,
            audioConstraints: audioConstraints
        )
        
        // Verify that the peer stores the audio constraints
        XCTAssertEqual(peer.audioConstraints?.echoCancellation, true)
        XCTAssertEqual(peer.audioConstraints?.noiseSuppression, false)
        XCTAssertEqual(peer.audioConstraints?.autoGainControl, true)
    }
    
    func testPeerWithoutAudioConstraints() {
        // Test that Peer works without audio constraints
        let iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        let peer = Peer(
            iceServers: iceServers,
            forceRelayCandidate: false,
            audioConstraints: nil
        )
        
        // Verify that the peer has no audio constraints
        XCTAssertNil(peer.audioConstraints)
    }
    
    // MARK: - Call Audio Constraints Tests
    
    func testCallWithAudioConstraints() {
        // Test that Call properly handles audio constraints
        let audioConstraints = AudioConstraints(
            echoCancellation: false,
            noiseSuppression: false,
            autoGainControl: false
        )
        
        let iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        let sessionId = "test-session"
        let socket = MockSocket() // You'll need to create a mock socket for testing
        let delegate = MockCallDelegate() // You'll need to create a mock delegate for testing
        
        let call = Call(
            callId: UUID(),
            sessionId: sessionId,
            socket: socket,
            delegate: delegate,
            iceServers: iceServers,
            audioConstraints: audioConstraints
        )
        
        // Verify that the call stores the audio constraints
        XCTAssertEqual(call.audioConstraints?.echoCancellation, false)
        XCTAssertEqual(call.audioConstraints?.noiseSuppression, false)
        XCTAssertEqual(call.audioConstraints?.autoGainControl, false)
    }
    
    func testCallWithoutAudioConstraints() {
        // Test that Call works without audio constraints
        let iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        let sessionId = "test-session"
        let socket = MockSocket()
        let delegate = MockCallDelegate()
        
        let call = Call(
            callId: UUID(),
            sessionId: sessionId,
            socket: socket,
            delegate: delegate,
            iceServers: iceServers,
            audioConstraints: nil
        )
        
        // Verify that the call has no audio constraints
        XCTAssertNil(call.audioConstraints)
    }
    
    // MARK: - WebRTC Constraints Mapping Tests
    
    func testWebRTCConstraintsMapping() {
        // Test that audio constraints are properly mapped to WebRTC constraints
        let audioConstraints = AudioConstraints(
            echoCancellation: true,
            noiseSuppression: false,
            autoGainControl: true
        )
        
        let iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        let peer = Peer(
            iceServers: iceServers,
            forceRelayCandidate: false,
            audioConstraints: audioConstraints
        )
        
        // Create audio track to test constraint application
        peer.createAudioTrack()
        
        // Note: In a real test environment, you would verify that the WebRTC
        // constraints are properly applied. This would require access to the
        // underlying WebRTC peer connection and media constraints, which may
        // not be directly accessible in the testing environment.
        
        // For now, we verify that the peer accepts and stores the constraints
        XCTAssertNotNil(peer.audioConstraints)
    }
}

// MARK: - Mock Classes for Testing

// Mock socket for testing
class MockSocket: Socket {
    // Implement required Socket methods for testing
    override init() {
        super.init()
    }
}

// Mock call delegate for testing
class MockCallDelegate: CallProtocol {
    func onCallStateDidChange(call: Call, state: CallState) {
        // Mock implementation
    }
    
    func onRemoteCallEnd(call: Call) {
        // Mock implementation
    }
    
    func onTrackAdded(call: Call, track: RTCMediaStreamTrack) {
        // Mock implementation
    }
    
    func onTrackRemoved(call: Call, track: RTCMediaStreamTrack) {
        // Mock implementation
    }
    
    func onGetStats(call: Call, stats: [RTCStatsReport]) {
        // Mock implementation
    }
    
    func onAudioDeviceDidChange(selectedAudioDevice: AudioDevice) {
        // Mock implementation
    }
    
    func onMessageReceived(call: Call, message: String) {
        // Mock implementation
    }
    
    func onRefreshAccessToken(call: Call) {
        // Mock implementation
    }
    
    func onSendDtmf(call: Call, code: String) {
        // Mock implementation
    }
}