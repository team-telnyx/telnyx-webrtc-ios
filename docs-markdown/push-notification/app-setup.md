## Push Notification App Setup

### Native iOS missed call notification opt-in

Native iOS missed call notifications are disabled by default. To explicitly opt in for testing or controlled rollouts, set `enableMissedCallNotifications` on `TxConfig`.

```Swift
let txConfig = TxConfig(
    sipUser: sipUser,
    password: password,
    pushDeviceToken: pushToken,
    enableMissedCallNotifications: true
)
```

When enabled, the SDK sends the native iOS user agent as `iOS-mpn-<sdk-version>`. When disabled, it continues using the default `iOS-<sdk-version>` format.

### VoIP Push - App Setup

The following setup is required in your application to receive Telnyx VoIP push notifications:

#### a. Add Push Notifications capability to your Xcode project

1. Open the xcode workspace associated with your app.
2. In the Project Navigator (the left-hand menu), select the project icon that represents your mobile app.
3. In the top-left corner of the right-hand pane in Xcode, select your app's target.
4. Press the  +Capabilities button.
<p align="center">
      <img width="294" alt="Screen Shot 2021-11-26 at 13 34 12" src="https://user-images.githubusercontent.com/75636882/143610180-04e2a98c-bb08-4f06-b81a-9a3a4231d389.png" />
</p>

6. Enable Push Notifications
<p align="center">
      <img width="269" alt="Screen Shot 2021-11-26 at 13 35 51" src="https://user-images.githubusercontent.com/75636882/143610372-abab46cc-dd2a-4712-9020-240f9dbaaaf7.png" />
</p>

#### b. Configure PushKit into your app:
1. Import pushkit
```Swift
import PushKit
```
2. Initialize PushKit:
```Swift
private var pushRegistry = PKPushRegistry.init(queue: DispatchQueue.main)
...

func initPushKit() {
  pushRegistry.delegate = self
  pushRegistry.desiredPushTypes = Set([.voIP])
}
```
3. Implement PKPushRegistryDelegate
```Swift
extension AppDelegate: PKPushRegistryDelegate {

    // New push notification token assigned by APNS.
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        if (type == .voIP) {
            // This push notification token has to be sent to Telnyx when connecting the Client.
            let deviceToken = credentials.token.reduce("", {$0 + String(format: "%02X", $1) })
            UserDefaults.standard.savePushToken(pushToken: deviceToken)
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        if (type == .voIP) {
            // Delete incoming token in user defaults
            let userDefaults = UserDefaults.init()
            userDefaults.deletePushToken()
        }
    }

    /**
     This delegate method is available on iOS 11 and above. 
     */
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        if (payload.type == .voIP) {
            self.handleVoIPPushNotification(payload: payload)
        }

        if let version = Float(UIDevice.current.systemVersion), version >= 13.0 {
            completion()
        }
    }

    func handleVoIPPushNotification(payload: PKPushPayload) {
        if let metadata = payload.dictionaryPayload["metadata"] as? [String: Any] {

            let callKitId = (metadata["parent_call_id"] as? String) ?? (metadata["call_id"] as? String)
            let callerName = (metadata["caller_name"] as? String) ?? ""
            let callerNumber = (metadata["caller_number"] as? String) ?? ""
            let caller = callerName.isEmpty ? (callerNumber.isEmpty ? "Unknown" : callerNumber) : callerName
            

            guard let callKitId = callKitId, let uuid = UUID(uuidString: callKitId) else { return }
            
            // Re-connect the client and process the push notification when is received.
            // You will need to use the credentials of the same user that is receiving the call. 
            let txConfig = TxConfig(sipUser: sipUser,
                                password: password,
                                pushDeviceToken: "APNS_PUSH_TOKEN")
                                
                        
            //Call processVoIPNotification method 
        
            try telnyxClient?.processVoIPNotification(txConfig: txConfig, serverConfiguration: serverConfig,pushMetaData: metadata)
            

            
            // Report the incoming call to CallKit framework.
            let callHandle = CXHandle(type: .generic, value: from)
            let callUpdate = CXCallUpdate()
            callUpdate.remoteHandle = callHandle
            callUpdate.hasVideo = false

            provider.reportNewIncomingCall(with: uuid, update: callUpdate) { error in
                  if let error = error {
                      print("AppDelegate:: Failed to report incoming call: \(error.localizedDescription).")
                  } else {
                      print("AppDelegate:: Incoming call successfully reported.")
                  }
            }
    }
}
```

4. If everything is correctly set-up when the app runs APNS should assign a Push Token.
5. In order to receive VoIP push notifications. You will need to send your push token when connecting to the Telnyx Client.

```Swift
 
 let txConfig = TxConfig(sipUser: sipUser,
                         password: password,
                         pushDeviceToken: "DEVICE_APNS_TOKEN",
                         //You can choose the appropriate verbosity level of the SDK. 
                         logLevel: .all)

 // Or use a JWT Telnyx Token to authenticate
 let txConfigToken = TxConfig(token: "MY_JWT_TELNYX_TOKEN",
                             pushDeviceToken: "DEVICE_APNS_TOKEN",
                             //You can choose the appropriate verbosity level of the SDK. Logs are disabled by default
                             logLevel: .all)
```

For more information about Pushkit you can check the official [Apple docs](https://developer.apple.com/documentation/pushkit]).


__*Important*__:
- You will need to login at least once to send your device token to Telnyx before start getting Push notifications.
- You will need to provide `pushMetaData` to `processVoIPNotification()` to get Push calls to work.
- You will need to implement 'CallKit' to report an incoming call when there’s a VoIP push notification. On iOS 13.0 and later, if you fail to report a call to CallKit, the system will terminate your app. More information on [Apple docs](https://developer.apple.com/documentation/pushkit/pkpushregistrydelegate/2875784-pushregistry) 


## Multidevice Push Notifications

Telnyx WebRTC supports multidevice push notifications. A single user can have up to 5 device tokens (either iOS - APNS or Android - FCM). When a user logs into the socket and provides a push token, our services will register this token to that user - allowing it to receive push notifications for incoming calls. If a 6th registration is made, the least recently used token will be removed.

This effectively means that you can have up to 5 devices that can receive push notifications for the same incoming call.

### Push-when-active multi-device flows

For multi-device setups where a single incoming call is delivered to several devices via push, the SDK can automatically include the answering device's PushKit VoIP token in the `telnyx_rtc.answer` payload. The backend uses that token to exclude the answering device from the `answered-elsewhere` / `picked-off` notification that is delivered to the remaining devices.

Enable the flow by setting `pushWhenActive: true` on `TxConfig`. The SDK handles the rest internally — no new `call.answer(...)` argument is required and the public API stays unchanged.

```Swift
let txConfig = TxConfig(
    sipUser: sipUser,
    password: password,
    pushDeviceToken: voipPushToken, // APNS VoIP token (required)
    pushWhenActive: true            // Opt-in to push-when-active multi-device
)
```

The `pushDeviceToken` value is the VoIP token your app receives from PushKit/APNS in `pushRegistry(_:didUpdate:for:)`. Login does not create this token; login registers the token you provide in `TxConfig`.

When `pushWhenActive` is `true`:

1. The login payload includes `push_when_active = "true"` in `userVariables` so the backend treats this device as active for push routing.
2. When `call.answer()` is invoked, the SDK sends `answered_device_token` (the same PushKit VoIP token supplied through `TxConfig(pushDeviceToken:)`) inside the `telnyx_rtc.answer` payload. The token is sourced internally from `pushNotificationConfig.pushDeviceToken`, so apps do not need to pass it again at answer time.
3. If push metadata includes `parent_call_id`, apps should use it as the CallKit UUID and fall back to `call_id` when it is missing. The SDK maps that CallKit ID to the socket `callID` internally after the INVITE arrives.
4. If the socket is already connected and the INVITE arrives without a push, the SDK uses the INVITE variable `telnyx_rtc_svar_parent_call_id` for the same CallKit-to-socket mapping.
5. If no `pushDeviceToken` is configured, or it is empty or whitespace-only, the `answered_device_token` field is omitted — the SDK never sends an unusable token.

The default value of `pushWhenActive` is `false`, which preserves the existing single-device behaviour exactly — no extra fields are added to either the login or the answer payload.

`call.answer()` is unchanged:

```Swift
call.answer()
```

### Handling calls answered on another device

When `pushWhenActive` is enabled, an incoming call can be delivered to more than one client or device. A web client may receive the call over an active WebSocket while iOS devices receive VoIP pushes. When one device answers, the Telnyx backend ends the call attempts on the remaining devices.

iOS apps should treat this as a normal **answered-elsewhere** outcome, not as a call failure. From the app's perspective, the call simply ends after the user has chosen to ignore the prompt — there is nothing to recover from and nothing to retry.

Your app should:

- dismiss the incoming-call UI
- stop any ringtone or vibration
- end the CallKit call if one is active
- mark the call as ended (or as answered elsewhere) in your own state
- avoid showing an error to the user

The SDK exposes the call termination through `CallState.DONE(reason:)` on the `TxClientDelegate` callback. Use the `reason` payload only for diagnostics — answered-elsewhere is a normal end and should not surface as an error.

```Swift
extension AppDelegate: TxClientDelegate {
    func onCallStateUpdated(callState: CallState, callId: UUID) {
        switch callState {
        case .DONE(let terminationReason):
            // Call ended normally — this covers user hangup, remote hangup,
            // INVITE timeout, AND the "answered on another device" case.
            // Do not show an error to the user for any of these.
            incomingCallUI.dismiss()
            ringtonePlayer.stop()
            endCallKitCall(callUUID: callId)

            if let reason = terminationReason {
                // Diagnostics only — never display to end users.
                print("Call ended: cause=\(reason.cause ?? "nil") "
                    + "sipCode=\(reason.sipCode ?? 0)")
            }
        // ...other states (NEW, CONNECTING, RINGING, ACTIVE, HELD, ...)
        default:
            break
        }
    }

    // ...other TxClientDelegate methods
}
```

`CallTerminationReason` (delivered through `CallState.DONE(reason:)` and the `onRemoteCallEnded(callId:reason:)` callback) exposes the same fields documented in [Error Handling — Call Termination Reasons](/docs-markdown/error-handling/error-handling.md#call-termination-reasons). In answered-elsewhere flows, the socket BYE commonly arrives as `PICKED_OFF` (`causeCode` 805, SIP 487). Apps should treat this as an expected outcome — not as a failure — when `pushWhenActive` is enabled.

#### CallKit behavior

When a CallKit call has already been reported for the incoming push, your app must end that CallKit call when another device answers. Use `.answeredElsewhere` so the system logs the call with the matching answered-elsewhere outcome:

```Swift
import CallKit

func endCallKitCall(callUUID: UUID) {
    // Use the CXProvider that reported the incoming call.
    callKitProvider.reportCall(with: callUUID, endedAt: Date(), reason: .answeredElsewhere)
}
```

Failing to end the CallKit call will leave the system call UI in a stale state and may block subsequent calls on that UUID. End the CallKit call from the same place you dismiss your own incoming-call UI — typically the `CallState.DONE` branch above.

#### PushKit cleanup notifications

Some answered-elsewhere and missed-call outcomes can arrive as VoIP pushes instead of, or in addition to, a socket BYE. These pushes are cleanup signals, not new incoming calls. Handle both alert strings through the same CallKit dismissal path:

```Swift
func pushRegistry(
    _ registry: PKPushRegistry,
    didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType,
    completion: @escaping () -> Void
) {
    defer { completion() }

    guard type == .voIP else { return }

    let payloadDictionary = payload.dictionaryPayload
    let aps = payloadDictionary["aps"] as? [String: Any]
    let alert = aps?["alert"] as? String

    if let callEndedReason = callEndedReason(forPushAlert: alert) {
        let metadata = payloadDictionary["metadata"] as? [String: Any]
        let callId = metadata?["call_id"] as? String
        let metadataUUID = callId.flatMap { UUID(uuidString: $0) }

        // Prefer the push call_id when present. If the cleanup push does not
        // include call_id, use the CallKit UUID saved when the original
        // incoming push was reported.
        if let callUUID = metadataUUID ?? currentIncomingCallKitUUID {
            reportPushCleanupCall(callUUID: callUUID, reason: callEndedReason)
        }

        return
    }

    // Otherwise process the payload as a normal incoming call.
    handleIncomingVoIPPush(payload)
}

func callEndedReason(forPushAlert alert: String?) -> CXCallEndedReason? {
    switch alert {
    case "Missed call!":
        return .unanswered
    case "Answered Elsewhere":
        return .answeredElsewhere
    default:
        return nil
    }
}

func reportPushCleanupCall(callUUID: UUID, reason: CXCallEndedReason) {
    let temporaryUUID = UUID()
    let update = CXCallUpdate()
    update.remoteHandle = CXHandle(type: .generic, value: " ")

    callKitProvider.reportNewIncomingCall(with: temporaryUUID, update: update) { _ in
        callKitProvider.reportCall(with: callUUID, endedAt: Date(), reason: reason)
        callKitProvider.reportCall(with: temporaryUUID, endedAt: Date(), reason: reason)
    }
}
```

The `reason` parameter is required by `CXProvider.reportCall(with:endedAt:reason:)`. Use `.unanswered` for `"Missed call!"` cleanup and `.answeredElsewhere` for `"Answered Elsewhere"` cleanup. Use the same reason for the temporary CallKit call that satisfies PushKit's requirement that every VoIP push reports a CallKit call.

### Expected flow

1. The app connects with `pushWhenActive: true` and a non-empty `pushDeviceToken`.
2. The SDK registers the device's VoIP push token with Telnyx.
3. An incoming call is delivered to multiple devices (push to iOS, WebSocket to web).
4. One device answers — the backend ends the remaining call attempts, commonly with a `PICKED_OFF` BYE on active sockets or an answered-elsewhere VoIP push for devices that need push cleanup.
5. The remaining iOS apps see `CallState.DONE(reason:)` and dismiss the incoming-call UI.

## Disable Push Notification

Push notifications can be disabled for the current user by calling :
```
telnyxClient.disablePushNotifications()
```
Note : Signing back in, using same credentials will re-enable push notifications.
