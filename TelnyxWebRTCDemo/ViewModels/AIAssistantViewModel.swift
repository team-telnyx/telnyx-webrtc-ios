//
//  AIAssistantViewModel.swift
//  TelnyxWebRTCDemo
//
//  Created by AI SWE Agent on 31/07/2025.
//

import SwiftUI
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
    
    private var txClient: TxClient?
    private var currentCall: Call?
    private var cancellables = Set<AnyCancellable>()
    
    var connectionStatusText: String {
        if isLoading {
            return "Connecting..."
        }
        return isConnected ? "Connected" : "Disconnected"
    }
    
    init() {
        setupTxClient()
    }
    
    deinit {
        disconnect()
    }
    
    private func setupTxClient() {
        txClient = TxClient()
        txClient?.delegate = self
        
        // Setup AI Assistant Manager delegate
        txClient?.aiAssistantManager.delegate = self
    }
    
    func connectToAssistant() {
        guard !targetIdInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a valid Target ID"
            return
        }
        
        isLoading = true
        loadingMessage = "Connecting to AI Assistant..."
        
        txClient?.anonymousLogin(
            targetId: targetIdInput.trimmingCharacters(in: .whitespacesAndNewlines),
            targetType: "ai_assistant"
        )
    }
    
    func disconnect() {
        isLoading = true
        loadingMessage = "Disconnecting..."
        
        // End any active calls first
        if let call = currentCall {
            call.hangup()
        }
        
        // Disconnect the client
        txClient?.disconnect()
        
        // Reset state
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
    }
    
    func startAssistantCall() {
        guard let client = txClient, isConnected else {
            errorMessage = "Not connected to AI Assistant"
            return
        }
        
        isLoading = true
        loadingMessage = "Starting call..."
        
        // Call the assistant using a generic target
        currentCall = client.newCall(callerName: "Anonymous User", 
                                   callerNumber: "anonymous", 
                                   destinationNumber: "assistant", 
                                   callId: UUID())
    }
    
    func endCall() {
        guard let call = currentCall else { return }
        
        isLoading = true
        loadingMessage = "Ending call..."
        
        call.hangup()
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