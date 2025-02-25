import Foundation

/// Protocol defining the interface for custom logging in the Telnyx SDK.
/// Implement this protocol to create a custom logger that can receive and handle logs from the SDK.
public protocol TxLogger {
    /// Called when a log message needs to be processed.
    /// - Parameters:
    ///   - level: The severity level of the log message
    ///   - tag: Optional tag to categorize the log message
    ///   - message: The actual log message
    ///   - timestamp: The timestamp when the log was generated
    ///   - vertoDirection: Optional parameter indicating the direction of Verto messages (if applicable)
    func log(level: LogLevel, tag: String?, message: String, timestamp: Date, vertoDirection: VertoDirection?)
}

/// Default implementation of TxLogger that prints to console
public class TxDefaultLogger: TxLogger {
    public init() {}
    
    public func log(level: LogLevel, tag: String?, message: String, timestamp: Date, vertoDirection: VertoDirection?) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestampStr = formatter.string(from: timestamp)
        let tagStr = tag ?? "TxClient"
        let directionGlyph = vertoDirection.map { direction -> String in
            switch direction {
            case .inbound: return "←"
            case .outbound: return "→"
            case .none: return ""
            }
        } ?? ""
        
        let levelGlyph: String
        switch level {
        case .error: levelGlyph = "❌"
        case .warning: levelGlyph = "⚠️"
        case .success: levelGlyph = "✅"
        case .info: levelGlyph = "ℹ️"
        case .verto: levelGlyph = directionGlyph
        case .stats: levelGlyph = "📊"
        case .all, .none: levelGlyph = ""
        }
        
        print("\(tagStr) : \(timestampStr) \(levelGlyph) \(message)")
    }
}