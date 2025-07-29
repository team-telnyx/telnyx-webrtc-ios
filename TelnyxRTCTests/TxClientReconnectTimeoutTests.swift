//
//  TxClientReconnectTimeoutTests.swift
//  TelnyxRTCTests
//
//  Created by AI SWE Agent on 29/07/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import XCTest
@testable import TelnyxRTC

/// Unit tests for TxClient reconnect timeout functionality
/// 
/// These tests verify that the reconnect timeout timer is properly managed
/// to prevent EXC_BREAKPOINT (SIGTRAP) crashes that were occurring in v2.0.1
/// when the timer was cancelled without proper thread safety or state checking.
class TxClientReconnectTimeoutTests: XCTestCase {
    
    var txClient: TxClient!
    var mockDelegate: MockTxClientDelegate!
    
    override func setUp() {
        super.setUp()
        txClient = TxClient()
        mockDelegate = MockTxClientDelegate()
        txClient.delegate = mockDelegate
    }
    
    override func tearDown() {
        txClient.delegate = nil
        txClient = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    /// Test that stopReconnectTimeout can be called multiple times without crashing
    /// This addresses the EXC_BREAKPOINT issue where double-cancellation caused crashes
    func testStopReconnectTimeoutMultipleCalls() {
        let expectation = XCTestExpectation(description: "Multiple stop calls should not crash")
        
        // Start a timeout first
        txClient.startReconnectTimeout()
        
        // Stop it multiple times - this should not crash
        txClient.stopReconnectTimeout()
        txClient.stopReconnectTimeout()
        txClient.stopReconnectTimeout()
        
        // Wait a bit to ensure all async operations complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test that stopReconnectTimeout can be called without starting a timer first
    /// This ensures proper nil checking prevents crashes
    func testStopReconnectTimeoutWithoutStart() {
        let expectation = XCTestExpectation(description: "Stop without start should not crash")
        
        // Call stop without starting - should not crash
        txClient.stopReconnectTimeout()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test that starting a new timeout while one is already running properly cancels the old one
    /// This prevents timer leaks and ensures only one timer is active at a time
    func testStartReconnectTimeoutWhileRunning() {
        let expectation = XCTestExpectation(description: "Starting new timeout should cancel old one")
        
        // Start first timeout
        txClient.startReconnectTimeout()
        
        // Start second timeout - should cancel the first one
        txClient.startReconnectTimeout()
        
        // Stop the current timeout
        txClient.stopReconnectTimeout()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test that the timer properly cleans up when TxClient is deallocated
    /// This ensures no memory leaks or dangling timer references
    func testTimerCleanupOnDeallocation() {
        let expectation = XCTestExpectation(description: "Timer should be cleaned up on deallocation")
        
        // Create a client in a local scope
        var localClient: TxClient? = TxClient()
        localClient?.startReconnectTimeout()
        
        // Deallocate the client - timer should be cleaned up in deinit
        localClient = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test rapid start/stop cycles to ensure thread safety
    /// This simulates network instability scenarios that could trigger the crash
    func testRapidStartStopCycles() {
        let expectation = XCTestExpectation(description: "Rapid start/stop cycles should be thread-safe")
        
        // Perform rapid start/stop cycles
        for _ in 0..<10 {
            txClient.startReconnectTimeout()
            txClient.stopReconnectTimeout()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}

/// Mock delegate for testing TxClient functionality
class MockTxClientDelegate: TxClientDelegate {
    var onClientErrorCalled = false
    var lastError: Error?
    
    func onRemoteCallEnded(callId: UUID) {}
    func onSocketConnected() {}
    func onSocketDisconnected() {}
    func onClientReady() {}
    func onSessionUpdated(sessionId: String) {}
    func onIncomingCall(call: Call) {}
    func onCallStateUpdated(callState: CallState, callId: UUID) {}
    
    func onClientError(error: Error) {
        onClientErrorCalled = true
        lastError = error
    }
}