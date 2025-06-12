//
//  PreCallDiagnosisExample.swift
//  TelnyxRTC
//
//  Created by AI SWE Agent on 12/06/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import Foundation
import TelnyxRTC

/// Example implementation showing how to use the Pre-call Diagnosis feature
class PreCallDiagnosisExample: TxClientDelegate {
    
    private var txClient: TxClient?
    
    func setupClient() {
        // Initialize the TxClient
        txClient = TxClient()
        txClient?.delegate = self
        
        // Configure and connect (example configuration)
        let config = TxConfig(
            sipUser: "your_sip_user",
            password: "your_password",
            pushDeviceToken: "your_push_token",
            ringtone: "your_ringtone",
            ringBackTone: "your_ringback_tone",
            logLevel: .all
        )
        
        do {
            try txClient?.connect(txConfig: config)
        } catch {
            print("Failed to connect: \(error)")
        }
    }
    
    func startPreCallDiagnosis() {
        guard let client = txClient else {
            print("TxClient not initialized")
            return
        }
        
        do {
            // Start pre-call diagnosis with a test number
            // This will make a test call for 10 seconds and collect metrics
            try client.startPreCallDiagnosis(
                testNumber: "+18005551234", // Replace with your test number
                callerName: "Pre-call Test",
                callerNumber: "+15551234567", // Replace with your caller number
                duration: 10.0 // Test for 10 seconds
            )
            
            print("Pre-call diagnosis started...")
            
        } catch {
            print("Failed to start pre-call diagnosis: \(error)")
        }
    }
    
    // MARK: - TxClientDelegate Methods
    
    func onSocketConnected() {
        print("Socket connected")
    }
    
    func onSocketDisconnected() {
        print("Socket disconnected")
    }
    
    func onClientReady() {
        print("Client ready - you can now start pre-call diagnosis")
        // Optionally start pre-call diagnosis automatically when client is ready
        // startPreCallDiagnosis()
    }
    
    func onClientError(error: Error) {
        print("Client error: \(error)")
    }
    
    func onSessionUpdated(sessionId: String) {
        print("Session updated: \(sessionId)")
    }
    
    func onIncomingCall(call: Call) {
        print("Incoming call: \(call.callInfo?.callId ?? UUID())")
    }
    
    func onRemoteCallEnded(callId: UUID, reason: CallTerminationReason?) {
        print("Remote call ended: \(callId), reason: \(reason?.rawValue ?? "unknown")")
    }
    
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        print("Call state updated: \(callState), callId: \(callId)")
    }
    
    func onPushCall(call: Call) {
        print("Push call: \(call.callInfo?.callId ?? UUID())")
    }
    
    // MARK: - Pre-call Diagnosis Delegate Method
    
    func onPreCallDiagnosisStateUpdated(state: PreCallDiagnosisState) {
        switch state {
        case .started:
            print("🔍 Pre-call diagnosis started")
            
        case .completed(let diagnosis):
            print("✅ Pre-call diagnosis completed!")
            print("📊 Results:")
            print("   MOS Score: \(diagnosis.mos)")
            print("   Quality: \(diagnosis.quality.rawValue)")
            print("   Jitter: min=\(diagnosis.jitter.min)s, max=\(diagnosis.jitter.max)s, avg=\(diagnosis.jitter.avg)s")
            print("   RTT: min=\(diagnosis.rtt.min)s, max=\(diagnosis.rtt.max)s, avg=\(diagnosis.rtt.avg)s")
            print("   Bytes sent: \(diagnosis.bytesSent)")
            print("   Bytes received: \(diagnosis.bytesReceived)")
            print("   Packets sent: \(diagnosis.packetsSent)")
            print("   Packets received: \(diagnosis.packetsReceived)")
            print("   ICE candidates: \(diagnosis.iceCandidates.count)")
            
            // Convert to dictionary for easy serialization
            let diagnosisDict = diagnosis.toDictionary()
            print("   Dictionary representation: \(diagnosisDict)")
            
            // You can now use this data to:
            // 1. Display to the user
            // 2. Send to your analytics service
            // 3. Make decisions about call quality expectations
            // 4. Recommend network improvements
            
            handleDiagnosisResults(diagnosis)
            
        case .failed(let error):
            print("❌ Pre-call diagnosis failed: \(error?.localizedDescription ?? "Unknown error")")
            
            // Handle the failure - you might want to:
            // 1. Retry the diagnosis
            // 2. Show an error message to the user
            // 3. Fall back to making a call without diagnosis
        }
    }
    
    private func handleDiagnosisResults(_ diagnosis: PreCallDiagnosis) {
        // Example of how to interpret and act on the results
        
        if diagnosis.mos >= 4.0 {
            print("🟢 Excellent call quality expected")
        } else if diagnosis.mos >= 3.0 {
            print("🟡 Good call quality expected")
        } else if diagnosis.mos >= 2.0 {
            print("🟠 Fair call quality - may experience some issues")
        } else {
            print("🔴 Poor call quality expected - consider checking network")
        }
        
        // Check for high jitter
        if diagnosis.jitter.avg > 0.030 { // 30ms
            print("⚠️ High jitter detected - audio may be choppy")
        }
        
        // Check for high RTT
        if diagnosis.rtt.avg > 0.150 { // 150ms
            print("⚠️ High latency detected - may experience delays")
        }
        
        // Check packet loss (simplified calculation)
        let packetLossRate = Double(diagnosis.packetsSent - diagnosis.packetsReceived) / Double(diagnosis.packetsSent)
        if packetLossRate > 0.05 { // 5% packet loss
            print("⚠️ Packet loss detected: \(String(format: "%.1f", packetLossRate * 100))%")
        }
    }
}

// MARK: - Usage Example

/*
 To use this example:
 
 1. Create an instance of PreCallDiagnosisExample
 2. Call setupClient() to initialize and connect the TxClient
 3. Once the client is ready, call startPreCallDiagnosis()
 4. Monitor the onPreCallDiagnosisStateUpdated delegate method for results
 
 Example:
 
 let example = PreCallDiagnosisExample()
 example.setupClient()
 
 // Wait for onClientReady callback, then:
 example.startPreCallDiagnosis()
 
 */