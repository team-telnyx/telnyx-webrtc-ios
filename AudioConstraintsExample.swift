//
//  AudioConstraintsExample.swift
//  Example demonstrating Audio Constraints usage
//

import Foundation
import TelnyxRTC

/// Example demonstrating how to use AudioConstraints with TelnyxRTC
class AudioConstraintsExample {
    
    /// Example 1: Create a call with default audio constraints (all enabled)
    func createCallWithDefaultAudioConstraints(telnyxClient: TxClient) throws -> Call {
        let audioConstraints = AudioConstraints() // All defaults to true
        
        let call = try telnyxClient.newCall(
            callerName: "John Doe",
            callerNumber: "+15551234567",
            destinationNumber: "+15557654321",
            callId: UUID(),
            audioConstraints: audioConstraints
        )
        
        return call
    }
    
    /// Example 2: Create a call with custom audio constraints
    func createCallWithCustomAudioConstraints(telnyxClient: TxClient) throws -> Call {
        let audioConstraints = AudioConstraints(
            echoCancellation: true,
            noiseSuppression: false,  // Disable noise suppression
            autoGainControl: true
        )
        
        let call = try telnyxClient.newCall(
            callerName: "Jane Smith",
            callerNumber: "+15559876543",
            destinationNumber: "+15552345678",
            callId: UUID(),
            audioConstraints: audioConstraints
        )
        
        return call
    }
    
    /// Example 3: Create a call with minimal audio processing
    func createCallWithMinimalProcessing(telnyxClient: TxClient) throws -> Call {
        let audioConstraints = AudioConstraints(
            echoCancellation: false,
            noiseSuppression: false,
            autoGainControl: false
        )
        
        let call = try telnyxClient.newCall(
            callerName: "Minimal Processing",
            callerNumber: "+15551112222",
            destinationNumber: "+15553334444",
            callId: UUID(),
            audioConstraints: audioConstraints
        )
        
        return call
    }
    
    /// Example 4: Create a call without audio constraints (uses WebRTC defaults)
    func createCallWithoutAudioConstraints(telnyxClient: TxClient) throws -> Call {
        let call = try telnyxClient.newCall(
            callerName: "Default WebRTC",
            callerNumber: "+15555556666",
            destinationNumber: "+15557778888",
            callId: UUID()
            // audioConstraints: nil - uses WebRTC defaults
        )
        
        return call
    }
}

/*
 USAGE EXAMPLES:
 
 // 1. Default audio constraints (echo cancellation, noise suppression, auto gain control all enabled)
 let example = AudioConstraintsExample()
 let call1 = try example.createCallWithDefaultAudioConstraints(telnyxClient: telnyxClient)
 
 // 2. Custom audio constraints
 let call2 = try example.createCallWithCustomAudioConstraints(telnyxClient: telnyxClient)
 
 // 3. Minimal audio processing
 let call3 = try example.createCallWithMinimalProcessing(telnyxClient: telnyxClient)
 
 // 4. No audio constraints (WebRTC defaults)
 let call4 = try example.createCallWithoutAudioConstraints(telnyxClient: telnyxClient)
 
 AUDIO CONSTRAINTS EXPLANATION:
 
 - echoCancellation: Reduces echo from audio being played back through speakers
 - noiseSuppression: Reduces background noise in the audio stream
 - autoGainControl: Automatically adjusts audio volume levels
 
 These constraints align with the W3C MediaTrackConstraints specification and
 are applied using WebRTC's "goog" prefixed constraints:
 - "googEchoCancellation"
 - "googNoiseSuppression" 
 - "googAutoGainControl"
 */