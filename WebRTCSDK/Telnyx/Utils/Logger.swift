//
//  Logger.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 29/03/2021.
//

import Foundation

/**
- Available Log levels for Logger
-- `none`: Print no message
-- `error`: Message of level `error`
-- `warning`: Message of level `warning`
-- `success`: Message of level `success`
-- `info`: Message of level `info`
-- `all`:  Will print all level of messages
-*/
public enum LogLevel: Int {
    case none = 0
    case error
    case warning
    case success
    case info
    case all
}


class Logger {

    internal static let log = Logger()

    /// represents the current log level: `all` is set as default
    internal var verboseLevel: LogLevel = .all

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

    private func getLogGlyph(level: LogLevel) -> String {
        switch(level) {
        case .all: return ""
        case .none: return ""
        case .error: return errorGlyph
        case .info: return infoGlyph
        case .success: return successGlyph
        case .warning: return warningGlyph
        }
    }

    private func buildMessage(level: LogLevel, message: String) -> String {
        return getLogGlyph(level: level) + " " + message + "\n"
    }
}

