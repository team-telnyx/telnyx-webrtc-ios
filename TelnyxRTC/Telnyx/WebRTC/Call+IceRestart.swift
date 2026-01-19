import Foundation
import WebRTC

// MARK: - ICE Restart handling
extension Call {
    
    /// Performs ICE restart to renegotiate ICE candidates when network conditions change
    /// This helps resolve audio delay issues by establishing new network paths
    /// - Parameter completion: Callback indicating success or failure of the ICE restart
    public func iceRestart(completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        guard let peer = self.peer,
              let callId = self.callInfo?.callId,
              let sessionId = self.sessionId else {
            Logger.log.e(message: "[ICE-RESTART] Call:: ICE restart failed - missing peer, callId, or sessionId")
            completion(false, NSError(domain: "Call", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing required parameters for ICE restart"]))
            return
        }
        
        // Check if call is in a valid state for ICE restart
        guard self.callState == .ACTIVE || self.callState == .CONNECTING else {
            Logger.log.w(message: "[ICE-RESTART] Call:: ICE restart skipped - call not in active state: \(self.callState)")
            completion(false, NSError(domain: "Call", code: -2, userInfo: [NSLocalizedDescriptionKey: "Call not in active state"]))
            return
        }
        
        // Set ICE restart flag to prevent automatic answer
        self.isIceRestarting = true
        
        // Mark that we need to reset audio after ICE restart to clear jitter buffers
        self.shouldResetAudioAfterIceRestart = true
        
        // Perform ICE restart on the peer connection
        peer.iceRestart { [weak self] (sdp, error) in
            guard let self = self else {
                completion(false, NSError(domain: "Call", code: -3, userInfo: [NSLocalizedDescriptionKey: "Call instance deallocated"]))
                return
            }
            
            if let error = error {
                Logger.log.e(message: "[ICE-RESTART] Call:: ICE restart failed: \(error)")
                
                // Reset ICE restart flags
                self.isIceRestarting = false
                self.shouldResetAudioAfterIceRestart = false
                
                completion(false, error)
                return
            }
            
            guard let sdp = sdp else {
                Logger.log.e(message: "[ICE-RESTART] Call:: ICE restart failed - no SDP generated")
                
                // Reset ICE restart flags
                self.isIceRestarting = false
                self.shouldResetAudioAfterIceRestart = false
                
                completion(false, NSError(domain: "Call", code: -4, userInfo: [NSLocalizedDescriptionKey: "No SDP generated"]))
                return
            }
            
            // Send ICE restart message via telnyx_rtc.modify
            let iceRestartMessage = ICERestartMessage(sessionId: sessionId, callId: callId.uuidString, sdp: sdp.sdp)
            let message = iceRestartMessage.encode() ?? ""
            self.socket?.sendMessage(message: message)
            
            // Reset ICE restart flag after sending
            self.isIceRestarting = false
            
            // Stop ICE gathering to prevent further candidates
            self.peer?.stopICEGathering()
            
            completion(true, nil)
        }
    }
    
    /// Automatically triggers ICE restart when network conditions change
    /// This is called internally when network quality degrades
    internal func autoIceRestart() {
        iceRestart { [weak self] (success, error) in
            if success {
                Logger.log.i(message: "[ICE-RESTART] Call:: Auto ICE restart completed successfully")
            } else {
                Logger.log.e(message: "[ICE-RESTART] Call:: Auto ICE restart failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    /// Sets up automatic ICE restart when network conditions improve
    /// This should be called when the call becomes active
    internal func setupAutoIceRestart() {
        // Note: Auto ICE restart setup removed as NetworkQualityMonitor is not being ported
        // This method is kept for future implementation if needed
    }
    
    /// Removes automatic ICE restart monitoring
    /// This should be called when the call ends
    internal func removeAutoIceRestart() {
        // Note: Auto ICE restart removal removed as NetworkQualityMonitor is not being ported
        // This method is kept for future implementation if needed
    }
    
    /// Handles ICE restart response from the server
    /// - Parameters:
    ///   - message: The verto message containing the ICE restart response
    ///   - dataMessage: The raw message data
    ///   - txClient: The TxClient instance
    internal func handleIceRestartResponse(message: Message, dataMessage: String, txClient: TxClient) {
        guard let result = message.result,
              let action = result["action"] as? String,
              action == "updateMedia",
              let sdp = result["sdp"] as? String else {
            return
        }
        
        Logger.log.i(message: "[ICE-RESTART] Call:: Processing ICE restart response")
        
        // Set the new remote SDP from the ICE restart response as answer
        let remoteDescription = RTCSessionDescription(type: .answer, sdp: sdp)
        self.peer?.connection?.setRemoteDescription(remoteDescription, completionHandler: { [weak self] (error) in
            guard let self = self else { return }
            
            if let error = error {
                Logger.log.e(message: "[ICE-RESTART] Call:: Error setting ICE restart remote description: \(error)")
                
                // Reset ICE restart flags
                self.isIceRestarting = false
                self.shouldResetAudioAfterIceRestart = false
            } else {
                
                // Reset audio to clear jitter buffers after successful ICE restart
                if self.shouldResetAudioAfterIceRestart {
                    Logger.log.i(message: "[ICE-RESTART] Call:: Resetting audio to clear jitter buffers after ICE restart with preserved speaker state")
                    self.resetAudioDeviceWithNetworkState()
                }
                
                // Reset ICE restart flags
                self.isIceRestarting = false
                self.shouldResetAudioAfterIceRestart = false
                
                Logger.log.i(message: "[ICE-RESTART] Call:: ICE restart completed successfully - connection should be stable")
            }
        })
    }
}
