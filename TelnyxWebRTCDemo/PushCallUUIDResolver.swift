//
//  PushCallUUIDResolver.swift
//  TelnyxWebRTCDemo
//

import Foundation

enum PushCallUUIDResolver {

    private static let callDismissalAlerts: Set<String> = [
        "Missed call!",
        "Answered Elsewhere",
    ]

    static func shouldDismissCall(forAlert alert: String) -> Bool {
        callDismissalAlerts.contains(alert)
    }

    static func uuid(
        from metadata: [String: Any]?,
        fallbackUUID: () -> UUID = { UUID() },
        logInvalidCallID: (Any, UUID) -> Void = { callID, uuid in
            print("AppDelegate:: Replacing invalid VoIP push call_id '\(callID)' with fallback UUID: \(uuid)")
        }
    ) -> UUID {
        guard let callIDValue = metadata?["call_id"] else {
            return fallbackUUID()
        }

        guard let callID = callIDValue as? String,
              !callID.isEmpty else {
            let uuid = fallbackUUID()
            logInvalidCallID(callIDValue, uuid)
            return uuid
        }

        guard let uuid = UUID(uuidString: callID) else {
            let uuid = fallbackUUID()
            logInvalidCallID(callID, uuid)
            return uuid
        }

        return uuid
    }

    static func handleMissedCall(
        metadata: [String: Any]?,
        fallbackUUID: () -> UUID = { UUID() },
        handleMissedCallNotification: (UUID, [String: Any]) -> Void
    ) {
        let pushMetadata = metadata ?? [:]
        let uuid = uuid(from: pushMetadata, fallbackUUID: fallbackUUID)
        print("AppDelegate:: Received missed call notification for call: \(uuid)")

        handleMissedCallNotification(uuid, pushMetadata)
    }

    static func handleIncomingCall(
        metadata: [String: Any]?,
        fallbackUUID: () -> UUID = { UUID() },
        processVoIPNotification: (UUID, [String: Any]) -> Void,
        reportNewIncomingCall: (String, UUID) -> Void
    ) {
        let pushMetadata = metadata ?? [:]
        let uuid = uuid(from: pushMetadata, fallbackUUID: fallbackUUID)
        let caller: String

        if metadata == nil {
            caller = "Incoming call"
        } else {
            let callerName = (pushMetadata["caller_name"] as? String) ?? ""
            let callerNumber = (pushMetadata["caller_number"] as? String) ?? ""
            caller = callerName.isEmpty ? (callerNumber.isEmpty ? "Unknown" : callerNumber) : callerName
        }

        processVoIPNotification(uuid, pushMetadata)
        reportNewIncomingCall(caller, uuid)
    }

    static func handleIncomingCall(
        metadata: [String: Any],
        fallbackUUID: () -> UUID = { UUID() },
        processVoIPNotification: (UUID, [String: Any]) -> Void,
        reportNewIncomingCall: (String, UUID) -> Void
    ) {
        handleIncomingCall(
            metadata: Optional(metadata),
            fallbackUUID: fallbackUUID,
            processVoIPNotification: processVoIPNotification,
            reportNewIncomingCall: reportNewIncomingCall
        )
    }
}
