import Foundation
import WebRTC

// MARK: - ICE Restart
extension Peer {
    
    /// Performs ICE restart by creating a new offer with iceRestart flag set to true
    /// This is useful when network conditions change and we need to renegotiate ICE candidates
    /// - Parameter completion: Callback with the new SDP offer or error
    func iceRestart(completion: @escaping (_ sdp: RTCSessionDescription?, _ error: Error?) -> Void) {
        // Set ICE restart flag to allow new candidates even when connected
        self.isIceRestarting = true
        
        // Reset negotiation state
        self.negotiationEnded = false
        self.gatheredICECandidates.removeAll()
        
        // Create constraints with IceRestart flag to force ICE restart
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: ["IceRestart": "true"],
            optionalConstraints: nil
        )
        
        // Create new offer with IceRestart constraint - this should force new ICE candidates
        self.connection?.offer(for: constraints) { (sdp, error) in
            if let error = error {
                Logger.log.e(message: "[ICE-RESTART] Peer:: Error creating ICE restart offer: \(error)")
                self.isIceRestarting = false
                completion(nil, error)
                return
            }
            
            guard let sdp = sdp else {
                Logger.log.w(message: "[ICE-RESTART] Peer:: ICE restart SDP is missing")
                self.isIceRestarting = false
                completion(nil, NSError(domain: "Peer", code: -1, userInfo: [NSLocalizedDescriptionKey: "SDP is missing"]))
                return
            }
            
            // Set local description to start ICE gathering with new candidates
            self.connection?.setLocalDescription(sdp, completionHandler: { (error) in
                if let error = error {
                    Logger.log.e(message: "[ICE-RESTART] Peer:: Error setting ICE restart local description: \(error)")
                    self.isIceRestarting = false
                    completion(nil, error)
                } else {
                    // Store completion handler for when negotiation ends
                    self.iceRestartCompletion = completion
                    
                    // Start waiting for ICE candidates with a timeout
                    self.waitForICECandidatesWithTimeout(completion: completion)
                }
            })
        }
    }
    
    /// Waits for ICE candidates to be generated during ICE restart with a timeout
    /// - Parameter completion: Callback with the final SDP or error
    private func waitForICECandidatesWithTimeout(completion: @escaping (_ sdp: RTCSessionDescription?, _ error: Error?) -> Void) {
        let timeout: TimeInterval = 5.0 // 5 seconds timeout for ICE candidates
        let startTime = Date()
        var lastCandidateCount = 0
        var stableCandidateCount = 0
        let requiredStableChecks = 3 // Need 3 consecutive checks with same count to consider stable
        
        // Check periodically if we have candidates or if ICE gathering is complete
        let timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            
            // Check if ICE gathering is complete or we have candidates
            if let connection = self.connection {
                let gatheringState = connection.iceGatheringState
                
                // Check if we have any candidates in the current local description
                if let localDescription = connection.localDescription {
                    let candidateCount = localDescription.sdp.components(separatedBy: "a=candidate:").count - 1
                    
                    if candidateCount > lastCandidateCount {
                        lastCandidateCount = candidateCount
                        stableCandidateCount = 0 // Reset stability counter
                    } else if candidateCount == lastCandidateCount && candidateCount > 0 {
                        stableCandidateCount += 1
                    }
                }
                
                // Check if ICE gathering is complete OR we have stable candidates
                if gatheringState == .complete {
                    timer.invalidate()
                    self.iceRestartCompletion = nil
                    self.createFinalOfferWithCandidates(completion: completion)
                } else if lastCandidateCount > 0 && stableCandidateCount >= requiredStableChecks {
                    timer.invalidate()
                    self.iceRestartCompletion = nil
                    self.createFinalOfferWithCandidates(completion: completion)
                } else if elapsed >= timeout {
                    Logger.log.w(message: "[ICE-RESTART] Peer:: Timeout waiting for ICE candidates")
                    timer.invalidate()
                    self.iceRestartCompletion = nil
                    
                    // Proceed with current SDP even without candidates
                    if let localDescription = connection.localDescription {
                        completion(localDescription, nil)
                    } else {
                        Logger.log.e(message: "[ICE-RESTART] Peer:: No local description available after timeout")
                        completion(nil, NSError(domain: "Peer", code: -1, userInfo: [NSLocalizedDescriptionKey: "No local description available after timeout"]))
                    }
                }
            } else {
                Logger.log.e(message: "[ICE-RESTART] Peer:: Connection lost during ICE restart")
                timer.invalidate()
                self.iceRestartCompletion = nil
                completion(nil, NSError(domain: "Peer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection lost"]))
            }
        }
        
        // Store timer reference to prevent deallocation
        RunLoop.current.add(timer, forMode: .common)
    }
    
    internal func createFinalOfferWithCandidates(completion: @escaping (_ sdp: RTCSessionDescription?, _ error: Error?) -> Void) {
        // For ICE restart, we should NOT create a new offer as it can cause codec negotiation errors
        // Instead, we should use the existing local description which already has the ICE restart flag
        // and the gathered candidates will be automatically included
        
        if let localDescription = self.connection?.localDescription {
            let candidateCount = localDescription.sdp.components(separatedBy: "a=candidate:").count - 1
            
            // Log warning if no candidates found
            if candidateCount == 0 {
                Logger.log.w(message: "[ICE-RESTART] Peer:: No ICE candidates found in local description")
            }
            
            completion(localDescription, nil)
        } else {
            Logger.log.e(message: "[ICE-RESTART] Peer:: No local description available for ICE restart")
            completion(nil, NSError(domain: "Peer", code: -1, userInfo: [NSLocalizedDescriptionKey: "No local description available"]))
        }
    }
    
    /// Stops ICE gathering to prevent further candidate generation
    /// This should be called after sending the ICE restart SDP to avoid overwhelming the server
    func stopICEGathering() {
        // Mark negotiation as ended to prevent further candidate processing
        self.negotiationEnded = true
        
        // Clear any pending ICE restart completion
        self.iceRestartCompletion = nil
        
        // Reset ICE restart flag
        self.isIceRestarting = false
    }
}
