import Foundation

enum AccessibilityIdentifiers {
    // SplashScreen
    static let splashLogo = "splashLogo"
    
    // HomeView
    static let homeViewLogo = "homeViewLogo"

    // User Creation
    static let usernameTextField = "usernameTextField"
    static let passwordTextField = "passwordTextField"
    static let callerNameTextField = "callerNameTextField"
    static let callerNumberTextField = "callerNumberTextField"
    static let createUserButton = "createUserButton"
    static let addProfileButton = "addProfileButton"
    static let signInButton = "signInButton"
    
    // User Selection
    static let userSelectionBottomSheet = "userSelectionBottomSheet"
    static let userSelectionList = "userSelectionList"
    static let userSelectionCell = "userSelectionCell"
    
    // Credential Management
    static let editCredentialButton = "editCredentialButton"
    static let deleteCredentialButton = "deleteCredentialButton"
    static let updateCredentialButton = "updateCredentialButton"
    static let deleteToastMessage = "deleteToastMessage"
    
    // Connection
    static let connectButton = "connectButton"
    static let disconnectButton = "disconnectButton"
    static let connectionStatusLabel = "connectionStatusLabel"
    
    // Call Controls
    static let numberToCallTextField = "numberToCallTextField"
    static let callButton = "callButton"
    static let answerButton = "answerButton"
    static let rejectButton = "rejectButton"
    static let hangupButton = "hangupButton"
    static let muteButton = "muteButton"
    static let speakerButton = "speakerButton"
    static let holdButton = "holdButton"
    static let dtmfButton = "dtmfButton"
    
    // DTMF Pad
    static let dtmfPad = "dtmfPad"
    static let dtmfClose = "dtmfClose"
    static func dtmfKey(_ key: String) -> String {
        return "dtmfKey\(key)"
    }
}
