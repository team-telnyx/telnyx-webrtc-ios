import Foundation
import UIKit
import FirebaseCore

enum TestConfiguration {
    
    static var isRunningUITests: Bool {
        ProcessInfo.processInfo.arguments.contains("UI_TESTING")
    }
    
    static func configureForTesting() {
        if isRunningUITests {
            // Disable animations
            UIView.setAnimationsEnabled(false)
            FirebaseApp.configure()
        }
    }
}
