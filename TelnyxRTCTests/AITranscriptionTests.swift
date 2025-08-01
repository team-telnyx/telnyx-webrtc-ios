//
//  AITranscriptionTests.swift
//  TelnyxRTCTests
//
//  Created by AI Assistant on 01/08/2025.
//

import XCTest
@testable import TelnyxRTC

class AITranscriptionTests: XCTestCase {
    
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
    
    func testResponseTextDeltaProcessing() {
        // Test message from AI assistant with response.text.delta type
        let message: [String: Any] = [
            "id": "2d865e18-ddf4-4f2d-a6fb-46b9d0cc2713",
            "jsonrpc": "2.0",
            "method": "ai_conversation",
            "params": [
                "content_index": 0,
                "delta": " Hi there! I'm your Telnyx Voice Assistant. How can I assist you today?",
                "item_id": "ad339df1-03df-4c60-a620-4e05d3c0c9f5",
                "output_index": 0,
                "response_id": "ad339df1-03df-4c60-a620-4e05d3c0c9f5",
                "type": "response.text.delta"
            ],
            "voice_sdk_id": "VSDK1Cu9f0jpaK4rBw_vGRTWnMyUhyfWRdw"
        ]
        
        // Process the message
        let processed = aiAssistantManager.processMessage(message)
        
        // Verify it was processed
        XCTAssertTrue(processed, "Message should have been processed")
        
        // Verify transcription was added
        let transcriptions = aiAssistantManager.getTranscriptions()
        XCTAssertEqual(transcriptions.count, 1, "Should have one transcription")
        
        let transcription = transcriptions.first!
        XCTAssertEqual(transcription.id, "ad339df1-03df-4c60-a620-4e05d3c0c9f5")
        XCTAssertEqual(transcription.speaker, "assistant")
        XCTAssertEqual(transcription.text, " Hi there! I'm your Telnyx Voice Assistant. How can I assist you today?")
        XCTAssertFalse(transcription.isFinal, "Delta messages should not be final")
        XCTAssertEqual(transcription.confidence, 1.0)
    }
    
    func testConversationItemCreatedProcessing() {
        // Test message from user with conversation.item.created type
        let message: [String: Any] = [
            "id": "f5829a5d-d299-481a-89db-ff1ce6e871e4",
            "jsonrpc": "2.0",
            "method": "ai_conversation",
            "params": [
                "item": [
                    "content": [
                        [
                            "transcript": "I want to end the current call.",
                            "type": "input_audio"
                        ]
                    ],
                    "id": "6da88024-6b6f-4d6b-8869-b43c37a55380",
                    "role": "user",
                    "status": "completed",
                    "type": "message"
                ],
                "previous_item_id": "ffe8f7cd-8fc6-4ced-bfe8-da5ab28cbcdc",
                "type": "conversation.item.created"
            ],
            "voice_sdk_id": "VSDK1Cu9f0jpaK4rBw_vGRTWnMyUhyfWRdw"
        ]
        
        // Process the message
        let processed = aiAssistantManager.processMessage(message)
        
        // Verify it was processed
        XCTAssertTrue(processed, "Message should have been processed")
        
        // Verify transcription was added
        let transcriptions = aiAssistantManager.getTranscriptions()
        XCTAssertEqual(transcriptions.count, 1, "Should have one transcription")
        
        let transcription = transcriptions.first!
        XCTAssertEqual(transcription.id, "6da88024-6b6f-4d6b-8869-b43c37a55380")
        XCTAssertEqual(transcription.speaker, "user")
        XCTAssertEqual(transcription.text, "I want to end the current call.")
        XCTAssertTrue(transcription.isFinal, "Completed user messages should be final")
        XCTAssertNil(transcription.confidence, "User transcripts don't have confidence")
    }
    
    func testInProgressUserTranscription() {
        // Test in-progress user transcription
        let message: [String: Any] = [
            "id": "test-id",
            "jsonrpc": "2.0",
            "method": "ai_conversation",
            "params": [
                "item": [
                    "content": [
                        [
                            "transcript": "I want to...",
                            "type": "input_audio"
                        ]
                    ],
                    "id": "user-item-123",
                    "role": "user",
                    "status": "in_progress",
                    "type": "message"
                ],
                "type": "conversation.item.created"
            ]
        ]
        
        // Process the message
        let processed = aiAssistantManager.processMessage(message)
        
        // Verify it was processed
        XCTAssertTrue(processed, "Message should have been processed")
        
        // Verify transcription was added
        let transcriptions = aiAssistantManager.getTranscriptions()
        XCTAssertEqual(transcriptions.count, 1, "Should have one transcription")
        
        let transcription = transcriptions.first!
        XCTAssertEqual(transcription.id, "user-item-123")
        XCTAssertEqual(transcription.speaker, "user")
        XCTAssertEqual(transcription.text, "I want to...")
        XCTAssertFalse(transcription.isFinal, "In-progress user messages should not be final")
    }
    
    func testDeltaMessageAppending() {
        // First delta message
        let firstDelta: [String: Any] = [
            "id": "delta-test-1",
            "jsonrpc": "2.0",
            "method": "ai_conversation",
            "params": [
                "delta": "Hello",
                "item_id": "response-123",
                "type": "response.text.delta"
            ]
        ]
        
        // Second delta message with same item_id
        let secondDelta: [String: Any] = [
            "id": "delta-test-2",
            "jsonrpc": "2.0",
            "method": "ai_conversation",
            "params": [
                "delta": " there!",
                "item_id": "response-123",
                "type": "response.text.delta"
            ]
        ]
        
        // Process both messages
        XCTAssertTrue(aiAssistantManager.processMessage(firstDelta))
        XCTAssertTrue(aiAssistantManager.processMessage(secondDelta))
        
        // Verify transcription was appended
        let transcriptions = aiAssistantManager.getTranscriptions()
        XCTAssertEqual(transcriptions.count, 1, "Should have one transcription (appended)")
        
        let transcription = transcriptions.first!
        XCTAssertEqual(transcription.id, "response-123")
        XCTAssertEqual(transcription.text, "Hello there!", "Text should be appended")
        XCTAssertEqual(transcription.speaker, "assistant")
        XCTAssertFalse(transcription.isFinal)
    }
}

// Mock delegate for testing
class MockAIAssistantManagerDelegate: AIAssistantManagerDelegate {
    var transcriptionsUpdated: [[TranscriptionItem]] = []
    var widgetSettingsUpdated: [WidgetSettings] = []
    var aiConversationMessages: [[String: Any]] = []
    var ringingAckCallIds: [String] = []
    
    func onTranscriptionUpdated(_ transcriptions: [TranscriptionItem]) {
        transcriptionsUpdated.append(transcriptions)
    }
    
    func onWidgetSettingsUpdated(_ settings: WidgetSettings) {
        widgetSettingsUpdated.append(settings)
    }
    
    func onAIConversationMessage(_ message: [String: Any]) {
        aiConversationMessages.append(message)
    }
    
    func onRingingAckReceived(callId: String) {
        ringingAckCallIds.append(callId)
    }
}
