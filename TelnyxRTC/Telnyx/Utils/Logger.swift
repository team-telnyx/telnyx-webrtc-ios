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
    /// All the SDK logs are printed.
    case all
}

enum VertoDirection: Int {
    case inbound = 0
    case outbound
    case none
}

// Logging
// Logger is modeled of of Timber which makes logging easier in Android
// It's a utility for the android.util.log class
// TODO Make this a protocol so the consumer (developer) can decide how logging happens
// I understand that we need to write to the device logs internally as well. But the developer might want to pipe the logs / log events
// somewhere else too.
// TODO Answer: What does the consumer (developer) expect from the logs? What the standard for logging to the device logs in iOS??
// TODO We may have to think about marking this internal
class Logger {

    // TODO I think it's best practice to use an instance property
    internal static let log = Logger()

    /// represents the current log level: `all` is set as default
    internal var verboseLevel: LogLevel = .all

    private var rightArrowGlyph: String = "\u{25B6}"
    private var leftArrowGlyph: String = "\u{25C0}"

    private var errorGlyph: String = "\u{1F6AB}"    // Glyph for messages of level .Error
    private var warningGlyph: String = "\u{1F514}"  // Glyph for messages of level .Warning
    private var successGlyph: String = "\u{2705}"   // Glyph for messages of level .Success
    private var infoGlyph: String = "\u{1F535}"     // Glyph for messages of level .Info

    private init() {}


    /// Prints information messages if `verboseLevel` is set to `.all` or `.info`
    /// - Parameter message: message to be printed
    public func i(message: String) {
        if verboseLevel == .all || verboseLevel == .info {
            print(buildMessage(level: .info, message: message))
        }
    }

    /// Prints Error messages if `verboseLevel` is set to `.all` or `.error`
    /// - Parameter message: message to be printed
    public func e(message: String) {
        if verboseLevel == .all || verboseLevel == .error {
            print(buildMessage(level: .error, message: message))
        }
    }

    /// Prints Warning messages if `verboseLevel` is set to `.all` or `.warning`
    /// - Parameter message: message to be printed
    public func w(message: String) {
        if verboseLevel == .all || verboseLevel == .warning {
            print(buildMessage(level: .warning, message: message))
        }
    }

    /// Prints Success messages if `verboseLevel` is set to `.all` or `.success`
    /// - Parameter message: message to be printed
    public func s(message: String) {
        if verboseLevel == .all || verboseLevel == .success {
            print(buildMessage(level: .success, message: message))
        }
    }

    /// Prints Success messages if `verboseLevel` is set to `.all` or `.verto`
    /// - Parameters:
    ///   - message: message to be printed
    ///   - direction: direction of the message. Inbound-outbound
    // TODO What's the purpose of a seperate log level for verto?
    public func verto(message: String, direction: VertoDirection) {
        if verboseLevel == .all || verboseLevel == .verto {
            print(buildMessage(level: .verto, message: message, direction: direction))
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
        }
    }

    private func buildMessage(level: LogLevel, message: String, direction: VertoDirection = .none) -> String {
        return getLogGlyph(level: level, direction: direction) + " " + message + "\n"
    }
}

