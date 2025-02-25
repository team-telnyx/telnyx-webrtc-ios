import XCTest
@testable import TelnyxRTC

class TelnyxRTCMLoggerTests: XCTestCase {
    private weak var expectation: XCTestExpectation!
    private var telnyxClient: TxClient?
    private var serverError: Error?
    private var customLogger: TxLogger?
    
    override func setUpWithError() throws {
        print("TelnyxRTCMLoggerTests:: setUpWithError")
        //Setup the SDK
        self.telnyxClient = TxClient()
        self.serverError = nil
    }
    
    override func tearDownWithError() throws {
        print("TelnyxRTCMLoggerTests:: tearDownWithError")
        self.telnyxClient?.disconnect()
        self.telnyxClient = nil
        self.serverError = nil
        self.expectation = nil
        self.customLogger = nil
    }
}
// MARK: - HELPER FUNCTIONS
extension TelnyxRTCMLoggerTests {
    func connectAndReturnError(txConfig: TxConfig) -> Error? {
        //We are expecting an error
        var error: Error? = nil
        do {
            try self.telnyxClient?.connect(txConfig: txConfig)
        } catch let err {
            print("TelnyxRTCMLoggerTests:: connect Error \(err)")
            error = err
        }
        return error
    }
}// TelnyxRTCMulticallTests helper functions

// MARK: - Multiple call tests
extension TelnyxRTCMLoggerTests {

    // MARK: - CustomLogger
    class MyCustomTestLogger : TxLogger {
        private weak var expectation: XCTestExpectation!
        var expectationFulfilled = false

        init(expectation: XCTestExpectation) {
            self.expectation = expectation
        }

        func log(level: TelnyxRTC.LogLevel, message: String) {
            if !expectationFulfilled {
                expectationFulfilled = true
                self.expectation?.fulfill()
            }
        }
    }
    
    func testCustomLogger() {
        expectation = expectation(description: "customLoger")
        self.customLogger = MyCustomTestLogger(expectation: expectation)
        let txConfig = TxConfig(sipUser: TestConstants.sipUser,
                                password: TestConstants.sipPassword,
                                logLevel: .all,
                                customLogger: self.customLogger)
        
        let error: Error? = self.connectAndReturnError(txConfig: txConfig)
        XCTAssertNil(error) // We shouldn't get any error here
        
        waitForExpectations(timeout: 5)
    }
}
