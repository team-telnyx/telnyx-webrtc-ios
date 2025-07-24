//
//  CallActiveStateTests.swift
//  TelnyxRTCTests
//
//  Created by AI SWE Agent on 14/07/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import XCTest
@testable import TelnyxRTC
@testable import TelnyxWebRTCDemo

/// Tests for call active state management and feature disabling during active calls
class CallActiveStateTests: XCTestCase {
    
    var homeViewModel: HomeViewModel!
    
    override func setUp() {
        super.setUp()
        homeViewModel = HomeViewModel()
    }
    
    override func tearDown() {
        homeViewModel = nil
        super.tearDown()
    }
    
    // MARK: - Feature Disable State Tests
    
    func testRegionSelectionEnabledWhenNoTxClient() {
        // Given: HomeViewModel without TxClient
        
        // When: Checking if region selection is disabled
        let isDisabled = homeViewModel.isRegionSelectionDisabled
        
        // Then: Should be enabled
        XCTAssertFalse(isDisabled, "Region selection should be enabled when TxClient is nil")
    }
    
    func testPreCallDiagnosisEnabledWhenNoTxClient() {
        // Given: HomeViewModel without TxClient
        
        // When: Checking if pre-call diagnosis is disabled
        let isDisabled = homeViewModel.isPreCallDiagnosisDisabled
        
        // Then: Should be enabled
        XCTAssertFalse(isDisabled, "Pre-call diagnosis should be enabled when TxClient is nil")
    }
    
    func testCallActiveWithNoTxClient() {
        // Given: HomeViewModel without TxClient
        
        // When: Checking if calls are active
        let isActive = homeViewModel.isCallsActive
        
        // Then: Should return false
        XCTAssertFalse(isActive, "Should return false when TxClient is nil")
        XCTAssertFalse(homeViewModel.isRegionSelectionDisabled, "Region selection should be enabled when TxClient is nil")
        XCTAssertFalse(homeViewModel.isPreCallDiagnosisDisabled, "Pre-call diagnosis should be enabled when TxClient is nil")
    }
    
    func testInitialState() {
        // Given: Newly created HomeViewModel
        
        // When: Checking initial state
        
        // Then: Should have correct defaults
        XCTAssertFalse(homeViewModel.isCallsActive, "Should start with no active calls")
        XCTAssertFalse(homeViewModel.isRegionSelectionDisabled, "Region selection should be enabled initially")
        XCTAssertFalse(homeViewModel.isPreCallDiagnosisDisabled, "Pre-call diagnosis should be enabled initially")
        XCTAssertEqual(homeViewModel.socketState, .disconnected, "Should start disconnected")
        XCTAssertEqual(homeViewModel.sessionId, "-", "Should start with no session ID")
        XCTAssertFalse(homeViewModel.isLoading, "Should not be loading initially")
    }
    
    func testFeatureDisablingLogic() {
        // Given: HomeViewModel
        
        // When: Checking feature disabling logic
        let regionDisabled = homeViewModel.isRegionSelectionDisabled
        let diagnosisDisabled = homeViewModel.isPreCallDiagnosisDisabled
        let callsActive = homeViewModel.isCallsActive
        
        // Then: Both features should have same state as calls active
        XCTAssertEqual(regionDisabled, callsActive, "Region selection disabled state should match calls active state")
        XCTAssertEqual(diagnosisDisabled, callsActive, "Pre-call diagnosis disabled state should match calls active state")
    }
    
    // MARK: - TxClient Integration Tests
    
    func testWithTxClientButNoCalls() {
        // Given: HomeViewModel with TxClient but no calls
        let txClient = TxClient()
        homeViewModel.setTxClient(txClient)
        
        // When: Checking state
        let isActive = homeViewModel.isCallsActive
        let isRegionDisabled = homeViewModel.isRegionSelectionDisabled
        let isDiagnosisDisabled = homeViewModel.isPreCallDiagnosisDisabled
        
        // Then: Should not be active, features should be enabled
        XCTAssertFalse(isActive, "Should not have active calls")
        XCTAssertFalse(isRegionDisabled, "Region selection should be enabled")
        XCTAssertFalse(isDiagnosisDisabled, "Pre-call diagnosis should be enabled")
    }
    
    // MARK: - Performance Tests
    
    func testCallActiveStatePerformance() {
        // Given: HomeViewModel with TxClient
        let txClient = TxClient()
        homeViewModel.setTxClient(txClient)
        
        // When: Measuring performance of isCallsActive
        measure {
            _ = homeViewModel.isCallsActive
        }
    }
    
    func testFeatureStatePerformance() {
        // Given: HomeViewModel with TxClient
        let txClient = TxClient()
        homeViewModel.setTxClient(txClient)
        
        // When: Measuring performance of feature state checks
        measure {
            _ = homeViewModel.isRegionSelectionDisabled
            _ = homeViewModel.isPreCallDiagnosisDisabled
        }
    }
    
    // MARK: - Edge Cases
    
    func testPreCallDiagnosticManagerIntegration() {
        // Given: HomeViewModel
        
        // When: Checking PreCallDiagnosticManager integration
        let manager = homeViewModel.preCallDiagnosticManager
        
        // Then: Should have manager instance
        XCTAssertNotNil(manager, "Should have PreCallDiagnosticManager instance")
        XCTAssertTrue(manager === PreCallDiagnosticManager.shared, "Should use shared instance")
    }
    
    func testRegionProperty() {
        // Given: HomeViewModel
        
        // When: Checking region property
        let initialRegion = homeViewModel.seletedRegion
        
        // Then: Should have default region
        XCTAssertEqual(initialRegion, .auto, "Should start with auto region")
        
        // When: Changing region
        homeViewModel.seletedRegion = .us_east
        
        // Then: Should update
        XCTAssertEqual(homeViewModel.seletedRegion, .us_east, "Should update region")
    }
    
    func testCallStateProperty() {
        // Given: HomeViewModel
        
        // When: Checking call state
        let initialCallState = homeViewModel.callState
        
        // Then: Should have default state
        if case .DONE = initialCallState {
            // This is expected
        } else {
            XCTFail("Should start with DONE call state")
        }
    }
}
