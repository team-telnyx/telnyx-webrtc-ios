//
//  TelnyxCallReportCollector.swift
//  TelnyxRTC
//
//  Created by OpenClaw on 2026-02-09.
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//

import Foundation
import WebRTC

/// Configuration options for the call report collector
public struct CallReportConfig {
    /// Enable or disable call report collection
    public let enabled: Bool
    
    /// Interval in seconds for collecting call statistics
    public let interval: TimeInterval
    
    public init(enabled: Bool = true, interval: TimeInterval = 5.0) {
        self.enabled = enabled
        self.interval = interval
    }
}

/// Collects WebRTC statistics during a call and posts them to voice-sdk-proxy
/// at the end of the call for quality analysis and debugging.
///
/// Stats Collection Strategy (based on Twilio/Jitsi best practices):
/// - Collects stats at regular intervals (default 5 seconds)
/// - Stores cumulative values (packets, bytes) from WebRTC API
/// - Calculates averages for variable metrics (audio level, jitter, RTT)
/// - Uses in-memory buffer with size limits for long calls
/// - Posts aggregated stats to voice-sdk-proxy on call end
public class TelnyxCallReportCollector {
    
    // MARK: - Properties
    
    private let config: CallReportConfig
    private let logCollectorConfig: LogCollectorConfig
    private weak var peerConnection: RTCPeerConnection?
    private var timer: Timer?
    private var statsBuffer: [CallReportInterval] = []
    private var intervalStartTime: Date?
    private let callStartTime: Date
    private var callEndTime: Date?
    private let logCollector: TelnyxLogCollector?
    
    // Accumulated values for averaging within an interval
    private var intervalAudioLevels: (outbound: [Double], inbound: [Double]) = ([], [])
    private var intervalJitters: [Double] = []
    private var intervalRTTs: [Double] = []
    private var intervalBitrates: (outbound: [Double], inbound: [Double]) = ([], [])
    
    // Previous values for rate calculations
    private var previousStats = PreviousStats()
    
    // Maximum buffer size to prevent memory issues on long calls
    private let maxBufferSize = 360 // 30 minutes at 5-second intervals

    // Retry configuration for HTTP POST (aligned with Android)
    private let maxRetryAttempts = 3
    private let retryBaseDelay: TimeInterval = 1.0
    
    // MARK: - Initialization
    
    public init(config: CallReportConfig = CallReportConfig(), logCollectorConfig: LogCollectorConfig = LogCollectorConfig()) {
        self.config = config
        self.logCollectorConfig = logCollectorConfig
        self.callStartTime = Date()
        
        // Create log collector if enabled — start immediately to capture setup/negotiation logs
        if logCollectorConfig.enabled {
            self.logCollector = TelnyxLogCollector(config: logCollectorConfig)
            self.logCollector?.start()
        } else {
            self.logCollector = nil
        }
    }
    
    // MARK: - Public Methods
    
    /// Start collecting stats from the peer connection
    /// - Parameter peerConnection: The RTCPeerConnection to monitor
    public func start(peerConnection: RTCPeerConnection) {
        guard config.enabled else { return }
        
        self.peerConnection = peerConnection
        self.intervalStartTime = Date()
        
        Logger.log.i(message: "TelnyxCallReportCollector: Starting stats collection (interval: \(config.interval)s, logCollectorActive: \(logCollector?.isActive() ?? false))")

        logCollector?.addEntry(
            level: "info",
            message: "CallReportCollector: Starting stats and log collection",
            context: ["interval": AnyCodable(config.interval), "logLevel": AnyCodable(logCollectorConfig.level)]
        )

        // Schedule on main RunLoop — start() may be called from a WebRTC background thread
        // where RunLoop.current is not running, which would prevent the timer from firing.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.timer = Timer.scheduledTimer(withTimeInterval: self.config.interval, repeats: true) { [weak self] _ in
                self?.collectStats()
            }
        }
    }
    
    /// Stop collecting stats and prepare for final report
    public func stop() {
        // Timer was scheduled on main RunLoop, must invalidate there
        DispatchQueue.main.async { [weak self] in
            self?.timer?.invalidate()
            self?.timer = nil
        }
        
        callEndTime = Date()
        
        // Collect final stats before stopping
        if peerConnection != nil && intervalStartTime != nil {
            collectStats()
        }
        
        // Stop log collector
        let logCount = logCollector?.getLogCount() ?? 0
        logCollector?.stop()
        
        Logger.log.i(message: "TelnyxCallReportCollector: Stopped stats collection (totalIntervals: \(statsBuffer.count), totalLogs: \(logCount), duration: \(callEndTime?.timeIntervalSince(callStartTime) ?? 0)s)")
    }
    
    /// Post the collected stats to voice-sdk-proxy
    /// - Parameters:
    ///   - summary: Call summary information
    ///   - callReportId: Call report ID from REGED message
    ///   - host: WebSocket host URL (will be converted to HTTP)
    ///   - voiceSdkId: Optional voice SDK ID
    public func postReport(summary: CallReportSummary, callReportId: String, host: String, voiceSdkId: String? = nil) {
        guard config.enabled && !statsBuffer.isEmpty else {
            Logger.log.i(message: "TelnyxCallReportCollector: Skipping report post (enabled: \(config.enabled), stats: \(statsBuffer.count))")
            return
        }
        
        // Get collected logs
        let logs = logCollector?.getLogs()
        
        // Build the report payload
        let payload = CallReportPayload(
            summary: summary,
            stats: statsBuffer,
            logs: logs
        )
        
        // Derive HTTP endpoint from WebSocket URL
        guard let wsUrl = URL(string: host) else {
            Logger.log.e(message: "TelnyxCallReportCollector: Invalid host URL: \(host)")
            return
        }
        
        let scheme = wsUrl.scheme?.replacingOccurrences(of: "ws", with: "http") ?? "https"
        let endpoint = "\(scheme)://\(wsUrl.host ?? "rtc.telnyx.com")\(wsUrl.port.map { ":\($0)" } ?? "")/call_report"
        
        guard let endpointUrl = URL(string: endpoint) else {
            Logger.log.e(message: "TelnyxCallReportCollector: Failed to construct endpoint URL from: \(endpoint)")
            return
        }
        
        Logger.log.i(message: "TelnyxCallReportCollector: Posting report (endpoint: \(endpoint), intervals: \(statsBuffer.count), logEntries: \(logs?.count ?? 0), callId: \(summary.callId))")
        
        // Build request
        var request = URLRequest(url: endpointUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(callReportId, forHTTPHeaderField: "x-call-report-id")
        request.setValue(summary.callId, forHTTPHeaderField: "x-call-id")
        if let voiceSdkId = voiceSdkId {
            request.setValue(voiceSdkId, forHTTPHeaderField: "x-voice-sdk-id")
        }
        
        // Encode payload
        let jsonData: Data
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            jsonData = try encoder.encode(payload)
            request.httpBody = jsonData
        } catch {
            Logger.log.e(message: "TelnyxCallReportCollector: Failed to encode payload: \(error)")
            return
        }

        // Log the payload for debugging
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            Logger.log.i(message: "TelnyxCallReportCollector: Payload:\n\(jsonString)")
        }

        // Post with retry logic (aligned with Android: 3 attempts, exponential backoff, 5xx only)
        executeUpload(request: request, attempt: 1)
    }

    private func executeUpload(request: URLRequest, attempt: Int) {
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                Logger.log.e(message: "TelnyxCallReportCollector: Error posting report (attempt \(attempt)): \(error)")
                self.retryIfNeeded(request: request, attempt: attempt, statusCode: nil)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                self.cleanup()
                return
            }

            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                Logger.log.i(message: "TelnyxCallReportCollector: Successfully posted report (status: \(httpResponse.statusCode))")
                self.cleanup()
            } else {
                let errorText = data.flatMap { String(data: $0, encoding: .utf8) } ?? "No response body"
                Logger.log.e(message: "TelnyxCallReportCollector: Failed to post report (attempt \(attempt), status: \(httpResponse.statusCode), error: \(errorText))")
                self.retryIfNeeded(request: request, attempt: attempt, statusCode: httpResponse.statusCode)
            }
        }
        task.resume()
    }

    private func retryIfNeeded(request: URLRequest, attempt: Int, statusCode: Int?) {
        // Only retry on 5xx or network errors, not on 4xx
        if let code = statusCode, code >= 400 && code < 500 {
            Logger.log.e(message: "TelnyxCallReportCollector: Not retrying (client error \(code))")
            cleanup()
            return
        }

        guard attempt < maxRetryAttempts else {
            Logger.log.e(message: "TelnyxCallReportCollector: All \(maxRetryAttempts) upload attempts failed")
            cleanup()
            return
        }

        let delay = retryBaseDelay * pow(2.0, Double(attempt - 1))
        Logger.log.w(message: "TelnyxCallReportCollector: Retrying in \(delay)s (attempt \(attempt + 1)/\(maxRetryAttempts))")

        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.executeUpload(request: request, attempt: attempt + 1)
        }
    }
    
    /// Get the current stats buffer (for debugging)
    /// - Returns: Array of collected intervals
    public func getStatsBuffer() -> [CallReportInterval] {
        return statsBuffer
    }
    
    /// Get the collected logs (for debugging)
    /// - Returns: Array of log entries
    public func getLogs() -> [LogEntry] {
        return logCollector?.getLogs() ?? []
    }
    
    /// Clean up resources (call after postReport)
    public func cleanup() {
        logCollector?.clear()
    }
    
    // MARK: - Private Types

    private struct ParsedStats {
        let outbound: RTCOutboundRTPStreamStats?
        let inbound: RTCInboundRTPStreamStats?
        let candidate: RTCIceCandidatePairStats?
    }

    private struct PreviousStats {
        var timestamp: Double?
        var outboundBytes: Int?
        var inboundBytes: Int?
    }

    // MARK: - Private Methods

    /// Collect stats from the peer connection and aggregate them
    private func collectStats() {
        guard let peerConnection = peerConnection, let intervalStartTime = intervalStartTime else {
            return
        }

        peerConnection.statistics { [weak self] report in
            guard let self = self else { return }

            let now = Date()
            let parsed = self.parseStatsReport(report)
            self.accumulateSamples(parsed: parsed, statistics: report.statistics, now: now)

            // Check if interval is complete (end of collection period)
            let intervalDuration = now.timeIntervalSince(intervalStartTime)
            if intervalDuration >= self.config.interval {
                self.finalizeInterval(start: intervalStartTime, end: now, parsed: parsed)
            }
        }
    }

    private func parseStatsReport(_ report: RTCStatisticsReport) -> ParsedStats {
        var outboundAudio: RTCOutboundRTPStreamStats?
        var inboundAudio: RTCInboundRTPStreamStats?
        var candidatePair: RTCIceCandidatePairStats?

        for stats in report.statistics.values {
            switch stats.type {
            case "outbound-rtp":
                if let kind = stats.values["kind"] as? String, kind == "audio" {
                    outboundAudio = RTCOutboundRTPStreamStats(stats)
                }
            case "inbound-rtp":
                if let kind = stats.values["kind"] as? String, kind == "audio" {
                    inboundAudio = RTCInboundRTPStreamStats(stats)
                }
            case "candidate-pair":
                let nominated = stats.values["nominated"] as? Bool ?? false
                let state = stats.values["state"] as? String ?? ""
                if nominated || state == "succeeded" {
                    candidatePair = RTCIceCandidatePairStats(stats)
                }
            default:
                break
            }
        }
        return ParsedStats(outbound: outboundAudio, inbound: inboundAudio, candidate: candidatePair)
    }

    private func accumulateSamples(
        parsed: ParsedStats,
        statistics: [String: RTCStatistics],
        now: Date
    ) {
        if let outbound = parsed.outbound {
            if let audioLevel = getAudioLevel(from: statistics, trackId: outbound.trackId) {
                intervalAudioLevels.outbound.append(audioLevel)
            }
            if let prevBytes = previousStats.outboundBytes, let prevTimestamp = previousStats.timestamp {
                let bytesDelta = outbound.bytesSent - prevBytes
                let timeDelta = outbound.timestamp - prevTimestamp
                if timeDelta > 0 {
                    intervalBitrates.outbound.append(Double(bytesDelta * 8 * 1000) / timeDelta)
                }
            }
            previousStats.outboundBytes = outbound.bytesSent
        }

        if let inbound = parsed.inbound {
            if let audioLevel = getAudioLevel(from: statistics, trackId: inbound.trackId) {
                intervalAudioLevels.inbound.append(audioLevel)
            }
            if inbound.jitter > 0 {
                intervalJitters.append(inbound.jitter * 1000)
            }
            if let prevBytes = previousStats.inboundBytes, let prevTimestamp = previousStats.timestamp {
                let bytesDelta = inbound.bytesReceived - prevBytes
                let timeDelta = inbound.timestamp - prevTimestamp
                if timeDelta > 0 {
                    intervalBitrates.inbound.append(Double(bytesDelta * 8 * 1000) / timeDelta)
                }
            }
            previousStats.inboundBytes = inbound.bytesReceived
        }

        if let candidate = parsed.candidate, candidate.currentRoundTripTime > 0 {
            intervalRTTs.append(candidate.currentRoundTripTime)
        }

        previousStats.timestamp = parsed.outbound?.timestamp ?? parsed.inbound?.timestamp ?? now.timeIntervalSince1970 * 1000
    }

    private func finalizeInterval(start: Date, end: Date, parsed: ParsedStats) {
        let statsEntry = createStatsEntry(
            start: start,
            end: end,
            outboundAudio: parsed.outbound,
            inboundAudio: parsed.inbound,
            candidatePair: parsed.candidate
        )

        statsBuffer.append(statsEntry)
        if statsBuffer.count > maxBufferSize {
            statsBuffer.removeFirst()
            Logger.log.w(message: "TelnyxCallReportCollector: Buffer size limit reached, removing oldest entry")
        }

        // Log per-interval summary (like Android's "Audio sample recorded" Timber log)
        let jitterStr = statsEntry.audio?.inbound?.jitterAvg.map { String(format: "%.2f", $0) } ?? "n/a"
        let rttStr = statsEntry.connection?.roundTripTimeAvg.map { String(format: "%.4f", $0) } ?? "n/a"
        let outPkts = statsEntry.audio?.outbound?.packetsSent.map { "\($0)" } ?? "n/a"
        let inPkts = statsEntry.audio?.inbound?.packetsReceived.map { "\($0)" } ?? "n/a"
        let lost = statsEntry.audio?.inbound?.packetsLost.map { "\($0)" } ?? "n/a"
        Logger.log.i(message: "TelnyxCallReportCollector: Interval #\(statsBuffer.count) collected "
            + "(jitter: \(jitterStr)ms, rtt: \(rttStr)s, outPkts: \(outPkts), inPkts: \(inPkts), lost: \(lost))")

        intervalStartTime = end
        resetIntervalAccumulators()
    }
    
    /// Create a stats entry from accumulated values
    private func createStatsEntry(
        start: Date,
        end: Date,
        outboundAudio: RTCOutboundRTPStreamStats?,
        inboundAudio: RTCInboundRTPStreamStats?,
        candidatePair: RTCIceCandidatePairStats?
    ) -> CallReportInterval {
        let iso8601 = ISO8601DateFormatter()
        
        var audioStats: AudioStats?
        var outboundStats: OutboundAudioStats?
        var inboundStats: InboundAudioStats?
        
        if let outbound = outboundAudio {
            outboundStats = OutboundAudioStats(
                packetsSent: outbound.packetsSent,
                bytesSent: outbound.bytesSent,
                audioLevelAvg: average(intervalAudioLevels.outbound),
                bitrateAvg: average(intervalBitrates.outbound)
            )
        }
        
        if let inbound = inboundAudio {
            inboundStats = InboundAudioStats(
                packetsReceived: inbound.packetsReceived,
                bytesReceived: inbound.bytesReceived,
                packetsLost: inbound.packetsLost,
                packetsDiscarded: inbound.packetsDiscarded,
                jitterBufferDelay: inbound.jitterBufferDelay,
                jitterBufferEmittedCount: inbound.jitterBufferEmittedCount,
                totalSamplesReceived: inbound.totalSamplesReceived,
                concealedSamples: inbound.concealedSamples,
                concealmentEvents: inbound.concealmentEvents,
                audioLevelAvg: average(intervalAudioLevels.inbound),
                jitterAvg: average(intervalJitters),
                bitrateAvg: average(intervalBitrates.inbound)
            )
        }
        
        if outboundStats != nil || inboundStats != nil {
            audioStats = AudioStats(outbound: outboundStats, inbound: inboundStats)
        }
        
        var connectionStats: ConnectionStats?
        if let candidate = candidatePair {
            connectionStats = ConnectionStats(
                roundTripTimeAvg: average(intervalRTTs),
                packetsSent: candidate.packetsSent,
                packetsReceived: candidate.packetsReceived,
                bytesSent: candidate.bytesSent,
                bytesReceived: candidate.bytesReceived
            )
        }
        
        return CallReportInterval(
            intervalStartUtc: iso8601.string(from: start),
            intervalEndUtc: iso8601.string(from: end),
            audio: audioStats,
            connection: connectionStats
        )
    }
    
    /// Get audio level from track stats
    private func getAudioLevel(from statistics: [String: RTCStatistics], trackId: String?) -> Double? {
        guard let trackId = trackId, let trackStats = statistics[trackId] else {
            return nil
        }
        
        return trackStats.values["audioLevel"] as? Double
    }
    
    /// Calculate average of an array of numbers
    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sum = values.reduce(0, +)
        return Double(String(format: "%.4f", sum / Double(values.count)))
    }
    
    /// Reset interval accumulators for next collection period
    private func resetIntervalAccumulators() {
        intervalAudioLevels = ([], [])
        intervalJitters = []
        intervalRTTs = []
        intervalBitrates = ([], [])
    }
}

// MARK: - Helper Structs for RTCStatistics Parsing

private struct RTCOutboundRTPStreamStats {
    let packetsSent: Int
    let bytesSent: Int
    let trackId: String?
    let timestamp: Double
    
    init(_ stats: RTCStatistics) {
        self.packetsSent = stats.values["packetsSent"] as? Int ?? 0
        self.bytesSent = stats.values["bytesSent"] as? Int ?? 0
        self.trackId = stats.values["trackId"] as? String
        self.timestamp = stats.timestamp_us / 1000.0
    }
}

private struct RTCInboundRTPStreamStats {
    let packetsReceived: Int
    let bytesReceived: Int
    let packetsLost: Int
    let packetsDiscarded: Int?
    let jitter: Double
    let jitterBufferDelay: Double?
    let jitterBufferEmittedCount: Int?
    let totalSamplesReceived: Int?
    let concealedSamples: Int?
    let concealmentEvents: Int?
    let trackId: String?
    let timestamp: Double
    
    init(_ stats: RTCStatistics) {
        self.packetsReceived = stats.values["packetsReceived"] as? Int ?? 0
        self.bytesReceived = stats.values["bytesReceived"] as? Int ?? 0
        self.packetsLost = stats.values["packetsLost"] as? Int ?? 0
        self.packetsDiscarded = stats.values["packetsDiscarded"] as? Int
        self.jitter = stats.values["jitter"] as? Double ?? 0
        self.jitterBufferDelay = stats.values["jitterBufferDelay"] as? Double
        self.jitterBufferEmittedCount = stats.values["jitterBufferEmittedCount"] as? Int
        self.totalSamplesReceived = stats.values["totalSamplesReceived"] as? Int
        self.concealedSamples = stats.values["concealedSamples"] as? Int
        self.concealmentEvents = stats.values["concealmentEvents"] as? Int
        self.trackId = stats.values["trackId"] as? String
        self.timestamp = stats.timestamp_us / 1000.0
    }
}

private struct RTCIceCandidatePairStats {
    let packetsSent: Int?
    let packetsReceived: Int?
    let bytesSent: Int?
    let bytesReceived: Int?
    let currentRoundTripTime: Double
    
    init(_ stats: RTCStatistics) {
        self.packetsSent = stats.values["packetsSent"] as? Int
        self.packetsReceived = stats.values["packetsReceived"] as? Int
        self.bytesSent = stats.values["bytesSent"] as? Int
        self.bytesReceived = stats.values["bytesReceived"] as? Int
        self.currentRoundTripTime = stats.values["currentRoundTripTime"] as? Double ?? 0
    }
}
