import XCTest

final class TelnyxWebRTCDemoUITests: XCTestCase {

    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("UI_TESTING")
        app.launch()
    }
    
    override func tearDown() {
        super.tearDown()
        app.terminate()
    }
    
    // MARK: - Helper Methods
    
    /// Waits for an element to exist and be hittable with a predicate-based approach
    /// - Parameters:
    ///   - element: The UI element to wait for
    ///   - timeout: Maximum time to wait (default: 15 seconds)
    /// - Returns: True if element became hittable within timeout
    @discardableResult
    func waitForElementToBeReady(_ element: XCUIElement, timeout: TimeInterval = 15.0) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    /// Waits for an element to simply exist (doesn't need to be hittable)
    /// - Parameters:
    ///   - element: The UI element to wait for
    ///   - timeout: Maximum time to wait (default: 10 seconds)
    /// - Returns: True if element exists within timeout
    @discardableResult
    func waitForElementToExist(_ element: XCUIElement, timeout: TimeInterval = 10.0) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }
    
    // MARK: - Tests
    
    func test_01_AppLaunch() {
        // Test app launch and verify home view is ready
        XCTAssertTrue(app.exists, "App should exist")
        
        let homeView = app.images[AccessibilityIdentifiers.homeViewLogo]
        
        // Wait for logo to exist and be hittable (accounting for animations)
        XCTAssertTrue(
            waitForElementToBeReady(homeView, timeout: 15.0),
            "Home View logo should be visible and hittable within 15 seconds"
        )
        
        // Additional verification: ensure logo is actually displayed
        XCTAssertTrue(homeView.exists, "Home View logo should exist")
        XCTAssertTrue(homeView.isHittable, "Home View logo should be hittable")
    }
    
    
    func test_02_testUserCreation() throws {
        // Wait for app to be ready
        sleep(1)
        XCTAssertTrue(app.exists, "App should exist")
        
        let homeView = app.images[AccessibilityIdentifiers.homeViewLogo]
        XCTAssertTrue(
            waitForElementToBeReady(homeView, timeout: 15.0),
            "Home View should be visible before user creation"
        )
        
        sleep(1)
        
        // Check which button is available (createUser or switchProfile)
        let createUserButton = app.buttons[AccessibilityIdentifiers.createUserButton]
        let switchProfileButton = app.buttons[AccessibilityIdentifiers.userSelectionBottomSheet]
        
        if createUserButton.exists {
            app.scrollToElement(createUserButton)
            XCTAssertTrue(waitForElementToBeReady(createUserButton, timeout: 10.0))
            createUserButton.tap()
        } else if switchProfileButton.exists {
            app.scrollToElement(switchProfileButton)
            XCTAssertTrue(waitForElementToBeReady(switchProfileButton, timeout: 10.0))
            switchProfileButton.tap()
        } else {
            XCTFail("Neither createUserButton nor switchProfileButton exists")
        }
        
        sleep(2)
        
        // Wait for bottom sheet to display and tap add profile button
        let addProfileButton = app.buttons[AccessibilityIdentifiers.addProfileButton]
        XCTAssertTrue(
            waitForElementToBeReady(addProfileButton, timeout: 10.0),
            "Add profile button should be visible"
        )
        addProfileButton.tap()
        
        // Wait for credential form fields
        let usernameTextField = app.textFields[AccessibilityIdentifiers.usernameTextField]
        let passwordTextField = app.secureTextFields[AccessibilityIdentifiers.passwordTextField]
        let callerNameTextField = app.textFields[AccessibilityIdentifiers.callerNameTextField]
        let callerNumberTextField = app.textFields[AccessibilityIdentifiers.callerNumberTextField]
        let signInButton = app.buttons[AccessibilityIdentifiers.signInButton]
        
        XCTAssertTrue(waitForElementToExist(usernameTextField, timeout: 10.0), "Username text field should exist")
        XCTAssertTrue(waitForElementToExist(passwordTextField, timeout: 10.0), "Password text field should exist")
        XCTAssertTrue(waitForElementToExist(signInButton, timeout: 10.0), "Sign In button should exist")
        
        // Fill in credentials
        usernameTextField.tap()
        usernameTextField.typeText(TestConstants.sipUser)
        
        passwordTextField.tap()
        passwordTextField.typeText(TestConstants.sipPassword)
        
        callerNumberTextField.tap()
        callerNumberTextField.typeText(TestConstants.callerNumber)
        
        callerNameTextField.tap()
        callerNameTextField.typeText(TestConstants.callerName)
        
        signInButton.tap()
        
        // Verify user was created successfully and returned to home view
        let homeViewLogo = app.images[AccessibilityIdentifiers.homeViewLogo]
        XCTAssertTrue(
            waitForElementToBeReady(homeViewLogo, timeout: 15.0),
            "HomeView should appear after signing in"
        )
        
        sleep(5)
        
        // Disconnect after test
        let disconnectButton = app.buttons[AccessibilityIdentifiers.disconnectButton]
        XCTAssertTrue(
            waitForElementToBeReady(disconnectButton, timeout: 10.0),
            "Disconnect button should be visible"
        )
        disconnectButton.tap()
        sleep(5)
    }
    
    func test_03_testCallFlow() {
        // Wait for app to be ready
        sleep(1)
        XCTAssertTrue(app.exists, "App should exist")
        
        let homeViewLogo = app.images[AccessibilityIdentifiers.homeViewLogo]
        XCTAssertTrue(
            waitForElementToBeReady(homeViewLogo, timeout: 15.0),
            "HomeView should be visible before call flow"
        )
        
        sleep(1)

        // Connect to SIP
        let connectButton = app.buttons[AccessibilityIdentifiers.connectButton]
        XCTAssertTrue(
            waitForElementToBeReady(connectButton, timeout: 10.0),
            "Connect button should be visible"
        )
        connectButton.tap()
        sleep(5)
        
        // Enter destination number
        let numberField = app.textFields[AccessibilityIdentifiers.numberToCallTextField]
        XCTAssertTrue(
            waitForElementToBeReady(numberField, timeout: 10.0),
            "Number field should be visible"
        )
        numberField.tap()
        numberField.typeText(TestConstants.destinationNumber)
        
        // Dismiss keyboard by tapping window
        app.children(matching: .window).firstMatch.tap()
        sleep(3)

        // Initiate call
        let callButton = app.buttons[AccessibilityIdentifiers.callButton]
        app.scrollToElement(callButton)
        XCTAssertTrue(
            waitForElementToBeReady(callButton, timeout: 10.0),
            "Call button should be visible and hittable"
        )
        callButton.tap()
        
        sleep(5)
        
        // Test mute functionality
        let muteButton = app.buttons[AccessibilityIdentifiers.muteButton]
        XCTAssertTrue(
            waitForElementToBeReady(muteButton, timeout: 10.0),
            "Mute button should be visible"
        )
        muteButton.tap() // Mute
        sleep(2)
        muteButton.tap() // Unmute
        
        // Test speaker functionality
        let speakerButton = app.buttons[AccessibilityIdentifiers.speakerButton]
        XCTAssertTrue(
            waitForElementToBeReady(speakerButton, timeout: 10.0),
            "Speaker button should be visible"
        )
        speakerButton.tap() // Toggle speaker
        sleep(2)
        speakerButton.tap() // Toggle speaker
        
        // Test hold functionality
        let holdButton = app.buttons[AccessibilityIdentifiers.holdButton]
        XCTAssertTrue(
            waitForElementToBeReady(holdButton, timeout: 10.0),
            "Hold button should be visible"
        )
        holdButton.tap() // Hold call
        sleep(2)
        holdButton.tap() // Resume call
        
        sleep(1)
        
        // Test DTMF
        let dtmfButton = app.buttons[AccessibilityIdentifiers.dtmfButton]
        XCTAssertTrue(
            waitForElementToBeReady(dtmfButton, timeout: 10.0),
            "DTMF button should be visible"
        )
        dtmfButton.tap()
        
        // Press some DTMF keys
        let keypadButtons = [
            "1", "2", "3",
            "4", "5", "6",
            "7", "8", "9",
            "*", "0", "#"
        ]
        
        for key in keypadButtons {
            let dtmfKey = app.buttons[AccessibilityIdentifiers.dtmfKey(key)]
            if waitForElementToBeReady(dtmfKey, timeout: 5.0) {
                dtmfKey.tap()
            } else {
                XCTFail("DTMF key '\(key)' not found or not hittable")
            }
        }
        
        // Close DTMF pad
        let dtmfCloseButton = app.buttons[AccessibilityIdentifiers.dtmfClose]
        XCTAssertTrue(
            waitForElementToBeReady(dtmfCloseButton, timeout: 5.0),
            "DTMF close button should be visible"
        )
        dtmfCloseButton.tap()
        
        // End call
        let endCallButton = app.buttons[AccessibilityIdentifiers.hangupButton]
        XCTAssertTrue(
            waitForElementToBeReady(endCallButton, timeout: 10.0),
            "End call button should be visible"
        )
        endCallButton.tap()
        sleep(2)

        // Disconnect
        let disconnectButton = app.buttons[AccessibilityIdentifiers.disconnectButton]
        XCTAssertTrue(
            waitForElementToBeReady(disconnectButton, timeout: 10.0),
            "Disconnect button should be visible after call ends"
        )
        disconnectButton.tap()
        sleep(2)
    }
}

// MARK: - XCUIApplication Extension

extension XCUIApplication {
    /// Scrolls to an element with retry logic
    /// - Parameters:
    ///   - element: Element to scroll to
    ///   - maxRetries: Maximum scroll attempts (default: 5)
    func scrollToElement(_ element: XCUIElement, maxRetries: Int = 5) {
        var attempts = 0
        while !element.isHittable && attempts < maxRetries {
            swipeUp()
            sleep(1)
            attempts += 1
        }
        
        if !element.isHittable {
            XCTFail("Element not found after \(maxRetries) scroll attempts")
        }
    }
}
