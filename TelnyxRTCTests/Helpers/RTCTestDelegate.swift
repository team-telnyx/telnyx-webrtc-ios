import Foundation
import TelnyxRTC
import XCTest

class RTCTestDelegate : TxClientDelegate {
    
    func onPushDisabled(success: Bool, message: String) {}
    
    
    var expectation: XCTestExpectation
    
    init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }
    
    func onSocketConnected() {}
    
    func onSocketDisconnected() {}
    
    func onClientError(error: Error) {}
    
    func onClientReady() {}
    
    func onSessionUpdated(sessionId: String) {}
    
    func onCallStateUpdated(callState: CallState, callId: UUID) {}
    
    func onIncomingCall(call: Call) {}
    
    func onRemoteCallEnded(callId: UUID, reason: TelnyxRTC.CallTerminationReason?) { }
    
    func onPushCall(call: Call) {}
}




