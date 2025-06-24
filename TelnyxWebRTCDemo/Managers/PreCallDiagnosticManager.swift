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
import UIKit
import CallKit


/// Manager class for handling Pre-call Diagnosis operations
/// Provides a centralized interface for starting diagnosis and handling state updates
class PreCallDiagnosticManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentState: PreCallDiagnosisState?
    @Published var isRunning: Bool = false
    
    static let shared = PreCallDiagnosticManager()

    
    // MARK: - Private Properties
    private var telnyxClient: TxClient?
    private var cancellables = Set<AnyCancellable>()
    
    // Pre-call diagnosis specific properties
    private var preCallDiagnosisCallId: UUID?
    private var callQualitymetricsData: [CallQualityMetrics] = []
    private var preCallDiagnosisTimer: Timer?
    private var diagnosisCall:Call?
    
    // MARK: - Delegate
    weak var delegate: PreCallDiagnosticManagerDelegate?
        
    var appDelegate: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    // MARK: - Initialization
     private init() {
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
    func startPreCallDiagnosis(destinationNumber: String = "", duration: TimeInterval = 10.0) {
        guard let client = telnyxClient else {
            updateState(.failed("Client not set"))
            return
        }
        
        guard !isRunning else {
            print("PreCallDiagnosticManager: Diagnosis already running")
            return
        }
        
        let callUUID = UUID()
        preCallDiagnosisCallId = callUUID
        
        do {
            // Clear previous metrics and timer
            callQualitymetricsData.removeAll()
            preCallDiagnosisTimer?.invalidate()
            
            
            // Update state to started
            updateState(.started)
            
            appDelegate.executeStartCallAction(uuid: callUUID, handle: "Pre-Call Diagnosis")
   
            // Start the diagnosis call
            diagnosisCall = try client.newCall(callerName:  "",
                                                 callerNumber:"",
                                                 destinationNumber: destinationNumber,
                                                 callId: callUUID,debug: true)
            
            appDelegate.currentCall = diagnosisCall
            self.appDelegate.isCallOutGoing = true
            
            // Set up timer to end diagnosis after specified duration
            preCallDiagnosisTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?.endPreCallDiagnosis()
            }
            
        } catch {
            updateState(.failed("Precall Diagnosis Failed: \(error.localizedDescription)"))
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
        
        callQualitymetricsData.append(metrics)
    }
    
    // MARK: - Private Methods
    
    private func endPreCallDiagnosis() {
        guard let _ = preCallDiagnosisCallId,
              let _ = telnyxClient else {
            updateState(.failed(""))
            return
        }
        
        // End the diagnosis call
        diagnosisCall?.hangup()

        // Process collected metrics
        processPreCallDiagnosisResults()
        
        // Clean up
        preCallDiagnosisTimer?.invalidate()
        preCallDiagnosisTimer = nil
        preCallDiagnosisCallId = nil
    }
    
    private func handlePreCallDiagnosisCallState(_ callState: CallState) {
        switch callState {
        case .DONE(_):
            // Call ended, process results
            processPreCallDiagnosisResults()
            preCallDiagnosisTimer?.invalidate()
            preCallDiagnosisTimer = nil
            preCallDiagnosisCallId = nil
            
        case .DROPPED(let reason):
            // Call failed or was terminated
            updateState(.failed(reason.rawValue))
            preCallDiagnosisTimer?.invalidate()
            preCallDiagnosisTimer = nil
            preCallDiagnosisCallId = nil
            
        default:
            // Other states, continue monitoring
            break
        }
    }
    
    private func processPreCallDiagnosisResults() {
        guard !callQualitymetricsData.isEmpty else {
            updateState(.failed("No Metrics to Show"))
            return
        }
        
        // Calculate jitter statistics
        let jitterValues = callQualitymetricsData.map { $0.jitter }
        let jitterSummary = MetricSummary(
            min: jitterValues.min() ?? 0.0,
            max: jitterValues.max() ?? 0.0,
            avg: jitterValues.reduce(0, +) / Double(jitterValues.count)
        )
        
        // Calculate RTT statistics
        let rttValues = callQualitymetricsData.map { $0.rtt }
        let rttSummary = MetricSummary(
            min: rttValues.min() ?? 0.0,
            max: rttValues.max() ?? 0.0,
            avg: rttValues.reduce(0, +) / Double(rttValues.count)
        )
        
        // Calculate average MOS
        let mosValues = callQualitymetricsData.map { $0.mos }
        let averageMOS = mosValues.reduce(0, +) / Double(mosValues.count)
        
        // Determine overall quality based on frequency of quality ratings
        let qualityFrequency = Dictionary(grouping: callQualitymetricsData) { $0.quality }
        let mostFrequentQuality = qualityFrequency.max { $0.value.count < $1.value.count }?.key ?? .unknown
        
        // Get packet and byte statistics from the last metric (cumulative)
        let lastMetric = callQualitymetricsData.last!
        
        print("Last Metric : \(lastMetric)")

        let bytesSent = (lastMetric.outboundAudio?["bytesSent"] as? NSNumber)?.int64Value ?? 0
        let bytesReceived = (lastMetric.inboundAudio?["bytesReceived"] as? NSNumber)?.int64Value ?? 0
        let packetsSent = (lastMetric.outboundAudio?["packetsSent"] as? NSNumber)?.int64Value ?? 0
        let packetsReceived = (lastMetric.inboundAudio?["packetsReceived"] as? NSNumber)?.int64Value ?? 0

 

        let diagnosis = PreCallDiagnosis(
            mos: averageMOS,
            quality: mostFrequentQuality,
            jitter: jitterSummary,
            rtt: rttSummary,
            bytesSent: bytesSent,
            bytesReceived: bytesReceived,
            packetsSent: packetsSent,
            packetsReceived: packetsReceived,
            iceCandidates: []
        )
        
        updateState(.completed(diagnosis))
    }
    
    private func setupStateObserver() {
        $currentState
            .sink { [weak self] state in
                guard self != nil else { return }
                
                switch state {
                case .started:
                    print("PreCallDiagnosticManager: Diagnosis started")
                case .completed(let diagnosis):
                    print("PreCallDiagnosticManager: Diagnosis completed with MOS: \(diagnosis.mos)")
                case .failed(let error):
                    print("PreCallDiagnosticManager: Diagnosis failed with error: \(String(describing: error))")
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
