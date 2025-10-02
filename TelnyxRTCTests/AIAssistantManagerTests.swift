//
//  AIAssistantManagerTests.swift
//  TelnyxRTCTests
//
//  Created by AI Assistant on 28/01/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import XCTest
@testable import TelnyxRTC

class AIAssistantManagerTests: XCTestCase {
    
    var aiAssistantManager: AIAssistantManager!
    var mockDelegate: MockAIAssistantManagerDelegate!
    
    override func setUp() {
        super.setUp()
        aiAssistantManager = AIAssistantManager()
        mockDelegate = MockAIAssistantManagerDelegate()
        aiAssistantManager.delegate = mockDelegate
    }
    
    override func tearDown() {
        aiAssistantManager = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Transcription Tests
    
    func testAddTranscription() {
        // Given
        let transcription = TranscriptionItem(
            id: "test-id",
            timestamp: Date(),
            speaker: "user",
            text: "Hello, this is a test transcription",
            confidence: 0.95
        )
        
        // When
        aiAssistantManager.addTranscription(transcription)
        
        // Then
        let transcriptions = aiAssistantManager.getTranscriptions()
        XCTAssertEqual(transcriptions.count, 1)
        XCTAssertEqual(transcriptions.first?.id, "test-id")
        XCTAssertEqual(transcriptions.first?.text, "Hello, this is a test transcription")
        XCTAssertEqual(transcriptions.first?.speaker, "user")
        XCTAssertEqual(transcriptions.first?.confidence, 0.95)
        
        // Verify delegate was called
        XCTAssertTrue(mockDelegate.onTranscriptionUpdatedCalled)
        XCTAssertEqual(mockDelegate.lastTranscriptions?.count, 1)
    }
    
    func testClearTranscriptions() {
        // Given
        let transcription1 = TranscriptionItem(id: "1", timestamp: Date(), speaker: "user", text: "First")
        let transcription2 = TranscriptionItem(id: "2", timestamp: Date(), speaker: "assistant", text: "Second")
        aiAssistantManager.addTranscription(transcription1)
        aiAssistantManager.addTranscription(transcription2)
        
        // When
        aiAssistantManager.clearTranscriptions()
        
        // Then
        let transcriptions = aiAssistantManager.getTranscriptions()
        XCTAssertEqual(transcriptions.count, 0)
        
        // Verify delegate was called
        XCTAssertTrue(mockDelegate.onTranscriptionUpdatedCalled)
        XCTAssertEqual(mockDelegate.lastTranscriptions?.count, 0)
    }
    
    // MARK: - Widget Settings Tests
    
    func testUpdateWidgetSettings() {
        // Given
        let settings = WidgetSettings(
            theme: "dark",
            language: "en",
            autoStart: true,
            showTranscript: false,
            customStyles: ["color": "blue"]
        )
        
        // When
        aiAssistantManager.updateWidgetSettings(settings)
        
        // Then
        let retrievedSettings = aiAssistantManager.getWidgetSettings()
        XCTAssertNotNil(retrievedSettings)
        XCTAssertEqual(retrievedSettings?.theme, "dark")
        XCTAssertEqual(retrievedSettings?.language, "en")
        XCTAssertEqual(retrievedSettings?.autoStart, true)
        XCTAssertEqual(retrievedSettings?.showTranscript, false)
        
        // Verify delegate was called
        XCTAssertTrue(mockDelegate.onWidgetSettingsUpdatedCalled)
        XCTAssertEqual(mockDelegate.lastWidgetSettings?.theme, "dark")
    }
    
    // MARK: - Clear All Data Tests
    
    func testClearAllData() {
        // Given
        let transcription = TranscriptionItem(id: "test", timestamp: Date(), speaker: "user", text: "Test")
        let settings = WidgetSettings(theme: "light", language: "es", autoStart: false, showTranscript: true)
        
        aiAssistantManager.addTranscription(transcription)
        aiAssistantManager.updateWidgetSettings(settings)
        
        // When
        aiAssistantManager.clearAllData()
        
        // Then
        XCTAssertEqual(aiAssistantManager.getTranscriptions().count, 0)
        XCTAssertNil(aiAssistantManager.getWidgetSettings())
        
        // Verify delegate was called
        XCTAssertTrue(mockDelegate.onTranscriptionUpdatedCalled)
    }
    
    // MARK: - Message Processing Tests
    
    func testProcessTranscriptionMessage() {
        // Given
        let message: [String: Any] = [
            "method": "telnyx_rtc.transcription",
            "params": [
                "transcript": [
                    "id": "trans-123",
                    "text": "Hello world",
                    "speaker": "user",
                    "timestamp": "2025-01-28T10:00:00Z",
                    "confidence": 0.98
                ]
            ]
        ]
        
        // When
        let processed = aiAssistantManager.processIncomingMessage(message)
        
        // Then
        XCTAssertTrue(processed)
        let transcriptions = aiAssistantManager.getTranscriptions()
        XCTAssertEqual(transcriptions.count, 1)
        XCTAssertEqual(transcriptions.first?.text, "Hello world")
        XCTAssertEqual(transcriptions.first?.speaker, "user")
    }
    
    func testProcessWidgetSettingsMessage() {
        // Given
        let message: [String: Any] = [
            "method": "telnyx_rtc.widget_config",
            "params": [
                "widget_settings": [
                    "theme": "dark",
                    "language": "fr",
                    "auto_start": true,
                    "show_transcript": false
                ]
            ]
        ]
        
        // When
        let processed = aiAssistantManager.processIncomingMessage(message)
        
        // Then
        XCTAssertTrue(processed)
        let settings = aiAssistantManager.getWidgetSettings()
        XCTAssertNotNil(settings)
        XCTAssertEqual(settings?.theme, "dark")
        XCTAssertEqual(settings?.language, "fr")
        XCTAssertEqual(settings?.autoStart, true)
        XCTAssertEqual(settings?.showTranscript, false)
    }
    
    func testProcessNonAIMessage() {
        // Given
        let message: [String: Any] = [
            "method": "telnyx_rtc.invite",
            "params": [
                "callID": "call-123"
            ]
        ]
        
        // When
        let processed = aiAssistantManager.processIncomingMessage(message)
        
        // Then
        XCTAssertFalse(processed)
    }
}

// MARK: - Mock Delegate

class MockAIAssistantManagerDelegate: AIAssistantManagerDelegate {
    
    var onAIConversationMessageCalled = false
    var onRingingAckReceivedCalled = false
    var onAIAssistantConnectionStateChangedCalled = false
    var onTranscriptionUpdatedCalled = false
    var onWidgetSettingsUpdatedCalled = false
    
    var lastMessage: [String: Any]?
    var lastCallId: String?
    var lastConnectionState: (isConnected: Bool, targetId: String?)?
    var lastTranscriptions: [TranscriptionItem]?
    var lastWidgetSettings: WidgetSettings?
    
    func onAIConversationMessage(_ message: [String : Any]) {
        onAIConversationMessageCalled = true
        lastMessage = message
    }
    
    func onRingingAckReceived(callId: String) {
        onRingingAckReceivedCalled = true
        lastCallId = callId
    }
    
    func onAIAssistantConnectionStateChanged(isConnected: Bool, targetId: String?) {
        onAIAssistantConnectionStateChangedCalled = true
        lastConnectionState = (isConnected, targetId)
    }
    
    func onTranscriptionUpdated(_ transcriptions: [TranscriptionItem]) {
        onTranscriptionUpdatedCalled = true
        lastTranscriptions = transcriptions
    }
    
    func onWidgetSettingsUpdated(_ settings: WidgetSettings) {
        onWidgetSettingsUpdatedCalled = true
        lastWidgetSettings = settings
    }
}