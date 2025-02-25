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
    case none = 0
    case error
    case warning
    case success
    case info
    case verto
    case stats
    case all
}

class Timestamp {
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS "
        return formatter
    }()

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

    /// Represents the current log level: `all` is set as default
    internal var verboseLevel: LogLevel = .all

    private var statsGlyph: String = "\u{1F4CA}"     // Glyph for messages of level .Stats
    private var rightArrowGlyph: String = "\u{25B6}"
    private var leftArrowGlyph: String = "\u{25C0}"
    private var errorGlyph: String = "\u{1F6AB}"    // Glyph for messages of level .Error
    private var warningGlyph: String = "\u{1F514}"  // Glyph for messages of level .Warning
    private var successGlyph: String = "\u{2705}"   // Glyph for messages of level .Success
    private var infoGlyph: String = "\u{1F535}"     // Glyph for messages of level .Info
    private var timeStamp: Timestamp = Timestamp()
    
    // File URL for persisting logs
    private let logFileURL: URL = {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("TelnyxRTC.log")
    }()
    
    private init() {
        // Create the log file if it doesn't exist
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        }
    }

    /// Prints information messages if `verboseLevel` is set to `.all` or `.info`
    public func i(message: String) {
        if verboseLevel == .all || verboseLevel == .info {
            let logMessage = "TxClient : \(timeStamp.getTimestamp())" + buildMessage(level: .info, message: message)
       //     print(logMessage)
            writeToFile(message: logMessage)
        }
    }

    /// Prints Error messages if `verboseLevel` is set to `.all` or `.error`
    public func e(message: String) {
        if verboseLevel == .all || verboseLevel == .error {
            let logMessage = "TxClient : \(timeStamp.getTimestamp())" + buildMessage(level: .error, message: message)
        //    print(logMessage)
            writeToFile(message: logMessage)
        }
    }

    /// Prints Warning messages if `verboseLevel` is set to `.all` or `.warning`
    public func w(message: String) {
        if verboseLevel == .all || verboseLevel == .warning {
            let logMessage = "TxClient : \(timeStamp.getTimestamp())" + buildMessage(level: .warning, message: message)
          //  print(logMessage)
            writeToFile(message: logMessage)
        }
    }

    /// Prints Success messages if `verboseLevel` is set to `.all` or `.success`
    public func s(message: String) {
        if verboseLevel == .all || verboseLevel == .success {
            let logMessage = "TxClient : \(timeStamp.getTimestamp())" + buildMessage(level: .success, message: message)
         //   print(logMessage)
            writeToFile(message: logMessage)
        }
    }

    /// Prints Success messages if `verboseLevel` is set to `.all` or `.verto`
    public func verto(message: String, direction: VertoDirection) {
        if verboseLevel == .all || verboseLevel == .verto {
            let logMessage = "TxClient : \(timeStamp.getTimestamp())" + buildMessage(level: .verto, message: message, direction: direction)
           // print(logMessage)
            writeToFile(message: logMessage)
        }
    }
    
    public func stats(message: String) {
        if verboseLevel == .all || verboseLevel == .stats {
            let logMessage = "TxClient : \(timeStamp.getTimestamp())" + buildMessage(level: .stats, message: message)
            //print(logMessage)
           // writeToFile(message: logMessage)
        }
    }

    private func getLogGlyph(level: LogLevel, direction: VertoDirection = .none) -> String {
        switch level {
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

    /// Writes a log message to the file
    private func writeToFile(message: String) {
        if let fileHandle = FileHandle(forWritingAtPath: logFileURL.path) {
            defer { fileHandle.closeFile() }
            fileHandle.seekToEndOfFile()
            if let data = message.data(using: .utf8) {
                fileHandle.write(data)
            }
        } else {
            print("Error: Could not write to log file.")
        }
    }

    /// Returns all logs as a single string
    public func getLogsAsString() -> String {
        do {
            return try String(contentsOf: logFileURL, encoding: .utf8)
        } catch {
            print("Error reading log file: \(error)")
            return ""
        }
    }

    /// Clears all logs from the file
    public func clearLogs() {
        do {
            try "".write(to: logFileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error clearing log file: \(error)")
        }
    }
}
