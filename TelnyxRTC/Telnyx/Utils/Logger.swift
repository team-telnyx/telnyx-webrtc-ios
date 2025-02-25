//
//  Logger.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 29/03/2021.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
//

import Foundation

/// Available Log levels:
/// - `none`: Print no messages
/// - `error`: Message of level `error`
/// - `warning`: Message of level `warning`
/// - `success`: Message of level `success`
/// - `info`: Message of level `info`
/// - `verto`: Message of level `verto` messages.
/// - `all`:  Will print all level of messages
public enum LogLevel: Int {
    /// Disable logs. SDK logs will not printed. This is the default configuration.
    case none = 0
    /// Print `error` logs only
    case error
    /// Print `warning` logs only
    case warning
    /// Print `success` logs only
    case success
    /// Print `info` logs only
    case info
    /// Print `verto` messages. Incoming and outgoing verto messages are printed.
    case verto
    /// Print `Debug Report` messages. Statistics of the RTCP connection
    case stats
    /// All the SDK logs are printed.
    case all
}

class Timestamp {
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS "
        return formatter
    }()

    func printTimestamp() {
        print(dateFormatter.string(from: Date()))
    }
    
    func getTimestamp() -> String {
        return dateFormatter.string(from: Date())
    }
}

enum VertoDirection: Int {
    case inbound = 0
    case outbound
    case none
}

class Logger {

    internal static let log = Logger()

    /// represents the current log level: `all` is set as default
    internal var verboseLevel: LogLevel = .all
    
    /// Custom logger implementation for handling log messages
    internal var customLogger: TxLogger?

    private var statsGlyph: String = "\u{1F4CA}"     // Glyph for messages of level .Stats

    private var rightArrowGlyph: String = "\u{25B6}"
    private var leftArrowGlyph: String = "\u{25C0}"

    private var errorGlyph: String = "\u{1F6AB}"    // Glyph for messages of level .Error
    private var warningGlyph: String = "\u{1F514}"  // Glyph for messages of level .Warning
    private var successGlyph: String = "\u{2705}"   // Glyph for messages of level .Success
    private var infoGlyph: String = "\u{1F535}"     // Glyph for messages of level .Info
    private var timeStamp:Timestamp = Timestamp()
    
    private init() {
        customLogger = TxDefaultLogger()
    }


    /// Prints information messages if `verboseLevel` is set to `.all` or `.info`
    /// - Parameter message: message to be printed
    public func i(message: String) {
        if verboseLevel == .all || verboseLevel == .info {
            customLogger?.log(level: .info, tag: "TxClient", message: message, timestamp: Date(), vertoDirection: nil)
        }
    }

    /// Prints Error messages if `verboseLevel` is set to `.all` or `.error`
    /// - Parameter message: message to be printed
    public func e(message: String) {
        if verboseLevel == .all || verboseLevel == .error {
            customLogger?.log(level: .error, tag: "TxClient", message: message, timestamp: Date(), vertoDirection: nil)
        }
    }

    /// Prints Warning messages if `verboseLevel` is set to `.all` or `.warning`
    /// - Parameter message: message to be printed
    public func w(message: String) {
        if verboseLevel == .all || verboseLevel == .warning {
            customLogger?.log(level: .warning, tag: "TxClient", message: message, timestamp: Date(), vertoDirection: nil)
        }
    }

    /// Prints Success messages if `verboseLevel` is set to `.all` or `.success`
    /// - Parameter message: message to be printed
    public func s(message: String) {
        if verboseLevel == .all || verboseLevel == .success {
            customLogger?.log(level: .success, tag: "TxClient", message: message, timestamp: Date(), vertoDirection: nil)
        }
    }

    /// Prints Success messages if `verboseLevel` is set to `.all` or `.verto`
    /// - Parameters:
    ///   - message: message to be printed
    ///   - direction: direction of the message. Inbound-outbound
    public func verto(message: String, direction: VertoDirection) {
        if verboseLevel == .all || verboseLevel == .verto {
            customLogger?.log(level: .verto, tag: "TxClient", message: message, timestamp: Date(), vertoDirection: direction)
        }
    }
    
    public func stats(message: String) {
        if verboseLevel == .all || verboseLevel == .stats {
            customLogger?.log(level: .stats, tag: "TxClient", message: message, timestamp: Date(), vertoDirection: nil)
        }
    }

    private func getLogGlyph(level: LogLevel, direction: VertoDirection = .none) -> String {
        switch(level) {
        case .verto: return direction == .inbound ? leftArrowGlyph : rightArrowGlyph
        case .all: return ""
        case .none: return ""
        case .error: return errorGlyph
        case .info: return infoGlyph
        case .success: return successGlyph
        case .warning: return warningGlyph
        case .stats: return statsGlyph
        }
    }

    private func buildMessage(level: LogLevel, message: String, direction: VertoDirection = .none) -> String {
        return getLogGlyph(level: level, direction: direction) + " " + message + "\n"
    }
}

