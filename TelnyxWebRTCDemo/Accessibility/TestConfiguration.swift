import Foundation
import UIKit

enum TestConfiguration {
    static var isRunningUITests: Bool {
        ProcessInfo.processInfo.arguments.contains("UI_TESTING")
    }
    
    static func configureForTesting() {
        if isRunningUITests {
            // Disable animations
            UIView.setAnimationsEnabled(false)
            
            // Set default values for testing
            UserDefaults.standard.set("testuser", forKey: "defaultUsername")
            UserDefaults.standard.set("testpass", forKey: "defaultPassword")
            UserDefaults.standard.set("Test User", forKey: "defaultCallerName")
            UserDefaults.standard.set("+1234567890", forKey: "defaultCallerNumber")
            UserDefaults.standard.set("18004377950", forKey: "defaultNumberToCall")
        }
    }
}