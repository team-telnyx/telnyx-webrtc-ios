//
//  PushCallUUIDResolverTests.swift
//  TelnyxRTCTests
//

import XCTest

final class PushCallUUIDResolverTests: XCTestCase {

    func testMalformedCallIDUsesFallbackUUID() {
        let fallbackUUID = makeUUID("11111111-1111-1111-1111-111111111111")

        let resolvedUUID = PushCallUUIDResolver.uuid(
            from: ["call_id": "not-a-canonical-uuid"],
            fallbackUUID: { fallbackUUID }
        )

        XCTAssertEqual(resolvedUUID, fallbackUUID)
    }

    func testMalformedCallIDLogsBadValueWhenUsingFallbackUUID() {
        let fallbackUUID = makeUUID("11111111-1111-1111-1111-111111111111")
        var loggedCallID: Any?
        var loggedFallbackUUID: UUID?

        let resolvedUUID = PushCallUUIDResolver.uuid(
            from: ["call_id": "not-a-canonical-uuid"],
            fallbackUUID: { fallbackUUID },
            logInvalidCallID: { callID, uuid in
                loggedCallID = callID
                loggedFallbackUUID = uuid
            }
        )

        XCTAssertEqual(resolvedUUID, fallbackUUID)
        XCTAssertEqual(loggedCallID as? String, "not-a-canonical-uuid")
        XCTAssertEqual(loggedFallbackUUID, fallbackUUID)
    }

    func testCanonicalCallIDUsesServerUUID() {
        let serverUUID = makeUUID("22222222-2222-2222-2222-222222222222")
        let fallbackUUID = makeUUID("11111111-1111-1111-1111-111111111111")

        let resolvedUUID = PushCallUUIDResolver.uuid(
            from: ["call_id": serverUUID.uuidString],
            fallbackUUID: { fallbackUUID }
        )

        XCTAssertEqual(resolvedUUID, serverUUID)
    }

    func testMalformedCallIDStillReportsIncomingCall() {
        let fallbackUUID = makeUUID("11111111-1111-1111-1111-111111111111")
        var processedUUID: UUID?
        var reportedCaller: String?
        var reportedUUID: UUID?

        PushCallUUIDResolver.handleIncomingCall(
            metadata: [
                "call_id": "not-a-canonical-uuid",
                "caller_name": "Alice",
            ],
            fallbackUUID: { fallbackUUID },
            processVoIPNotification: { uuid, _ in
                processedUUID = uuid
            },
            reportNewIncomingCall: { caller, uuid in
                reportedCaller = caller
                reportedUUID = uuid
            }
        )

        XCTAssertEqual(processedUUID, fallbackUUID)
        XCTAssertEqual(reportedCaller, "Alice")
        XCTAssertEqual(reportedUUID, fallbackUUID)
    }

    func testIncomingCallWithoutMetadataStillReportsIncomingCall() {
        let fallbackUUID = makeUUID("11111111-1111-1111-1111-111111111111")
        var processedMetadata: [String: Any]?
        var processedUUID: UUID?
        var reportedCaller: String?
        var reportedUUID: UUID?

        PushCallUUIDResolver.handleIncomingCall(
            metadata: nil,
            fallbackUUID: { fallbackUUID },
            processVoIPNotification: { uuid, metadata in
                processedUUID = uuid
                processedMetadata = metadata
            },
            reportNewIncomingCall: { caller, uuid in
                reportedCaller = caller
                reportedUUID = uuid
            }
        )

        XCTAssertEqual(processedUUID, fallbackUUID)
        XCTAssertEqual(processedMetadata?.isEmpty, true)
        XCTAssertEqual(reportedCaller, "Incoming call")
        XCTAssertEqual(reportedUUID, fallbackUUID)
    }

    func testMalformedMissedCallIDStillReportsMissedCall() {
        let fallbackUUID = makeUUID("11111111-1111-1111-1111-111111111111")
        var handledUUID: UUID?
        var handledMetadata: [String: Any]?

        PushCallUUIDResolver.handleMissedCall(
            metadata: ["call_id": "not-a-canonical-uuid"],
            fallbackUUID: { fallbackUUID },
            handleMissedCallNotification: { uuid, metadata in
                handledUUID = uuid
                handledMetadata = metadata
            }
        )

        XCTAssertEqual(handledUUID, fallbackUUID)
        XCTAssertEqual(handledMetadata?["call_id"] as? String, "not-a-canonical-uuid")
    }

    func testMissedCallWithoutMetadataStillReportsMissedCall() {
        let fallbackUUID = makeUUID("11111111-1111-1111-1111-111111111111")
        var handledUUID: UUID?
        var handledMetadata: [String: Any]?

        PushCallUUIDResolver.handleMissedCall(
            metadata: nil,
            fallbackUUID: { fallbackUUID },
            handleMissedCallNotification: { uuid, metadata in
                handledUUID = uuid
                handledMetadata = metadata
            }
        )

        XCTAssertEqual(handledUUID, fallbackUUID)
        XCTAssertEqual(handledMetadata?.isEmpty, true)
    }

    private func makeUUID(
        _ value: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> UUID {
        guard let uuid = UUID(uuidString: value) else {
            XCTFail("Invalid test UUID: \(value)", file: file, line: line)
            return UUID()
        }

        return uuid
    }
}
