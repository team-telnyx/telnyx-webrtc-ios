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
            updateState(.started)
            try client.startPreCallDiagnosis(
                destinationNumber: destinationNumber,
                duration: duration
            )
        } catch {
            updateState(.failed(error))
        }
    }
    
    /// Stops the current pre-call diagnosis if running
    func stopPreCallDiagnosis() {
        guard isRunning else { return }
        
        // Note: TxClient doesn't have a stop method, so we just reset our state
        updateState(nil)
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
    
    // MARK: - Private Methods
    
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