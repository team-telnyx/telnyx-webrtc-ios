//
//  TelnyxWebRTCDemoUITestsLaunchTests.swift
//  TelnyxWebRTCDemoUITests
//
//  Created by Guillermo Battistel on 05-02-25.
//

import XCTest

final class TelnyxWebRTCDemoUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }


    @MainActor
    func testLaunchAndNavigateToHome() throws {
        let app = XCUIApplication()
        app.launch()

        // Add an explicit wait to allow the animation to complete
        let waitAnimation = XCTestExpectation(description: "Wait for SplashScreen animation to complete")
        let result = XCTWaiter.wait(for: [waitAnimation], timeout: 3.0) // Adjust the timeout as needed

        if result == .timedOut {
            // Wait for the Splash screen to disappear and HomeViewController to appear
            let homeView = app.otherElements["HomeViewController"]
            let homeExists = NSPredicate(format: "exists == true")

            expectation(for: homeExists, evaluatedWith: homeView, handler: nil)
            waitForExpectations(timeout: 10, handler: nil)

            // Verify that HomeViewController is displayed
            XCTAssertTrue(homeView.exists)

            // Take a screenshot of HomeViewController
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "HomeViewController Screen"
            attachment.lifetime = .keepAlways
            add(attachment)
        } else {
            XCTFail("Failed to wait for SplashScreen animation to complete")
        }
    }
}
