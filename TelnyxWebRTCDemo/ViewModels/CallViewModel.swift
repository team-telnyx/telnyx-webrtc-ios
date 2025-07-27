import SwiftUI
import TelnyxRTC
import Combine

class CallViewModel: ObservableObject {
    @Published var sipAddress: String = ""
    @Published var isMuted: Bool = false
    @Published var isSpeakerOn: Bool = false
    @Published var callState: CallState = .DONE(reason: nil)
    @Published var isOnHold: Bool = false
    @Published var showDTMFKeyboard: Bool = false
    @Published var showCallMetricsPopup = false
    @Published var callQualityMetrics: CallQualityMetrics? = nil
    @Published var errorMessage: String = ""
    
    /// The current active call object, used for accessing media streams
    @Published var currentCall: Call? = nil
    
    // MARK: - Audio Level Properties
    /// Current inbound audio level for waveform visualization
    @Published var currentInboundAudioLevel: Float = 0.0
    
    /// Current outbound audio level for waveform visualization
    @Published var currentOutboundAudioLevel: Float = 0.0
    
    /// Array containing current inbound audio level (for waveform generation)
    @Published var inboundAudioLevels: [Float] = [0.0]
    
    /// Array containing current outbound audio level (for waveform generation)
    @Published var outboundAudioLevels: [Float] = [0.0]
    
    /// Cancellable for audio level collection
    private var audioLevelCollectionCancellable: AnyCancellable?
    
    /// Previous audio levels for smooth interpolation
    private var previousInboundLevel: Float = 0.0
    private var previousOutboundLevel: Float = 0.0
    
    init() {
        setupAudioLevelCollection()
    }
    
    deinit {
        audioLevelCollectionCancellable?.cancel()
    }
    
    // MARK: - Audio Level Collection
    private func setupAudioLevelCollection() {
        audioLevelCollectionCancellable = $callQualityMetrics
            .sink { [weak self] metrics in
                self?.updateAudioLevels(from: metrics)
            }
    }
    
    private func updateAudioLevels(from metrics: CallQualityMetrics?) {
        guard let metrics = metrics else {
            // Clear levels when call ends or metrics are null
            currentInboundAudioLevel = 0.0
            currentOutboundAudioLevel = 0.0
            inboundAudioLevels = [0.0]
            outboundAudioLevels = [0.0]
            previousInboundLevel = 0.0
            previousOutboundLevel = 0.0
            return
        }
        
        // Update inbound levels with more responsive scaling and smoothing
        // Scale the audio level for better visualization (make it more sensitive)
        let rawInboundLevel = min(1.0, metrics.inboundAudioLevel * 4.0) // Increased sensitivity
        
        // Apply smoothing to prevent jarring jumps but keep responsiveness
        let smoothedInboundLevel = smoothAudioLevel(current: rawInboundLevel, previous: previousInboundLevel)
        previousInboundLevel = smoothedInboundLevel
        
        // Update current level (this is what the waveform will use)
        currentInboundAudioLevel = smoothedInboundLevel
        // Keep the array with just the current level for compatibility
        inboundAudioLevels = [smoothedInboundLevel]
        
        // Update outbound levels with more responsive scaling and smoothing
        // Scale the audio level for better visualization (make it more sensitive)
        let rawOutboundLevel = min(1.0, metrics.outboundAudioLevel * 4.0) // Increased sensitivity
        
        // Apply smoothing to prevent jarring jumps but keep responsiveness
        let smoothedOutboundLevel = smoothAudioLevel(current: rawOutboundLevel, previous: previousOutboundLevel)
        previousOutboundLevel = smoothedOutboundLevel
        
        // Update current level (this is what the waveform will use)
        currentOutboundAudioLevel = smoothedOutboundLevel
        // Keep the array with just the current level for compatibility
        outboundAudioLevels = [smoothedOutboundLevel]
    }
    
    /// Smooths audio level transitions for more natural waveform appearance
    /// - Parameters:
    ///   - current: Current audio level
    ///   - previous: Previous audio level
    /// - Returns: Smoothed audio level
    private func smoothAudioLevel(current: Float, previous: Float) -> Float {
        // Use different smoothing based on whether audio is increasing or decreasing
        // Faster response when audio is increasing (speaking starts)
        // Slower decay when audio is decreasing (speaking ends)
        if current > previous {
            // Quick response to new audio input
            let quickResponseFactor: Float = 0.1
            return previous * quickResponseFactor + current * (1.0 - quickResponseFactor)
        } else {
            // Slightly slower decay for natural look
            let slowDecayFactor: Float = 0.4
            return previous * slowDecayFactor + current * (1.0 - slowDecayFactor)
        }
    }
}
