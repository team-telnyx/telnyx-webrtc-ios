import Foundation
import WebRTC
import Network

class NetworkQualityMonitor {
    static let shared = NetworkQualityMonitor()
    
    private var rttHistory: [Double] = []
    private var jitterHistory: [Double] = []
    private var packetLossHistory: [Double] = []
    private let maxHistorySize = 10
    
    // Thresholds for network quality detection
    private let goodRttThreshold: Double = 0.1 // 100ms
    private let poorRttThreshold: Double = 0.5 // 500ms
    private let improvementThreshold: Double = 0.3 // 300ms improvement
    
    private var lastNetworkQuality: NetworkQuality = .unknown
    private var isMonitoring = false
    private var lastNetworkType: NWInterface.InterfaceType?
    private var networkPathMonitor: NWPathMonitor?
    private var networkQueue = DispatchQueue(label: "NetworkMonitor")
    
    // ICE restart state
    private var lastICERestartTime: Date?
    private let minICERestartInterval: TimeInterval = 30 // 30 seconds minimum between restarts
    
    enum NetworkQuality {
        case excellent
        case good
        case fair
        case poor
        case unknown
    }
    
    var onNetworkQualityChange: ((NetworkQuality) -> Void)?
    var onNetworkImprovementDetected: (() -> Void)?
    
    private init() {
        setupNetworkPathMonitoring()
    }
    
    func startMonitoring() {
        isMonitoring = true
        rttHistory.removeAll()
    }
    
    func stopMonitoring() {
        isMonitoring = false
        rttHistory.removeAll()
    }
    
    func updateNetworkMetrics(rtt: Double, jitter: Double, packetLoss: Double) {
        guard isMonitoring else { return }
        
        // Add to history
        rttHistory.append(rtt)
        jitterHistory.append(jitter)
        packetLossHistory.append(packetLoss)
        
        // Keep history size manageable
        if rttHistory.count > maxHistorySize {
            rttHistory.removeFirst()
            jitterHistory.removeFirst()
            packetLossHistory.removeFirst()
        }
        
        // Need at least 3 samples for reliable detection
        guard rttHistory.count >= 3 else { return }
        
        // Calculate averages
        let avgRTT = rttHistory.reduce(0, +) / Double(rttHistory.count)
        let avgJitter = jitterHistory.reduce(0, +) / Double(jitterHistory.count)
        let avgPacketLoss = packetLossHistory.reduce(0, +) / Double(packetLossHistory.count)
        
        Logger.log.i(message: "NetworkQualityMonitor:: Metrics - RTT: \(avgRTT * 1000)ms, Jitter: \(avgJitter * 1000)ms, PacketLoss: \(avgPacketLoss)%")
        
        // Detect network improvement using multiple indicators
        if detectNetworkImprovement(avgRTT: avgRTT, avgJitter: avgJitter, avgPacketLoss: avgPacketLoss) {
            Logger.log.i(message: "NetworkQualityMonitor:: Network improvement detected! Triggering ICE restart...")
            onNetworkImprovementDetected?()
        }
        
        // Update quality for general monitoring
        let currentQuality = determineNetworkQuality(avgRTT)
        if currentQuality != lastNetworkQuality {
            lastNetworkQuality = currentQuality
            onNetworkQualityChange?(currentQuality)
        }
    }
    
    func updateRTT(_ rtt: Double) {
        // Legacy method for backward compatibility
        updateNetworkMetrics(rtt: rtt, jitter: 0, packetLoss: 0)
    }
    
    private func determineNetworkQuality(_ rtt: Double) -> NetworkQuality {
        switch rtt {
        case 0..<goodRttThreshold:
            return .excellent
        case goodRttThreshold..<0.2:
            return .good
        case 0.2..<0.4:
            return .fair
        case 0.4..<poorRttThreshold:
            return .poor
        default:
            return .poor
        }
    }
    
    private func shouldTriggerICEUpdate(currentQuality: NetworkQuality, previousQuality: NetworkQuality) -> Bool {
        // Trigger ICE update if we've improved from poor to good or better
        switch (previousQuality, currentQuality) {
        case (.poor, .excellent), (.poor, .good), (.fair, .excellent):
            return true
        case (.unknown, .excellent), (.unknown, .good):
            return true
        default:
            return false
        }
    }
    
    func getCurrentQuality() -> NetworkQuality {
        return lastNetworkQuality
    }
    
    func getAverageRTT() -> Double {
        guard !rttHistory.isEmpty else { return 0 }
        return rttHistory.reduce(0, +) / Double(rttHistory.count)
    }
    
    // MARK: - Network Improvement Detection
    
    private func detectNetworkImprovement(avgRTT: Double, avgJitter: Double, avgPacketLoss: Double) -> Bool {
        // Check if enough time has passed since last ICE restart
        if let lastRestart = lastICERestartTime,
           Date().timeIntervalSince(lastRestart) < minICERestartInterval {
            return false
        }
        
        // Detect improvement based on multiple indicators
        let rttImprovement = detectRTTImprovement(avgRTT)
        let jitterImprovement = detectJitterImprovement(avgJitter)
        let packetLossImprovement = detectPacketLossImprovement(avgPacketLoss)
        let networkTypeChange = detectNetworkTypeChange()
        
        // Trigger ICE restart if we detect significant improvement
        let shouldRestart = rttImprovement || jitterImprovement || packetLossImprovement || networkTypeChange
        
        if shouldRestart {
            lastICERestartTime = Date()
            Logger.log.i(message: "NetworkQualityMonitor:: ICE restart triggered - RTT: \(rttImprovement), Jitter: \(jitterImprovement), PacketLoss: \(packetLossImprovement), NetworkType: \(networkTypeChange)")
        }
        
        return shouldRestart
    }
    
    private func detectRTTImprovement(_ avgRTT: Double) -> Bool {
        // Look for significant RTT improvement in recent samples
        guard rttHistory.count >= 3 else { return false }
        
        let recentRTT = Array(rttHistory.suffix(2))
        let olderRTT = Array(rttHistory.prefix(rttHistory.count - 2))
        
        let recentAvg = recentRTT.reduce(0, +) / Double(recentRTT.count)
        let olderAvg = olderRTT.reduce(0, +) / Double(olderRTT.count)
        
        // More sensitive detection: look for RTT improvement from high to low values
        let improvement = olderAvg - recentAvg
        let wasHighRTT = olderAvg > 0.5  // Was RTT > 500ms
        let isLowRTT = recentAvg < 0.2   // Is RTT < 200ms
        let significantImprovement = improvement > 0.2 || (wasHighRTT && isLowRTT)
        
        Logger.log.i(message: "NetworkQualityMonitor:: RTT improvement check - Older: \(olderAvg * 1000)ms, Recent: \(recentAvg * 1000)ms, Improvement: \(improvement * 1000)ms, WasHigh: \(wasHighRTT), IsLow: \(isLowRTT), Significant: \(significantImprovement)")
        
        return significantImprovement
    }
    
    private func detectJitterImprovement(_ avgJitter: Double) -> Bool {
        // Look for significant jitter improvement
        guard jitterHistory.count >= 5 else { return false }
        
        let recentJitter = Array(jitterHistory.suffix(3))
        let olderJitter = Array(jitterHistory.prefix(jitterHistory.count - 3))
        
        let recentAvg = recentJitter.reduce(0, +) / Double(recentJitter.count)
        let olderAvg = olderJitter.reduce(0, +) / Double(olderJitter.count)
        
        // Significant improvement: recent jitter is much better than older jitter
        let improvement = olderAvg - recentAvg
        let significantImprovement = improvement > 0.05 // 50ms improvement
        
        Logger.log.i(message: "NetworkQualityMonitor:: Jitter improvement check - Older: \(olderAvg * 1000)ms, Recent: \(recentAvg * 1000)ms, Improvement: \(improvement * 1000)ms, Significant: \(significantImprovement)")
        
        return significantImprovement
    }
    
    private func detectPacketLossImprovement(_ avgPacketLoss: Double) -> Bool {
        // Look for significant packet loss improvement
        guard packetLossHistory.count >= 5 else { return false }
        
        let recentLoss = Array(packetLossHistory.suffix(3))
        let olderLoss = Array(packetLossHistory.prefix(packetLossHistory.count - 3))
        
        let recentAvg = recentLoss.reduce(0, +) / Double(recentLoss.count)
        let olderAvg = olderLoss.reduce(0, +) / Double(olderLoss.count)
        
        // Significant improvement: recent packet loss is much better than older
        let improvement = olderAvg - recentAvg
        let significantImprovement = improvement > 5.0 // 5% improvement
        
        Logger.log.i(message: "NetworkQualityMonitor:: Packet loss improvement check - Older: \(olderAvg)%, Recent: \(recentAvg)%, Improvement: \(improvement)%, Significant: \(significantImprovement)")
        
        return significantImprovement
    }
    
    private func detectNetworkTypeChange() -> Bool {
        // Check if network type changed (e.g., cellular to WiFi)
        guard let currentType = getCurrentNetworkType() else { return false }
        
        if let lastType = lastNetworkType, lastType != currentType {
            Logger.log.i(message: "NetworkQualityMonitor:: Network type changed from \(lastType) to \(currentType)")
            lastNetworkType = currentType
            return true
        }
        
        lastNetworkType = currentType
        return false
    }
    
    private func getCurrentNetworkType() -> NWInterface.InterfaceType? {
        // This would need to be implemented based on your network monitoring setup
        // For now, return nil to disable this check
        return nil
    }
    
    // MARK: - Network Path Monitoring
    
    private func setupNetworkPathMonitoring() {
        networkPathMonitor = NWPathMonitor()
        networkPathMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handleNetworkPathUpdate(path)
            }
        }
        networkPathMonitor?.start(queue: networkQueue)
    }
    
    private func handleNetworkPathUpdate(_ path: NWPath) {
        let currentType = path.availableInterfaces.first?.type
        
        if let type = currentType, type != lastNetworkType {
            Logger.log.i(message: "NetworkQualityMonitor:: Network path changed to \(type)")
            lastNetworkType = type
            
            // Trigger ICE restart on network type change
            if isMonitoring {
                onNetworkImprovementDetected?()
            }
        }
    }
    
    deinit {
        networkPathMonitor?.cancel()
    }
}
