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

    private static let TAG = "TxClient"
    
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
            let fullMessage = buildMessage(level: .info, message: message, direction: .none)
            customLogger?.log(level: .info, message: fullMessage)
        }
    }

    /// Prints Error messages if `verboseLevel` is set to `.all` or `.error`
    /// - Parameter message: message to be printed
    public func e(message: String) {
        if verboseLevel == .all || verboseLevel == .error {
            let fullMessage = buildMessage(level: .error, message: message, direction: .none)
            customLogger?.log(level: .error, message: fullMessage)
        }
    }

    /// Prints Warning messages if `verboseLevel` is set to `.all` or `.warning`
    /// - Parameter message: message to be printed
    public func w(message: String) {
        if verboseLevel == .all || verboseLevel == .warning {
            let fullMessage = buildMessage(level: .warning, message: message, direction: .none)
            customLogger?.log(level: .warning, message: fullMessage)
        }
    }

    /// Prints Success messages if `verboseLevel` is set to `.all` or `.success`
    /// - Parameter message: message to be printed
    public func s(message: String) {
        if verboseLevel == .all || verboseLevel == .success {
            let fullMessage = buildMessage(level: .warning, message: message, direction: .none)
            customLogger?.log(level: .success, message: fullMessage)
        }
    }

    /// Prints Success messages if `verboseLevel` is set to `.all` or `.verto`
    /// - Parameters:
    ///   - message: message to be printed
    ///   - direction: direction of the message. Inbound-outbound
    public func verto(message: String, direction: VertoDirection) {
        if verboseLevel == .all || verboseLevel == .verto {
            let fullMessage = buildMessage(level: .warning, message: message, direction: direction)
            customLogger?.log(level: .verto, message: fullMessage)
        }
    }
    
    public func stats(message: String) {
        if verboseLevel == .all || verboseLevel == .stats {
            customLogger?.log(level: .stats, message: buildMessage(level: .stats, message: message))
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

    private func buildTimeStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestampStr = formatter.string(from: Date())
        return timestampStr
    }
    
    private func buildMessage(level: LogLevel, message: String, direction: VertoDirection = .none) -> String {
        return Logger.TAG + buildTimeStamp() + getLogGlyph(level: level, direction: direction) + " " + message + "\n"
    }
}
