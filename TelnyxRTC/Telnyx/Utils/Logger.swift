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
    
    /// File handle for logging to a file
    private var logFileHandle: FileHandle?
    private let logQueue = DispatchQueue(label: "com.telnyx.logger.queue", attributes: .concurrent)
    
    private init() {
        // Initialize the log file
        setupLogFile()
    }
    
    deinit {
        logFileHandle?.closeFile()
    }
    
    /// Sets up the log file
    private func setupLogFile() {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let logFileURL = documentsDirectory.appendingPathComponent("TelnyxRTC.log")
        
        // Create the log file if it doesn't exist
        if !fileManager.fileExists(atPath: logFileURL.path) {
            fileManager.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        }
        
        // Open the log file for writing
        do {
            logFileHandle = try FileHandle(forWritingTo: logFileURL)
            logFileHandle?.seekToEndOfFile() // Append to the end of the file
        } catch {
            print("Failed to open log file: \(error)")
        }
    }
    
    /// Writes a log message to the file
    private func writeToLogFile(_ message: String) {
        //print(message)
        logQueue.async(flags: .barrier) {
            if let data = message.data(using: .utf8) {
                self.logFileHandle?.write(data)
            }
        }
    }
    
    /// Retrieves the logs as a string
    public func getLogs() -> String? {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let logFileURL = documentsDirectory.appendingPathComponent("TelnyxRTC.log")
        
        do {
            print("\n Reading log file...")
            let logData = try Data(contentsOf: logFileURL)
            let logString = String(data: logData, encoding: .utf8)
            return logString
        } catch {
            print("Failed to read log file: \(error)")
            return nil
        }
    }
    
    public func clearLog() {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent("TelnyxRTC.log")
            do {
                try "".write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
                print("Error clearing log file: \(error)")
            }
        }

    /// Prints information messages if `verboseLevel` is set to `.all` or `.info`
    /// - Parameter message: message to be printed
    public func i(message: String) {
        if verboseLevel == .all || verboseLevel == .info {
            let logMessage = "TxClient : \(timeStamp.getTimestamp())" + buildMessage(level: .info, message: message)
            //print(logMessage)
            writeToLogFile(logMessage)
        }
    }

    /// Prints Error messages if `verboseLevel` is set to `.all` or `.error`
    /// - Parameter message: message to be printed
    public func e(message: String) {
        if verboseLevel == .all || verboseLevel == .error {
            let logMessage = "TxClient : \(timeStamp.getTimestamp())" + buildMessage(level: .error, message: message)
            //print(logMessage)
            writeToLogFile(logMessage)
        }
    }

    /// Prints Warning messages if `verboseLevel` is set to `.all` or `.warning`
    /// - Parameter message: message to be printed
    public func w(message: String) {
        if verboseLevel == .all || verboseLevel == .warning {
            let logMessage = "TxClient : \(timeStamp.getTimestamp())" + buildMessage(level: .warning, message: message)
           // print(logMessage)
            writeToLogFile(logMessage)
        }
    }

    /// Prints Success messages if `verboseLevel` is set to `.all` or `.success`
    /// - Parameter message: message to be printed
    public func s(message: String) {
        if verboseLevel == .all || verboseLevel == .success {
            let logMessage = "TxClient : \(timeStamp.getTimestamp())" + buildMessage(level: .success, message: message)
            //print(logMessage)
            writeToLogFile(logMessage)
        }
    }

    /// Prints Success messages if `verboseLevel` is set to `.all` or `.verto`
    /// - Parameters:
    ///   - message: message to be printed
    ///   - direction: direction of the message. Inbound-outbound
    public func verto(message: String, direction: VertoDirection) {
        if verboseLevel == .all || verboseLevel == .verto {
            let logMessage = "TxClient : \(timeStamp.getTimestamp())" + buildMessage(level: .verto, message: message, direction: direction)
            //print(logMessage)
            writeToLogFile(logMessage)
        }
    }
    
    public func stats(message: String) {
        if verboseLevel == .all || verboseLevel == .stats {
            let logMessage = "TxClient : \(timeStamp.getTimestamp())" + buildMessage(level: .stats, message: message)
           //. print(logMessage)
            writeToLogFile(logMessage)
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
