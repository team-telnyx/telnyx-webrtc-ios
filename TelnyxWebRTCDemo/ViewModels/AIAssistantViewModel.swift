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
        setupAIAssistantDelegate()
    }
    
    deinit {
        cleanupAIAssistantState()
    }
    
    private func setupAIAssistantDelegate() {
        // Setup AI Assistant Manager delegate on the existing client
        appDelegate.telnyxClient?.aiAssistantManager.delegate = self
    }
    
    private func cleanupAIAssistantState() {
        // Only clean up AI Assistant specific state, don't disconnect the shared client
        DispatchQueue.main.async {
            self.isConnected = false
            self.isLoading = false
            self.sessionId = nil
            self.callState = .NEW
            self.currentCall = nil
            self.transcriptions.removeAll()
            self.widgetSettings = nil
            self.targetIdInput = ""
        }
        
        // Remove AI Assistant delegate to prevent callbacks
        appDelegate.telnyxClient?.aiAssistantManager.delegate = nil
    }
    
    func connectToAssistant() {
        guard !targetIdInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a valid Target ID"
            return
        }
        
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
        
        // Set up the VoIP delegate to handle the call execution
        appDelegate.voipDelegate = self
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
        
        DispatchQueue.main.async {
            self.transcriptions.append(userTranscription)
        }
    }
}

// MARK: - TxClientDelegate
extension AIAssistantViewModel: TxClientDelegate {
    func onPushDisabled(success: Bool, message: String) {
        //
    }
    
    func onRemoteCallEnded(callId: UUID, reason: TelnyxRTC.CallTerminationReason?) {
        //
    }
    
    func onPushCall(call: TelnyxRTC.Call) {
        //
    }
    
    func onRemoteSessionReceived(sessionId: String) {
        DispatchQueue.main.async {
            self.sessionId = sessionId
        }
    }
    
    func onSocketConnected() {
        DispatchQueue.main.async {
            self.isConnected = true
            self.isLoading = false
            self.loadingMessage = ""
        }
    }
    
    func onSocketDisconnected() {
        DispatchQueue.main.async {
            self.isConnected = false
            self.isLoading = false
            self.sessionId = nil
            self.callState = .NEW
            self.currentCall = nil
        }
    }
    
    func onClientError(error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
    
    func onClientReady() {
        DispatchQueue.main.async {
            self.isConnected = true
            self.isLoading = false
            self.loadingMessage = ""
        }
    }
    
    func onSessionUpdated(sessionId: String) {
        DispatchQueue.main.async {
            self.sessionId = sessionId
        }
    }
    
    func onIncomingCall(call: Call) {
        DispatchQueue.main.async {
            self.currentCall = call
            self.callState = call.callState
        }
    }
    
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        DispatchQueue.main.async {
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
        DispatchQueue.main.async {
            self.isConnected = isConnected
            if !isConnected {
                self.sessionId = nil
                self.callState = .NEW
                self.currentCall = nil
            }
        }
    }
    
    func onTranscriptionUpdated(_ transcriptions: [TranscriptionItem]) {
        DispatchQueue.main.async {
            self.transcriptions = transcriptions
        }
    }
    
    func onWidgetSettingsUpdated(_ settings: WidgetSettings) {
        DispatchQueue.main.async {
            self.widgetSettings = settings
        }
    }
}

// MARK: - VoIPDelegate
extension AIAssistantViewModel: VoIPDelegate {
    func onSocketConnected() {
        // Handle socket connection if needed for AI Assistant
    }
    
    func onSocketDisconnected() {
        // Handle socket disconnection if needed for AI Assistant
    }
    
    func onClientError(error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
    
    func onClientReady() {
        // Handle client ready if needed for AI Assistant
    }
    
    func onSessionUpdated(sessionId: String) {
        // Handle session update if needed for AI Assistant
    }
    
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        // This is handled by the TxClientDelegate extension
    }
    
    func onIncomingCall(call: Call) {
        // Handle incoming call if needed for AI Assistant
    }
    
    func onRemoteCallEnded(callId: UUID, reason: CallTerminationReason?) {
        // Handle remote call end if needed for AI Assistant
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
            
            DispatchQueue.main.async {
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
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            completionHandler(nil)
        }
    }
}
