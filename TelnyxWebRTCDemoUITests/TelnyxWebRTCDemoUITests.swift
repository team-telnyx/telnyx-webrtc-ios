//
//  TelnyxWebRTCDemoUITests.swift
//  TelnyxWebRTCDemoUITests
//
//  Created by Guillermo Battistel on 05-02-25.
//

import XCTest

final class TelnyxWebRTCDemoUITests: XCTestCase {

    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDown() {
        super.tearDown()
        app.terminate()
    }
    
    func testAppLaunchAndUserCreation() {
        // Test app launch and bottom sheet appearance
        XCTAssertTrue(app.exists)
        app.launchArguments.append("UIViewAnimationEnabled=YES")

        // Create user with hardcoded values
        let createUserButton = app.buttons["Create User"]
        XCTAssertTrue(createUserButton.waitForExistence(timeout: 5))
        createUserButton.tap()
        
        // Fill user details
        let usernameField = app.textFields["Username"]
        let passwordField = app.secureTextFields["Password"]
        let callerNameField = app.textFields["Caller Name"]
        let callerNumberField = app.textFields["Caller Number"]
        
        usernameField.tap()
        usernameField.typeText("testuser")
        
        passwordField.tap()
        passwordField.typeText("testpassword")
        
        callerNameField.tap()
        callerNameField.typeText("Test User")
        
        callerNumberField.tap()
        callerNumberField.typeText("+1234567890")
        
        app.buttons["Save"].tap()
    }
    
    func testUserSelectionAndConnection() {
        // Select user from bottom sheet
        let userCell = app.cells["testuser"]
        XCTAssertTrue(userCell.waitForExistence(timeout: 5))
        userCell.tap()
        
        // Connect
        let connectButton = app.buttons["Connect"]
        XCTAssertTrue(connectButton.waitForExistence(timeout: 5))
        connectButton.tap()
        
        // Wait for connection
        let connectedStatus = app.staticTexts["Connected"]
        XCTAssertTrue(connectedStatus.waitForExistence(timeout: 10))
    }
    
    func testCallFlow() {
        // Enter number to call
        let numberField = app.textFields["Phone Number"]
        XCTAssertTrue(numberField.waitForExistence(timeout: 5))
        numberField.tap()
        numberField.typeText("18004377950")
        
        // Initiate call
        let callButton = app.buttons["Call"]
        callButton.tap()
        
        // Wait for call invitation
        let answerButton = app.buttons["Answer"]
        XCTAssertTrue(answerButton.waitForExistence(timeout: 10))
        answerButton.tap()
        
        // Test mute functionality
        let muteButton = app.buttons["Mute"]
        XCTAssertTrue(muteButton.waitForExistence(timeout: 5))
        muteButton.tap() // Mute
        muteButton.tap() // Unmute
        
        // Test DTMF
        let dtmfButton = app.buttons["Keypad"]
        XCTAssertTrue(dtmfButton.waitForExistence(timeout: 5))
        dtmfButton.tap()
        
        // Press some DTMF keys
        let keys = ["1", "2", "3", "4"]
        for key in keys {
            app.buttons[key].tap()
        }
        
        // Close DTMF pad
        app.buttons["Close"].tap()
        
        // End call
        let endCallButton = app.buttons["End Call"]
        XCTAssertTrue(endCallButton.waitForExistence(timeout: 5))
        endCallButton.tap()
        
        // Verify call ended
        let callEndedStatus = app.staticTexts["Call Ended"]
        XCTAssertTrue(callEndedStatus.waitForExistence(timeout: 5))
    }
}
