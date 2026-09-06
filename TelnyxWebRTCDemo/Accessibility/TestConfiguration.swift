import Foundation
import UIKit
import FirebaseCore

enum TestConfiguration {
    private static let trueValues = ["1", "true", "yes", "y", "on"]
    
    static var isRunningUITests: Bool {
        ProcessInfo.processInfo.arguments.contains("UI_TESTING")
    }

    static var isMobileBlackboxAutomationEnabled: Bool {
        hasArgument("MOBILE_BBT_AUTOMATION") || boolValue(for: "MOBILE_BBT_AUTOMATION")
    }

    static var shouldAutoAnswerMobileBlackboxCalls: Bool {
        isMobileBlackboxAutomationEnabled || boolValue(for: "MOBILE_BBT_AUTO_ANSWER")
    }

    static var mobileBlackboxCallbackDestination: String? {
        stringValue(for: "MOBILE_BBT_CALLBACK_DESTINATION")
    }

    static var mobileBlackboxAutoAnswerDelay: TimeInterval {
        timeIntervalValue(for: "MOBILE_BBT_AUTO_ANSWER_DELAY_SECONDS", defaultValue: 1.0)
    }

    static var mobileBlackboxCallbackDelay: TimeInterval {
        timeIntervalValue(for: "MOBILE_BBT_CALLBACK_DELAY_SECONDS", defaultValue: 1.0)
    }

    static var mobileBlackboxInboundActiveHold: TimeInterval {
        timeIntervalValue(for: "MOBILE_BBT_INBOUND_ACTIVE_HOLD_SECONDS", defaultValue: 1.0)
    }
    
    static func configureForTesting() {
        if isRunningUITests {
            // Disable animations
            UIView.setAnimationsEnabled(false)
            FirebaseApp.configure()
        }
    }

    private static func hasArgument(_ argument: String) -> Bool {
        ProcessInfo.processInfo.arguments.contains(argument)
    }

    private static func boolValue(for key: String) -> Bool {
        guard let value = ProcessInfo.processInfo.environment[key]?.lowercased() else {
            return false
        }

        return trueValues.contains(value)
    }

    private static func stringValue(for key: String) -> String? {
        guard let value = ProcessInfo.processInfo.environment[key],
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return value
    }

    private static func timeIntervalValue(for key: String, defaultValue: TimeInterval) -> TimeInterval {
        guard let value = ProcessInfo.processInfo.environment[key],
              let interval = TimeInterval(value),
              interval >= 0 else {
            return defaultValue
        }

        return interval
    }
}
