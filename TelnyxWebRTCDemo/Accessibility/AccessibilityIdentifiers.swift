import Foundation

enum AccessibilityIdentifiers {
    // Main View
    static let mainView = "mainView"
    
    // User Creation
    static let createUserBottomSheet = "createUserBottomSheet"
    static let usernameTextField = "usernameTextField"
    static let passwordTextField = "passwordTextField"
    static let callerNameTextField = "callerNameTextField"
    static let callerNumberTextField = "callerNumberTextField"
    static let createUserButton = "createUserButton"
    
    // User Selection
    static let userSelectionBottomSheet = "userSelectionBottomSheet"
    static let userSelectionList = "userSelectionList"
    static let userSelectionCell = "userSelectionCell"
    
    // Connection
    static let connectButton = "connectButton"
    static let connectionStatusLabel = "connectionStatusLabel"
    
    // Call Controls
    static let numberToCallTextField = "numberToCallTextField"
    static let callButton = "callButton"
    static let answerButton = "answerButton"
    static let rejectButton = "rejectButton"
    static let hangupButton = "hangupButton"
    static let muteButton = "muteButton"
    static let dtmfButton = "dtmfButton"
    
    // DTMF Pad
    static let dtmfPad = "dtmfPad"
    static func dtmfKey(_ key: String) -> String {
        return "dtmfKey\(key)"
    }
}