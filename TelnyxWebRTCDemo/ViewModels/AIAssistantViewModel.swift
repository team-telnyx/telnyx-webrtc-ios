//
//  AIAssistantViewModel.swift
//  TelnyxWebRTCDemo
//
//  Created by AI SWE Agent on 31/07/2025.
//

import SwiftUI
import UIKit
import TelnyxRTC

class AIAssistantViewModel: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var isLoading: Bool = false
    @Published var loadingMessage: String = ""
    @Published var sessionId: String?
    @Published var callState: CallState = .NEW
    @Published var targetIdInput: String = ""
    @Published var showTranscriptDialog: Bool = false
    @Published var transcriptions: [TranscriptionItem] = []
    @Published var widgetSettings: WidgetSettings?
    @Published var errorMessage: String?
    
    private let lastTargetIdKey = "LastAIAssistantTargetId"
    
    private var currentCall: Call?
    private var cancellables: [Any] = []
    private var originalVoipDelegate: VoIPDelegate?
    private var hasSetupDelegates = false
    private var appDelegate: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    // MARK: - Real-time Transcript Updates
    private var transcriptUpdateCancellable: TranscriptCancellable?
    private var transcriptItemCancellable: TranscriptCancellable?
    
    var connectionStatusText: String {
        if isLoading {
            return "Connecting..."
        }
        return isConnected ? "Connected" : "Disconnected"
    }
    
    init() {
        // Load the last successful targetId from UserDefaults
        loadLastTargetId()
        
        // Don't set up delegates immediately to avoid retain cycles
        // They will be set up when actually needed
    }
    
    private func loadLastTargetId() {
        if let savedTargetId = UserDefaults.standard.string(forKey: lastTargetIdKey) {
            targetIdInput = savedTargetId
        }
    }
    
    private func saveLastTargetId(_ targetId: String) {
        UserDefaults.standard.set(targetId, forKey: lastTargetIdKey)
    }
    
    deinit {
        print("AIAssistantViewModel deinit called")
        // Force immediate cleanup to break retain cycles
        cleanupAIAssistantState()
    }
    
    private func setupAIAssistantDelegate() {
        print("AIAssistantViewModel setupAIAssistantDelegate called - hasSetupDelegates: \(hasSetupDelegates)")
        
        // Only setup once to avoid multiple delegate assignments
        guard !hasSetupDelegates else { 
            print("AIAssistantViewModel setupAIAssistantDelegate - delegates already set up, just reassigning AI Assistant delegate")
            // Re-assign AI Assistant delegate in case it was cleared during disconnect
            appDelegate.telnyxClient?.aiAssistantManager.delegate = self
            setupRealtimeTranscriptUpdates()
            return 
        }
        
        // Store the original VoIP delegate before overriding
        originalVoipDelegate = appDelegate.voipDelegate
        print("AIAssistantViewModel setupAIAssistantDelegate - storing original delegate: \(String(describing: originalVoipDelegate))")
        
        // Setup AI Assistant Manager delegate on the existing client
        appDelegate.telnyxClient?.aiAssistantManager.delegate = self
        appDelegate.voipDelegate = self
        
        // Setup real-time transcript updates (Android compatibility)
        setupRealtimeTranscriptUpdates()
        
        hasSetupDelegates = true
        print("AIAssistantViewModel setupAIAssistantDelegate completed - delegates set up successfully")
    }
    
    private func setupRealtimeTranscriptUpdates() {
        guard let aiAssistantManager = appDelegate.telnyxClient?.aiAssistantManager else { return }
        
        // Subscribe to real-time transcript updates
        transcriptUpdateCancellable = aiAssistantManager.subscribeToTranscriptUpdates { [weak self] updatedTranscriptions in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.transcriptions = updatedTranscriptions
            }
        }
        
        // Subscribe to individual transcript item updates
        transcriptItemCancellable = aiAssistantManager.subscribeToTranscriptItemUpdates { [weak self] newItem in
            guard let self = self else { return }
            print("AIAssistantViewModel:: Received individual transcript update: \(newItem.content)")
            // Individual item updates are handled by the array update above
        }
        
        print("AIAssistantViewModel:: Real-time transcript updates setup completed")
    }
    
    private func cleanupAIAssistantState() {
        print("AIAssistantViewModel cleanupAIAssistantState called - full cleanup")
        
        // Cancel all subscriptions first
        cancellables.removeAll()
        
        // Cancel real-time transcript subscriptions
        transcriptUpdateCancellable?.cancel()
        transcriptItemCancellable?.cancel()
        transcriptUpdateCancellable = nil
        transcriptItemCancellable = nil
        
        // Force cleanup of delegates regardless of hasSetupDelegates flag
        appDelegate.telnyxClient?.aiAssistantManager.delegate = nil
        
        // Clear VoIP delegate if it's pointing to self
        if appDelegate.voipDelegate === self {
            if let originalDelegate = originalVoipDelegate {
                print("AIAssistantViewModel cleanupAIAssistantState - restoring original delegate: \(originalDelegate)")
                appDelegate.voipDelegate = originalDelegate
            } else {
                print("AIAssistantViewModel cleanupAIAssistantState - clearing self as delegate")
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
        
        print("AIAssistantViewModel cleanupAIAssistantState completed - full cleanup done")
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
        
        print("AIAssistantViewModel connectToAssistant called")
        
        // Set up delegates - this will work for both first connection and reconnection
        setupAIAssistantDelegate()
        
        // Clear any previous error messages
        errorMessage = nil
        
        isLoading = true
        loadingMessage = "Connecting to AI Assistant..."
        
        // Use the new connectWithAIAssistant method that properly establishes connection
        appDelegate.telnyxClient?.anonymousLogin(
            targetId: targetIdInput.trimmingCharacters(in: .whitespacesAndNewlines),
            targetType: "ai_assistant",
            targetVersionId: nil
        )
    }
    
    func disconnect() {
        print("AIAssistantViewModel disconnect called")
        isLoading = true
        loadingMessage = "Disconnecting from AI Assistant..."
        
        // End any active calls first
        if let call = currentCall {
            call.hangup()
        }
        
        // Disconnect from the client completely to ensure clean state
        appDelegate.telnyxClient?.disconnect()
        
        // Clean up AI Assistant state but keep delegates for potential reconnection
        cleanupAIAssistantStateForDisconnect()
    }
    
    private func cleanupAIAssistantStateForDisconnect() {
        print("AIAssistantViewModel cleanupAIAssistantStateForDisconnect called")
        
        // Clear current call and connection state
        currentCall = nil
        
        // Clean up published properties synchronously
        isConnected = false
        isLoading = false
        sessionId = nil
        callState = .NEW
        transcriptions.removeAll()
        widgetSettings = nil
        errorMessage = nil
        
        // DON'T clear the aiAssistantManager delegate - keep it active for reconnection events
        // This is the key difference from full cleanup
        
        print("AIAssistantViewModel cleanupAIAssistantStateForDisconnect completed - delegates kept active for reconnection")
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
        print("AIAssistantViewModel:: Sending text message: \(message)")
        
        guard let aiAssistantManager = appDelegate.telnyxClient?.aiAssistantManager else {
            errorMessage = "AI Assistant Manager not available"
            return
        }
        
        // Use the new mixed-mode communication method
        let success = aiAssistantManager.sendAIAssistantMessage(message)
        
        if !success {
            errorMessage = "Failed to send message to AI Assistant"
        }
    }
    
    // MARK: - Mixed-mode Communication (Android compatibility)
    
    /// Send a text message to AI Assistant during active call
    /// - Parameter message: The text message to send
    func sendTextMessage(_ message: String) {
        sendMessage(message)
    }
    
    /// Get current transcriptions (Android compatibility method)
    /// - Returns: Current array of transcription items
    func getCurrentTranscriptions() -> [TranscriptionItem] {
        return appDelegate.telnyxClient?.aiAssistantManager.getTranscriptions() ?? []
    }
    
    /// Check if transcriptions are available
    /// - Returns: True if transcriptions are available, false otherwise
    var hasTranscriptions: Bool {
        return !transcriptions.isEmpty
    }
    
    /// Get the latest transcription item
    /// - Returns: Latest transcription item or nil if none available
    var latestTranscription: TranscriptionItem? {
        return transcriptions.last
    }
    
    // MARK: - Transcript Management (Android compatibility)
    
    /// Get transcriptions by role (Android compatibility)
    /// - Parameter role: The role to filter by ("user" or "assistant")
    /// - Returns: Array of transcription items for the specified role
    func getTranscriptionsByRole(_ role: String) -> [TranscriptionItem] {
        return transcriptions.filter { $0.role.lowercased() == role.lowercased() }
    }
    
    /// Get user transcriptions only
    /// - Returns: Array of user transcription items
    var userTranscriptions: [TranscriptionItem] {
        return getTranscriptionsByRole("user")
    }
    
    /// Get assistant transcriptions only
    /// - Returns: Array of assistant transcription items
    var assistantTranscriptions: [TranscriptionItem] {
        return getTranscriptionsByRole("assistant")
    }
    
    /// Clear transcriptions by role
    /// - Parameter role: The role to clear transcriptions for
    func clearTranscriptionsByRole(_ role: String) {
        transcriptions.removeAll { $0.role.lowercased() == role.lowercased() }
    }
    
    /// Get partial transcriptions (in-progress recordings)
    /// - Returns: Array of partial transcription items
    var partialTranscriptions: [TranscriptionItem] {
        return transcriptions.filter { $0.isPartial }
    }
    
    /// Get final transcriptions (completed recordings)
    /// - Returns: Array of final transcription items
    var finalTranscriptions: [TranscriptionItem] {
        return transcriptions.filter { !$0.isPartial }
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
        print("AIAssistantViewModel onAIAssistantConnectionStateChanged - isConnected: \(isConnected), targetId: \(String(describing: targetId))")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isConnected = isConnected
            self.isLoading = false
            
            if isConnected, let targetId = targetId {
                // Save the successful targetId to UserDefaults
                self.saveLastTargetId(targetId)
            } else {
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
        print("AIAssistantViewModel onSocketConnected called")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isConnected = true
            self.isLoading = false
            self.loadingMessage = ""
        }
    }
    
    func onSocketDisconnected() {
        print("AIAssistantViewModel onSocketDisconnected called")
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
        print("AIAssistantViewModel onClientError called: \(error)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            self.errorMessage = error.localizedDescription
        }
    }
    
    func onClientReady() {
        print("AIAssistantViewModel onClientReady called")
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
