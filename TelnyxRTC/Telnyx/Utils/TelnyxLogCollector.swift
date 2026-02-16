//
//  TelnyxLogCollector.swift
//  TelnyxRTC
//
//  Created by OpenClaw on 2026-02-09.
//  Copyright © 2026 Telnyx LLC. All rights reserved.
//

import Foundation

/// Configuration options for the log collector
public struct LogCollectorConfig {
    /// Enable or disable log collection
    public let enabled: Bool
    
    /// Minimum log level to capture ("debug", "info", "warn", "error")
    public let level: String
    
    /// Maximum number of log entries to buffer
    public let maxEntries: Int
    
    public init(enabled: Bool = true, level: String = "debug", maxEntries: Int = 1000) {
        self.enabled = enabled
        self.level = level
        self.maxEntries = maxEntries
    }
}

/// Collects debug logs during a call for inclusion in call reports
public class TelnyxLogCollector {
    
    // MARK: - Properties
    
    private let config: LogCollectorConfig
    private var buffer: [LogEntry] = []
    private var isCapturing: Bool = false
    private let lock = NSLock()
    
    private let levelPriority: [String: Int] = [
        "debug": 0,
        "info": 1,
        "warn": 2,
        "error": 3,
    ]
    
    // MARK: - Initialization
    
    public init(config: LogCollectorConfig = LogCollectorConfig()) {
        self.config = config
    }
    
    // MARK: - Public Methods
    
    /// Start capturing logs
    public func start() {
        guard config.enabled else { return }
        
        lock.lock()
        defer { lock.unlock() }
        
        isCapturing = true
        buffer.removeAll()
        Logger.log.i(message: "TelnyxLogCollector: Started capturing logs")
    }
    
    /// Stop capturing logs
    public func stop() {
        lock.lock()
        defer { lock.unlock() }
        
        isCapturing = false
        Logger.log.i(message: "TelnyxLogCollector: Stopped capturing logs (captured \(buffer.count) entries)")
    }
    
    /// Add a log entry if capturing is active and level passes filter
    /// - Parameters:
    ///   - level: Log level ("debug", "info", "warn", "error")
    ///   - message: Log message
    ///   - context: Optional context dictionary
    public func addEntry(level: String, message: String, context: [String: Any]? = nil) {
        lock.lock()
        defer { lock.unlock() }
        
        guard isCapturing && config.enabled else { return }
        
        // Check if level passes the filter
        let currentLevelPriority = levelPriority[level.lowercased()] ?? 0
        let configLevelPriority = levelPriority[config.level.lowercased()] ?? 0
        
        guard currentLevelPriority >= configLevelPriority else { return }
        
        // Convert context to AnyCodable if present
        let anyCodableContext = context?.mapValues { AnyCodable($0) }
        
        let entry = LogEntry(
            timestamp: ISO8601DateFormatter().string(from: Date()),
            level: level.lowercased(),
            message: message,
            context: anyCodableContext
        )
        
        buffer.append(entry)
        
        // Enforce max buffer size (remove oldest entries)
        if buffer.count > config.maxEntries {
            buffer.removeFirst(buffer.count - config.maxEntries)
        }
    }
    
    /// Get all collected logs (non-destructive)
    /// - Returns: Array of log entries
    public func getLogs() -> [LogEntry] {
        lock.lock()
        defer { lock.unlock() }

        return buffer
    }

    /// Atomically returns all logs and clears the buffer.
    /// Used by intermediate flushes so logs are not re-sent.
    /// - Returns: Array of log entries that were in the buffer
    public func drain() -> [LogEntry] {
        lock.lock()
        defer { lock.unlock() }
        let entries = buffer
        buffer.removeAll()
        return entries
    }
    
    /// Get the number of collected logs
    /// - Returns: Number of log entries in buffer
    public func getLogCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        
        return buffer.count
    }
    
    /// Clear the buffer
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        
        buffer.removeAll()
    }
    
    /// Check if collector is currently capturing
    /// - Returns: True if capturing, false otherwise
    public func isActive() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        return isCapturing
    }
    
    /// Check if collector is enabled
    /// - Returns: True if enabled, false otherwise
    public func isEnabled() -> Bool {
        return config.enabled
    }
}
