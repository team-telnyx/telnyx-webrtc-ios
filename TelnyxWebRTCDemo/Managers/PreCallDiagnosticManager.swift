//
//  PreCallDiagnosticManager.swift
//  TelnyxWebRTCDemo
//
//  Created by AI SWE Agent on 12/06/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import Foundation
import TelnyxRTC
import Combine

/// Manager class for handling Pre-call Diagnosis operations
/// Provides a centralized interface for starting diagnosis and handling state updates
class PreCallDiagnosticManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentState: PreCallDiagnosisState?
    @Published var isRunning: Bool = false
    
    // MARK: - Private Properties
    private var telnyxClient: TxClient?
    private var cancellables = Set<AnyCancellable>()
    
    // Pre-call diagnosis specific properties
    private var preCallDiagnosisCallId: UUID?
    private var preCallDiagnosisMetrics: [CallQualityMetrics] = []
    private var preCallDiagnosisTimer: Timer?
    
    // MARK: - Delegate
    weak var delegate: PreCallDiagnosticManagerDelegate?
    
    // MARK: - Initialization
    init() {
        setupStateObserver()
    }
    
    // MARK: - Public Methods
    
    /// Sets the TelnyxClient reference for diagnosis operations
    /// - Parameter client: The TxClient instance to use for diagnosis
    func setTelnyxClient(_ client: TxClient) {
        self.telnyxClient = client
    }
    
    /// Starts a pre-call diagnosis with the specified parameters
    /// - Parameters:
    ///   - destinationNumber: The destination number to test (default: "echo")
    ///   - duration: The duration of the test in seconds (default: 10.0)
    func startPreCallDiagnosis(destinationNumber: String = "echo", duration: TimeInterval = 10.0) {
        guard let client = telnyxClient else {
            updateState(.failed(TxError.clientNotReady))
            return
        }
        
        guard !isRunning else {
            print("PreCallDiagnosticManager: Diagnosis already running")
            return
        }
        
        do {
            // Clear previous metrics and timer
            preCallDiagnosisMetrics.removeAll()
            preCallDiagnosisTimer?.invalidate()
            
            // Generate unique call ID for this diagnosis
            let diagnosisCallId = UUID()
            preCallDiagnosisCallId = diagnosisCallId
            
            // Update state to started
            updateState(.started)
            
            // Create call options for the diagnosis call
            let callOptions = TxCallOptions(
                destinationNumber: destinationNumber,
                callerName: "PreCall Diagnosis",
                callerNumber: "PreCall Diagnosis",
                clientState: "diagnosis",
                customHeaders: [:]
            )
            
            // Start the diagnosis call
            try client.newCall(callOptions: callOptions, callId: diagnosisCallId)
            
            // Set up timer to end diagnosis after specified duration
            preCallDiagnosisTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?.endPreCallDiagnosis()
            }
            
        } catch {
            updateState(.failed(error))
        }
    }
    
    /// Stops the current pre-call diagnosis if running
    func stopPreCallDiagnosis() {
        guard isRunning else { return }
        endPreCallDiagnosis()
    }
    
    /// Updates the diagnosis state from external sources (e.g., delegate callbacks)
    /// - Parameter state: The new diagnosis state
    func updateState(_ state: PreCallDiagnosisState?) {
        DispatchQueue.main.async {
            self.currentState = state
            self.isRunning = (state == .started)
            self.delegate?.preCallDiagnosticManager(self, didUpdateState: state)
        }
    }
    
    /// Handles call state changes for pre-call diagnosis
    /// - Parameters:
    ///   - callId: The call ID
    ///   - callState: The new call state
    func handleCallStateChange(callId: UUID, callState: CallState) {
        guard callId == preCallDiagnosisCallId else { return }
        handlePreCallDiagnosisCallState(callState)
    }
    
    /// Collects call quality metrics for pre-call diagnosis
    /// - Parameter metrics: The call quality metrics to collect
    func collectMetrics(_ metrics: CallQualityMetrics) {
        guard preCallDiagnosisCallId != nil,
              isRunning else { return }
        
        preCallDiagnosisMetrics.append(metrics)
    }
    
    // MARK: - Private Methods
    
    private func endPreCallDiagnosis() {
        guard let callId = preCallDiagnosisCallId,
              let client = telnyxClient else {
            let error = TxError.clientNotReady
            updateState(.failed(error))
            return
        }
        
        // End the diagnosis call
        do {
            try client.endCall(callId: callId)
        } catch {
            print("PreCallDiagnosticManager: Error ending diagnosis call: \(error)")
        }
        
        // Process collected metrics
        processPreCallDiagnosisResults()
        
        // Clean up
        preCallDiagnosisTimer?.invalidate()
        preCallDiagnosisTimer = nil
        preCallDiagnosisCallId = nil
    }
    
    private func handlePreCallDiagnosisCallState(_ callState: CallState) {
        switch callState {
        case .done:
            // Call ended, process results
            processPreCallDiagnosisResults()
            preCallDiagnosisTimer?.invalidate()
            preCallDiagnosisTimer = nil
            preCallDiagnosisCallId = nil
            
        case .hangup, .destroy:
            // Call failed or was terminated
            let error = TxError.callFailed
            updateState(.failed(error))
            preCallDiagnosisTimer?.invalidate()
            preCallDiagnosisTimer = nil
            preCallDiagnosisCallId = nil
            
        default:
            // Other states, continue monitoring
            break
        }
    }
    
    private func processPreCallDiagnosisResults() {
        guard !preCallDiagnosisMetrics.isEmpty else {
            let error = TxError.callFailed
            updateState(.failed(error))
            return
        }
        
        do {
            // Calculate jitter statistics
            let jitterValues = preCallDiagnosisMetrics.map { $0.jitter }
            let jitterSummary = MetricSummary(
                min: jitterValues.min() ?? 0.0,
                max: jitterValues.max() ?? 0.0,
                avg: jitterValues.reduce(0, +) / Double(jitterValues.count)
            )
            
            // Calculate RTT statistics
            let rttValues = preCallDiagnosisMetrics.map { $0.rtt }
            let rttSummary = MetricSummary(
                min: rttValues.min() ?? 0.0,
                max: rttValues.max() ?? 0.0,
                avg: rttValues.reduce(0, +) / Double(rttValues.count)
            )
            
            // Calculate average MOS
            let mosValues = preCallDiagnosisMetrics.map { $0.mos }
            let averageMOS = mosValues.reduce(0, +) / Double(mosValues.count)
            
            // Determine overall quality based on frequency of quality ratings
            let qualityFrequency = Dictionary(grouping: preCallDiagnosisMetrics) { $0.quality }
            let mostFrequentQuality = qualityFrequency.max { $0.value.count < $1.value.count }?.key ?? .unknown
            
            // Get packet and byte statistics from the last metric (cumulative)
            let lastMetric = preCallDiagnosisMetrics.last!
            
            // Create mock ICE candidates (in a real implementation, these would come from WebRTC)
            let iceCandidates: [ICECandidate] = [
                ICECandidate(id: "candidate-1", type: "host", protocol: "udp", address: "192.168.1.100", port: 54400, priority: 2113667326),
                ICECandidate(id: "candidate-2", type: "srflx", protocol: "udp", address: "203.0.113.1", port: 54401, priority: 1686052606)
            ]
            
            let diagnosis = PreCallDiagnosis(
                mos: averageMOS,
                quality: mostFrequentQuality,
                jitter: jitterSummary,
                rtt: rttSummary,
                bytesSent: lastMetric.bytesSent,
                bytesReceived: lastMetric.bytesReceived,
                packetsSent: lastMetric.packetsSent,
                packetsReceived: lastMetric.packetsReceived,
                iceCandidates: iceCandidates
            )
            
            updateState(.completed(diagnosis))
            
        } catch {
            updateState(.failed(error))
        }
    }
    
    private func setupStateObserver() {
        $currentState
            .sink { [weak self] state in
                guard let self = self else { return }
                
                switch state {
                case .started:
                    print("PreCallDiagnosticManager: Diagnosis started")
                case .completed(let diagnosis):
                    print("PreCallDiagnosticManager: Diagnosis completed with MOS: \(diagnosis.mos)")
                case .failed(let error):
                    print("PreCallDiagnosticManager: Diagnosis failed with error: \(error?.localizedDescription ?? "Unknown error")")
                case .none:
                    print("PreCallDiagnosticManager: Diagnosis state reset")
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - PreCallDiagnosticManagerDelegate Protocol

protocol PreCallDiagnosticManagerDelegate: AnyObject {
    /// Called when the pre-call diagnosis state changes
    /// - Parameters:
    ///   - manager: The PreCallDiagnosticManager instance
    ///   - state: The new diagnosis state
    func preCallDiagnosticManager(_ manager: PreCallDiagnosticManager, didUpdateState state: PreCallDiagnosisState?)
}