//
//  AIAssistantViewModel.swift
//  TelnyxWebRTCDemo
//
//  Created by AI SWE Agent on 31/07/2025.
//

import SwiftUI
import UIKit
import TelnyxRTC
import Combine

class AIAssistantViewModel: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var isLoading: Bool = false
    @Published var loadingMessage: String = ""
    @Published var sessionId: String?
    @Published var callState: CallState = .NEW
    @Published var showTargetIdInput: Bool = false
    @Published var targetIdInput: String = ""
    @Published var showTranscriptDialog: Bool = false
    @Published var transcriptions: [TranscriptionItem] = []
    @Published var widgetSettings: WidgetSettings?
    @Published var errorMessage: String?
    
    private var currentCall: Call?
    private var cancellables = Set<AnyCancellable>()
    private var originalVoipDelegate: VoIPDelegate?
    private var hasSetupDelegates = false
    private var appDelegate: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    var connectionStatusText: String {
        if isLoading {
            return "Connecting..."
        }
        return isConnected ? "Connected" : "Disconnected"
    }
    
    init() {
        // Don't set up delegates immediately to avoid retain cycles
        // They will be set up when actually needed
    }
    
    deinit {
        print("AIAssistantViewModel deinit called")
        // Force immediate cleanup to break retain cycles
        cleanupAIAssistantState()
    }
    
    private func setupAIAssistantDelegate() {
        // Only setup once to avoid multiple delegate assignments
        guard !hasSetupDelegates else { return }
        
        // Store the original VoIP delegate before overriding
        originalVoipDelegate = appDelegate.voipDelegate
        
        // Setup AI Assistant Manager delegate on the existing client
        appDelegate.telnyxClient?.aiAssistantManager.delegate = self
        appDelegate.voipDelegate = self
        
        hasSetupDelegates = true
    }
    
    private func cleanupAIAssistantState() {
        print("AIAssistantViewModel cleanupAIAssistantState called")
        
        // Cancel all Combine subscriptions first
        cancellables.removeAll()
        
        // Force cleanup of delegates regardless of hasSetupDelegates flag
        appDelegate.telnyxClient?.aiAssistantManager.delegate = nil
        
        // Clear VoIP delegate if it's pointing to self
        if appDelegate.voipDelegate === self {
            if let originalDelegate = originalVoipDelegate {
                appDelegate.voipDelegate = originalDelegate
            } else {
                appDelegate.voipDelegate = nil
            }
        }
        
        // Clear all references immediately
        currentCall = nil
        originalVoipDelegate = nil
        hasSetupDelegates = false
        
        // Clean up published properties synchronously to avoid retaining self
        isConnected = false
        isLoading = false
        sessionId = nil
        callState = .NEW
        transcriptions.removeAll()
        widgetSettings = nil
        targetIdInput = ""
        errorMessage = nil
    }
    
    private func restoreOriginalVoipDelegate() {
        // Restore the original VoIP delegate if we stored one
        // This method is safe to call multiple times
        print("AIAssistantViewModel restoreOriginalVoipDelegate called")
        
        if let originalDelegate = originalVoipDelegate {
            print("AIAssistantViewModel restoring original delegate: \(originalDelegate)")
            appDelegate.voipDelegate = originalDelegate
            originalVoipDelegate = nil
        } else {
            // If no original delegate was stored, at least clear self to break retain cycle
            if appDelegate.voipDelegate === self {
                print("AIAssistantViewModel clearing self as delegate")
                appDelegate.voipDelegate = nil
            } else {
                print("AIAssistantViewModel delegate is not self, no action needed")
            }
        }
    }
    
    func connectToAssistant() {
        guard !targetIdInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a valid Target ID"
            return
        }
        
        // Set up delegates only when actually connecting
        setupAIAssistantDelegate()
        
        isLoading = true
        loadingMessage = "Connecting to AI Assistant..."
        
        appDelegate.telnyxClient?.anonymousLogin(
            targetId: targetIdInput.trimmingCharacters(in: .whitespacesAndNewlines),
            targetType: "ai_assistant"
        )
    }
    
    func disconnect() {
        isLoading = true
        loadingMessage = "Disconnecting from AI Assistant..."
        
        // End any active calls first
        if let call = currentCall {
            call.hangup()
        }
        
        // Don't disconnect the shared client, just clean up AI Assistant state
        cleanupAIAssistantState()
    }
    
    func startAssistantCall() {
        guard isConnected else {
            errorMessage = "Not connected to AI Assistant"
            return
        }
        
        isLoading = true
        loadingMessage = "Starting call..."
        
        // Generate a UUID for the call and use CallKit like regular calls
        let callUUID = UUID()
        
        // Use AppDelegate's CallKit integration to start the call properly
        appDelegate.executeStartCallAction(uuid: callUUID, handle: "AI Assistant")
    }
    
    func endCall() {
        guard let call = currentCall else { return }
        
        isLoading = true
        loadingMessage = "Ending call..."
        
        // Use CallKit to end the call properly
        if let callId = call.callInfo?.callId {
            appDelegate.executeEndCallAction(uuid: callId)
        } else {
            // Fallback to direct hangup if no CallKit UUID
            call.hangup()
        }
    }
    
    func restoreHomeDelegate() {
        // Public method to restore the original delegate when view is dismissed
        // This must break all retain cycles immediately
        print("AIAssistantViewModel restoreHomeDelegate called")
        
        // Only clean up if we actually set up delegates
        guard hasSetupDelegates else { 
            print("AIAssistantViewModel restoreHomeDelegate - delegates not set up, skipping")
            return 
        }
        
        // Clear AI Assistant delegate first to break retain cycles
        appDelegate.telnyxClient?.aiAssistantManager.delegate = nil
        
        // Restore the original VoIP delegate
        restoreOriginalVoipDelegate()
        
        // Clear any remaining state that might hold references
        currentCall = nil
        cancellables.removeAll()
        
        // Mark that delegates are no longer set up
        hasSetupDelegates = false
        
        print("AIAssistantViewModel restoreHomeDelegate completed")
    }
    
    func sendMessage(_ message: String) {
        // TODO: Implement conversation messaging when SDK supports it
        // For now, this is a placeholder for future implementation
        print("Sending message: \(message)")
        
        // Create a mock transcription item for the user message
        let userTranscription = TranscriptionItem(
            id: UUID().uuidString,
            timestamp: Date(),
            speaker: "user",
            text: message
        )
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.transcriptions.append(userTranscription)
        }
    }
}


// MARK: - AIAssistantManagerDelegate
extension AIAssistantViewModel: AIAssistantManagerDelegate {
    func onAIConversationMessage(_ message: [String : Any]) {
        // Handle AI conversation messages
        print("AI Conversation Message: \(message)")
    }
    
    func onRingingAckReceived(callId: String) {
        // Handle ringing acknowledgment
        print("Ringing Ack Received for call: \(callId)")
    }
    
    func onAIAssistantConnectionStateChanged(isConnected: Bool, targetId: String?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isConnected = isConnected
            if !isConnected {
                self.sessionId = nil
                self.callState = .NEW
                self.currentCall = nil
            }
        }
    }
    
    func onTranscriptionUpdated(_ transcriptions: [TranscriptionItem]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.transcriptions = transcriptions
        }
    }
    
    func onWidgetSettingsUpdated(_ settings: WidgetSettings) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.widgetSettings = settings
        }
    }
}

// MARK: - VoIPDelegate
extension AIAssistantViewModel: VoIPDelegate {
    
    func onPushDisabled(success: Bool, message: String) {
        //
    }
    
    func onPushCall(call: TelnyxRTC.Call) {
        //
    }
    
    
    func onRemoteSessionReceived(sessionId: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.sessionId = sessionId
        }
    }
    
    func onSocketConnected() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isConnected = true
            self.isLoading = false
            self.loadingMessage = ""
        }
    }
    
    func onSocketDisconnected() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isConnected = false
            self.isLoading = false
            self.sessionId = nil
            self.callState = .NEW
            self.currentCall = nil
        }
    }
    
    func onClientError(error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
    
    func onClientReady() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isConnected = true
            self.isLoading = false
            self.loadingMessage = ""
        }
    }
    
    func onSessionUpdated(sessionId: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.sessionId = sessionId
        }
    }
    
    func onIncomingCall(call: Call) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentCall = call
            self.callState = call.callState
        }
    }
    
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.callState = callState
            self.isLoading = false
            
            // Clear transcriptions when call ends
            if case .DONE = callState {
                self.currentCall = nil
                // Don't clear transcriptions immediately to allow user to review
            }
        }
    }
    
    func onCallQualityMetricsUpdated(metrics: CallQualityMetrics, callId: UUID) {
        // Handle call quality metrics if needed
    }
    func onRemoteCallEnded(callId: UUID, reason: TelnyxRTC.CallTerminationReason?) {

    }
    
    func executeCall(callUUID: UUID, completionHandler: @escaping (Call?) -> Void) {
        do {
            // Create the assistant call using the shared client
            let call = try appDelegate.telnyxClient?.newCall(
                callerName: "Anonymous User",
                callerNumber: "anonymous",
                destinationNumber: "assistant",
                callId: callUUID
            )
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.currentCall = call
                if call != nil {
                    print("AIAssistantViewModel:: executeCall() successful")
                } else {
                    print("AIAssistantViewModel:: executeCall() failed")
                    self.errorMessage = "Failed to start assistant call"
                }
            }
            
            completionHandler(call)
        } catch let error {
            print("AIAssistantViewModel:: executeCall Error \(error)")
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            completionHandler(nil)
        }
    }
}
