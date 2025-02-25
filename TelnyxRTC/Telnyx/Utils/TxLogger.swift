import Foundation

/// Protocol defining the interface for custom logging in the Telnyx SDK.
/// Implement this protocol to create a custom logger that can receive and handle logs from the SDK.
public protocol TxLogger {
    /// Called when a log message needs to be processed.
    /// - Parameters:
    ///   - level: The severity level of the log message
    ///   - message: The actual log message
    func log(level: LogLevel, message: String)
}

/// Default implementation of TxLogger that prints to console
public class TxDefaultLogger: TxLogger {
    public init() {}
    
    public func log(level: LogLevel, message: String) {
        print("\(message)")
    }
}
