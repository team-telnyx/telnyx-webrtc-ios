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
    
    func testAppLaunch() {
        // Test app launch and bottom sheet appearance
        XCTAssertTrue(app.exists)
        let homeView = app.images[AccessibilityIdentifiers.homeViewLogo]
        XCTAssertTrue(homeView.waitForExistence(timeout: 5), "Home View is not visible")
    }
    
    
    func testUserCreation() throws {
        // Test app launch and bottom sheet appearance
        sleep(1)
        XCTAssertTrue(app.exists)
        let homeView = app.images[AccessibilityIdentifiers.homeViewLogo]
        XCTAssertTrue(homeView.waitForExistence(timeout: 5), "Home View is not visible")
        
        sleep(1)
        // Verificar si existe el botón de createUser
        let createUserButton = app.buttons[AccessibilityIdentifiers.createUserButton]
        let switchProfileButton = app.buttons[AccessibilityIdentifiers.userSelectionBottomSheet]
        
        if createUserButton.exists {
            app.scrollToElement(createUserButton)
            createUserButton.tap()
        } else if switchProfileButton.exists {
            app.scrollToElement(switchProfileButton)
            switchProfileButton.tap()
        } else {
            XCTFail("Neither createUserButton nor switchProfileButton exists")
        }
        
        sleep(2)
        // Wait to bottomsheet to be displayed and check for add profile button
        let addProfileButton = app.buttons[AccessibilityIdentifiers.addProfileButton]
        XCTAssertTrue(addProfileButton.waitForExistence(timeout: 10))
        addProfileButton.tap()
        
        let usernameTextField = app.textFields[AccessibilityIdentifiers.usernameTextField]
        let passwordTextField = app.secureTextFields[AccessibilityIdentifiers.passwordTextField]
        let callerNameTextField = app.textFields[AccessibilityIdentifiers.callerNameTextField]
        let callerNumberTextField = app.textFields[AccessibilityIdentifiers.callerNumberTextField]
        
        let signInButton = app.buttons[AccessibilityIdentifiers.signInButton]
        
        XCTAssertTrue(usernameTextField.exists, "Username text field does not exist")
        XCTAssertTrue(passwordTextField.exists, "Password text field does not exist")
        XCTAssertTrue(signInButton.exists, "Sign In button does not exist")
    
        
        usernameTextField.tap()
        usernameTextField.typeText(TestConstants.sipUser)
        
        passwordTextField.tap()
        passwordTextField.typeText(TestConstants.sipPassword)
        
        callerNumberTextField.tap()
        callerNumberTextField.typeText("+1234567890")
        
        callerNameTextField.tap()
        callerNameTextField.typeText("Test User")
        
        signInButton.tap()
        
        // Verificar que el usuario fue creado correctamente
        let homeViewLogo = app.images[AccessibilityIdentifiers.homeViewLogo]
        XCTAssertTrue(homeViewLogo.waitForExistence(timeout: 10), "HomeView did not appear after signing in")
        sleep(5)
        
        let disconnectButton = app.buttons[AccessibilityIdentifiers.disconnectButton]
        XCTAssertTrue(homeViewLogo.waitForExistence(timeout: 5))
        disconnectButton.tap()
        sleep(5)
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

extension XCUIApplication {
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
