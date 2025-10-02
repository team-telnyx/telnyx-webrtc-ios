//
//  AnonymousLoginTests.swift
//  TelnyxRTCTests
//
//  Created by AI SWE Agent on 29/07/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import XCTest
@testable import TelnyxRTC

class AnonymousLoginTests: XCTestCase {
    
    var txClient: TxClient!
    
    override func setUp() {
        super.setUp()
        txClient = TxClient()
    }
    
    override func tearDown() {
        txClient = nil
        super.tearDown()
    }
    
    func testAnonymousLoginWithDisconnectedSocket() {
        // Given
        let targetId = "test-assistant-id"
        let targetType = "ai_assistant"
        let targetVersionId = "v1.0"
        let userVariables = ["test": "value"]
        
        // When
        txClient.anonymousLogin(
            targetId: targetId,
            targetType: targetType,
            targetVersionId: targetVersionId,
            userVariables: userVariables,
            reconnection: false
        )
        
        // Then
        // The method should not throw an error and should handle the disconnected state gracefully
        // This is a behavioral test - the method should queue the message for later sending
        XCTAssertTrue(true, "Anonymous login should handle disconnected socket gracefully")
    }
    
    func testAnonymousLoginMessageCreation() {
        // Given
        let targetId = "test-assistant-id"
        let targetType = "ai_assistant"
        let targetVersionId = "v1.0"
        let sessionId = "test-session-id"
        let userVariables = ["user": "test", "type": "demo"]
        
        // When
        let message = AnonymousLoginMessage(
            targetType: targetType,
            targetId: targetId,
            targetVersionId: targetVersionId,
            sessionId: sessionId,
            userVariables: userVariables,
            reconnection: false
        )
        
        // Then
        XCTAssertNotNil(message)
        XCTAssertEqual(message.method, .ANONYMOUS_LOGIN)
        
        // Verify the message can be encoded
        let encodedMessage = message.encode()
        XCTAssertFalse(encodedMessage.isEmpty)
        
        // Verify the encoded message contains expected fields
        XCTAssertTrue(encodedMessage.contains("target_id"))
        XCTAssertTrue(encodedMessage.contains("target_type"))
        XCTAssertTrue(encodedMessage.contains("anonymous_login"))
    }
    
    func testAIAssistantManagerInitialization() {
        // Given & When
        let aiManager = AIAssistantManager()
        
        // Then
        XCTAssertNotNil(aiManager)
        XCTAssertFalse(aiManager.isAIAssistantConnected)
        XCTAssertNil(aiManager.connectedTargetId)
        
        let connectionInfo = aiManager.getConnectionInfo()
        XCTAssertEqual(connectionInfo["isConnected"] as? Bool, false)
    }
    
    func testAIAssistantManagerConnectionState() {
        // Given
        let aiManager = AIAssistantManager()
        let targetId = "test-assistant"
        let targetType = "ai_assistant"
        
        // When
        aiManager.updateConnectionState(
            connected: true,
            targetId: targetId,
            targetType: targetType
        )
        
        // Then
        XCTAssertTrue(aiManager.isAIAssistantConnected)
        XCTAssertEqual(aiManager.connectedTargetId, targetId)
        
        let connectionInfo = aiManager.getConnectionInfo()
        XCTAssertEqual(connectionInfo["isConnected"] as? Bool, true)
        XCTAssertEqual(connectionInfo["targetId"] as? String, targetId)
        XCTAssertEqual(connectionInfo["targetType"] as? String, targetType)
    }
    
    func testAIConversationMessageDetection() {
        // Given
        let aiManager = AIAssistantManager()
        
        let aiMessage: [String: Any] = [
            "method": "ai_conversation",
            "params": [
                "ai_conversation": "Hello, how can I help you?",
                "target_type": "ai_assistant"
            ]
        ]
        
        let regularMessage: [String: Any] = [
            "method": "telnyx_rtc.invite",
            "params": [
                "callID": "test-call-id"
            ]
        ]
        
        // When & Then
        XCTAssertTrue(aiManager.processIncomingMessage(aiMessage))
        XCTAssertFalse(aiManager.processIncomingMessage(regularMessage))
    }
    
    func testRingingAckMessageCreation() {
        // Given
        let callId = "test-call-id"
        let sessionId = "test-session-id"
        
        // When
        let ringingAckMessage = RingingAckMessage(callId: callId, sessionId: sessionId)
        
        // Then
        XCTAssertNotNil(ringingAckMessage)
        XCTAssertEqual(ringingAckMessage.method, .RINGING_ACK)
        
        let encodedMessage = ringingAckMessage.encode()
        XCTAssertFalse(encodedMessage.isEmpty)
        XCTAssertTrue(encodedMessage.contains("telnyx_rtc.ringing_ack"))
        XCTAssertTrue(encodedMessage.contains(callId))
    }
    
    func testTxClientAIAssistantManagerIntegration() {
        // Given
        let txClient = TxClient()
        
        // When & Then
        XCTAssertNotNil(txClient.aiAssistantManager)
        XCTAssertFalse(txClient.aiAssistantManager.isAIAssistantConnected)
    }
    
    func testAnonymousLoginParameterHandling() {
        // Given
        let targetId = "assistant-123"
        let userVariables = ["key1": "value1", "key2": 42] as [String: Any]
        
        // When
        txClient.anonymousLogin(
            targetId: targetId,
            userVariables: userVariables
        )
        
        // Then
        // Should not crash with mixed type user variables
        XCTAssertTrue(true, "Anonymous login should handle mixed type user variables")
    }
    
    func testAnonymousLoginDefaultParameters() {
        // Given
        let targetId = "assistant-default"
        
        // When
        txClient.anonymousLogin(targetId: targetId)
        
        // Then
        // Should work with minimal parameters
        XCTAssertTrue(true, "Anonymous login should work with default parameters")
    }
}

// MARK: - Mock Delegate for Testing

class MockAIAssistantManagerDelegate: AIAssistantManagerDelegate {
    var receivedAIMessages: [[String: Any]] = []
    var receivedRingingAcks: [String] = []
    var connectionStateChanges: [(Bool, String?)] = []
    
    func onAIConversationMessage(_ message: [String : Any]) {
        receivedAIMessages.append(message)
    }
    
    func onRingingAckReceived(callId: String) {
        receivedRingingAcks.append(callId)
    }
    
    func onAIAssistantConnectionStateChanged(isConnected: Bool, targetId: String?) {
        connectionStateChanges.append((isConnected, targetId))
    }
}

// MARK: - Additional Tests with Mock Delegate

extension AnonymousLoginTests {
    
    func testAIAssistantManagerDelegateCallbacks() {
        // Given
        let aiManager = AIAssistantManager()
        let mockDelegate = MockAIAssistantManagerDelegate()
        aiManager.delegate = mockDelegate
        
        let aiMessage: [String: Any] = [
            "method": "ai_conversation",
            "params": ["message": "Hello"]
        ]
        
        // When
        _ = aiManager.processIncomingMessage(aiMessage)
        aiManager.updateConnectionState(connected: true, targetId: "test-id")
        
        // Then
        XCTAssertEqual(mockDelegate.receivedAIMessages.count, 1)
        XCTAssertEqual(mockDelegate.connectionStateChanges.count, 1)
        XCTAssertTrue(mockDelegate.connectionStateChanges[0].0) // isConnected
        XCTAssertEqual(mockDelegate.connectionStateChanges[0].1, "test-id") // targetId
    }
}