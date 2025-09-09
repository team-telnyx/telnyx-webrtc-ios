import Foundation
import WebRTC
import AVFoundation

class CallQualityOptimizer {
    static let shared = CallQualityOptimizer()
    
    let enabled = true
    
    let avg_bitrate = 16000
    let minptime = 20
    let ptime = 40
    
    private var networkQualityMonitor = NetworkQualityMonitor.shared
    private var currentPeerConnection: RTCPeerConnection?
    private var isAudioResetInProgress = false
    
    func improveRTCConfig(_ config: RTCConfiguration) {
        if !enabled { return }
        
        config.enableDscp = true
        config.audioJitterBufferMaxPackets = 8
        config.audioJitterBufferFastAccelerate = true
    }
    
    func adjustBitrate(for pc: RTCPeerConnection) {
        if !enabled { return }
        
        guard let sender = pc.senders.first(where: { $0.track?.kind == "audio" }) else { return }
        let params = sender.parameters
        guard !params.encodings.isEmpty else { return }
        Logger.log.i(message: "Peer:: Adjusting Bitrate was \(String(describing: params.encodings[0].maxBitrateBps)) -> \(avg_bitrate)")
        
        params.encodings[0].maxBitrateBps = NSNumber(value: avg_bitrate)
        sender.parameters = params
    }
    
    func startNetworkMonitoring(for pc: RTCPeerConnection) {
        if !enabled { return }
        
        currentPeerConnection = pc
        networkQualityMonitor.startMonitoring()
        
        // Set up network improvement detection callback
        networkQualityMonitor.onNetworkImprovementDetected = { [weak self] in
            self?.handleNetworkImprovementDetected()
        }
        
        // Set up network quality change callback for general monitoring
        networkQualityMonitor.onNetworkQualityChange = { quality in
            Logger.log.i(message: "CallQualityOptimizer:: Network quality changed to \(quality)")
        }
        
        Logger.log.i(message: "CallQualityOptimizer:: Started network quality monitoring")
    }
    
    func stopNetworkMonitoring() {
        networkQualityMonitor.stopMonitoring()
        currentPeerConnection = nil
        isAudioResetInProgress = false
        Logger.log.i(message: "CallQualityOptimizer:: Stopped network quality monitoring")
    }
    
    func updateNetworkMetrics(rtt: Double, jitter: Double, packetLoss: Double = 0) {
        if !enabled { return }
        
        networkQualityMonitor.updateNetworkMetrics(rtt: rtt, jitter: jitter, packetLoss: packetLoss)
        Logger.log.i(message: "CallQualityOptimizer:: Updated metrics - RTT: \(rtt * 1000)ms, Jitter: \(jitter * 1000)ms, PacketLoss: \(packetLoss)%")
    }
    
    private func handleNetworkImprovementDetected() {
        guard let pc = currentPeerConnection, !isAudioResetInProgress else { return }
        
        Logger.log.i(message: "CallQualityOptimizer:: Network improvement detected! Resetting audio device to clear jitter buffers...")
        
        // Reset audio device to clear jitter buffers instead of ICE restart
        resetAudioDeviceAndClearBuffers(for: pc)
    }
    
    private func resetAudioDeviceAndClearBuffers(for pc: RTCPeerConnection) {
        guard !isAudioResetInProgress else { return }
        
        isAudioResetInProgress = true
        
        Logger.log.i(message: "CallQualityOptimizer:: Starting audio device reset to clear jitter buffers...")
        
        self.forceResetAudioDevice()
        
//        // Additional ultra-aggressive reset for persistent delays
//        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
//            self.ultraAggressiveReset()
//        }
        
        Logger.log.i(message: "CallQualityOptimizer:: Audio device reset completed successfully")
        isAudioResetInProgress = false
    }
    
    private func forceResetAudioDevice() {
        Logger.log.i(message: "CallQualityOptimizer:: Force resetting audio device...")
        
        // Execute 3 reset cycles sequentially
        executeResetCycle(cycle: 1, totalCycles: 3)
    }
    
    private func executeResetCycle(cycle: Int, totalCycles: Int) {
        Logger.log.i(message: "CallQualityOptimizer:: Executing reset cycle \(cycle)/\(totalCycles)...")
        
        let rtcAudioSession = RTCAudioSession.sharedInstance()
        let audioSession = AVAudioSession.sharedInstance()
        
        // Step 1: Deactivate audio device
        Logger.log.i(message: "CallQualityOptimizer:: Cycle \(cycle) - Deactivating audio device...")
        rtcAudioSession.audioSessionDidDeactivate(audioSession)
        rtcAudioSession.isAudioEnabled = false
        
        // Step 2: Deactivate audio session
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            Logger.log.i(message: "CallQualityOptimizer:: Cycle \(cycle) - Audio session deactivated")
        } catch {
            Logger.log.e(message: "CallQualityOptimizer:: Cycle \(cycle) - Failed to deactivate audio session: \(error)")
        }
        
        // Step 3: Wait for buffers to clear (increasing wait time per cycle)
        let waitTime = Double(cycle) * 1  // 0.5s, 1.0s, 1.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
            // Step 4: Reactivate with fresh configuration
            Logger.log.i(message: "CallQualityOptimizer:: Cycle \(cycle) - Reactivating with fresh configuration...")
            
            do {
                try audioSession.setCategory(.playAndRecord, 
                                           mode: .voiceChat, 
                                           options: [.allowBluetooth, .duckOthers])
                try audioSession.setActive(true)
                Logger.log.i(message: "CallQualityOptimizer:: Cycle \(cycle) - Audio session reactivated")
            } catch {
                Logger.log.e(message: "CallQualityOptimizer:: Cycle \(cycle) - Failed to reactivate audio session: \(error)")
            }
            
            // Step 5: Re-enable RTC audio session
            rtcAudioSession.audioSessionDidActivate(audioSession)
            rtcAudioSession.isAudioEnabled = true
            
            Logger.log.i(message: "CallQualityOptimizer:: Cycle \(cycle) - Completed")
            
            // Step 6: Execute next cycle or finish
            if cycle < totalCycles {
                // Wait a bit before next cycle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.executeResetCycle(cycle: cycle + 1, totalCycles: totalCycles)
                }
            } else {
                Logger.log.i(message: "CallQualityOptimizer:: All reset cycles completed successfully")
            }
        }
    }
    
    
    private func softResetAudioSession() {
        Logger.log.i(message: "CallQualityOptimizer:: Soft resetting audio session...")
        
        // Soft reset without deactivating the audio session to preserve call
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Only reconfigure the audio session without deactivating
            try audioSession.setCategory(.playAndRecord, 
                                       mode: .voiceChat, 
                                       options: [.allowBluetooth, .duckOthers])
            
            // Force audio session to refresh its configuration
            try audioSession.setPreferredSampleRate(16000)
            try audioSession.setPreferredIOBufferDuration(0.005) // 5ms buffer for low latency
            
            Logger.log.i(message: "CallQualityOptimizer:: Audio session soft reset completed")
        } catch {
            Logger.log.e(message: "CallQualityOptimizer:: Failed to soft reset audio session: \(error)")
        }
    }
    
    func optimizeSDP(_ original: RTCSessionDescription) -> RTCSessionDescription {
        if !enabled { return original }
        
        Logger.log.i(message: "Peer:: SDP Original:\n\(original.sdp)")
        
        let optimized = optimizeForWorstCase(original.sdp)
        let validation = validateOptimizedSDP(optimized)
        
        if !validation.isValid {
            Logger.log.i(message: "Peer:: SDP Optimization Warning: \(validation.issues.joined(separator: ", "))")
            Logger.log.i(message: optimized)
            // Return original if validation fails
            return original
        }
        
        Logger.log.i(message: "Peer:: SDP Optimization Succeeded\n\(optimized)")
        return RTCSessionDescription(type: original.type, sdp: optimized)
    }
    
    private func optimizeForWorstCase(_ originalSDP: String) -> String {
        let lines = originalSDP.components(separatedBy: "\r\n")
        var processedLines: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Ultra-conservative Opus settings optimized for extreme cellular conditions
            if trimmedLine.hasPrefix("a=fmtp:111") {
                // Extreme cellular optimization: handles 1sec+ RTT, network switching
                processedLines.append("a=fmtp:111 minptime=\(minptime);useinbandfec=1;usedtx=0;maxaveragebitrate=\(avg_bitrate);maxplaybackrate=\(avg_bitrate);stereo=0;sprop-stereo=0;cbr=1")
            }
            // Change Opus sample rate from 48000 to 16000 to match bitrate
            else if trimmedLine.contains("opus/48000") {
                processedLines.append(trimmedLine.replacingOccurrences(of: "opus/48000", with: "opus/16000"))
            }
            // Change telephone-event sample rate from 48000 to 16000 to match Opus
            else if trimmedLine.contains("telephone-event/48000") {
                processedLines.append(trimmedLine.replacingOccurrences(of: "telephone-event/48000", with: "telephone-event/16000"))
            }
            // Keep all other essential SDP attributes
            else {
                processedLines.append(trimmedLine)
            }
        }
        
        // Use the original separator when rejoining
        return processedLines.joined(separator: "\r\n")
    }
    
    /// Validation function to ensure the optimized SDP maintains essential functionality
    private func validateOptimizedSDP(_ sdp: String) -> (isValid: Bool, issues: [String]) {
        let lines = sdp.components(separatedBy: .newlines)
        var issues: [String] = []
        
        // Check for essential components
        let hasVersion = lines.contains { $0.hasPrefix("v=") }
        let hasOrigin = lines.contains { $0.hasPrefix("o=") }
        let hasMedia = lines.contains { $0.hasPrefix("m=audio") }
        let hasOpus = lines.contains { $0.contains("opus/16000") }
        let hasPCMU = lines.contains { $0.contains("PCMU/8000") }
        let hasDTMF = lines.contains { $0.contains("telephone-event/16000") } ||
        lines.contains { $0.contains("telephone-event/8000") }
        let hasICE = lines.contains { $0.hasPrefix("a=ice-ufrag") }
        let hasBitrateLimit = lines.contains { $0.contains("maxaveragebitrate") }
        
        if !hasVersion { issues.append("Missing version line") }
        if !hasOrigin { issues.append("Missing origin line") }
        if !hasMedia { issues.append("Missing audio media line") }
        if !hasOpus { issues.append("Missing Opus codec") }
        if !hasPCMU { issues.append("Missing PCMU fallback codec") }
        if !hasDTMF { issues.append("Missing DTMF support") }
        if !hasICE { issues.append("Missing ICE credentials") }
        if !hasBitrateLimit { issues.append("Missing bitrate optimization") }
        
        return (isValid: issues.isEmpty, issues: issues)
    }
}
