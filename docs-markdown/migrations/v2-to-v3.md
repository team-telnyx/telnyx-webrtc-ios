# Migration Guide: v2.x to v3.0.0

This guide covers the migration from Telnyx WebRTC iOS SDK v2.x to v3.0.0.

## Overview

Version 3.0.0 introduces significant improvements to push notification handling and call flow management, while maintaining backward compatibility with existing implementations. The main enhancements focus on:

- Missed call notification handling
- Improved push notification call decline flow
- Optional Trickle ICE support for faster connection establishment

## Breaking Changes

### Missed Call Notification Handling (Required)

Starting in v3.0.0, Telnyx servers send "Missed call!" VoIP push notifications to all v3.x clients when a call is rejected remotely or missed. v2.x clients do not receive these notifications.

Per Apple's PushKit policy, every VoIP push notification **must** have a corresponding `reportNewIncomingCall` to CallKit. Since the original incoming call was already reported, the missed call push is a second delivery that also needs its own `reportNewIncomingCall`. The workaround is to report a temporary dummy call and immediately end both.

**Failure to handle these notifications will result in:**
- Apple disabling VoIP push notification delivery to your app
- Users no longer receiving incoming call notifications

#### Migration Steps

Update your VoIP push notification handler to detect missed call notifications and dismiss the CallKit UI:

```swift
func handleVoIPPushNotification(payload: PKPushPayload) {
    // Check if this is a missed call notification
    if let aps = payload.dictionaryPayload["aps"] as? [String: Any],
       let alert = aps["alert"] as? String,
       alert == "Missed call!" {

        // Handle missed call notification
        if let metadata = payload.dictionaryPayload["metadata"] as? [String: Any] {
            var callID = UUID().uuidString
            if let newCallId = (metadata["call_id"] as? String),
               !newCallId.isEmpty {
                callID = newCallId
            }

            if let uuid = UUID(uuidString: callID) {
                print("Received missed call notification for call: \(callID)")
                handleMissedCallNotification(callUUID: uuid)
            }
        }
        return
    }

    // Handle regular incoming call notification as before
    // ... your existing code
}

/// Handle missed call VoIP push notification.
///
/// Apple requires every VoIP push to have a corresponding `reportNewIncomingCall`.
/// Since the original incoming call was already reported, we report a temporary
/// dummy call for this second VoIP push and immediately end both calls.
func handleMissedCallNotification(callUUID: UUID) {
    guard let provider = callKitProvider else {
        print("CallKit provider not available for missed call handling")
        return
    }

    let tempUUID = UUID()
    let update = CXCallUpdate()
    update.remoteHandle = CXHandle(type: .generic, value: " ")

    provider.reportNewIncomingCall(with: tempUUID, update: update) { _ in
        // End the original incoming call that is ringing in CallKit
        provider.reportCall(with: callUUID, endedAt: Date(), reason: .answeredElsewhere)
        // End the temporary dummy call
        provider.reportCall(with: tempUUID, endedAt: Date(), reason: .answeredElsewhere)
    }

    // Clean up any stored call references
    // ... clean up your call state as needed
}
```

#### Push Notification Payload Format

Missed call notifications have a specific payload:

```json
{
  "aps": {
    "alert": "Missed call!"
  },
  "metadata": {
    "call_id": "uuid-of-the-call"
  }
}
```

Your app detects the `"Missed call!"` alert string to differentiate from regular incoming call notifications.

#### Implementation Reference

See the [demo app's AppDelegate.swift](https://github.com/team-telnyx/telnyx-webrtc-ios/blob/main/TelnyxWebRTCDemo/AppDelegate.swift) for a complete implementation example.

## Push Notification Flow Changes

### What Changed Internally

v3.0.0 introduces an internal improvement to how push notification calls are handled. This change is fully backward compatible and requires no code changes in your app.

#### v2.x Behavior

When a VoIP push notification was received:

1. App calls `processVoIPNotification(txConfig:serverConfiguration:pushMetaData:)`
2. SDK connects the WebSocket and immediately sends the login message
3. Once authenticated, the SDK waits for the INVITE
4. User accepts or declines via CallKit

#### v3.0.0 Behavior

When a VoIP push notification is received:

1. App calls `processVoIPNotification()` (same method signature)
2. SDK connects the WebSocket
3. On socket connect, SDK logs in immediately with context about the push origin
4. If the user has already accepted or declined via CallKit before the socket connected, the SDK includes that decision in the login (`decline_push: true/false`)
5. If no user action yet, the SDK logs in and waits for the INVITE

The key difference is that the SDK now tracks user actions (accept/decline) that happen while the socket is still connecting, so the login message carries the correct intent from the start. This eliminates race conditions between CallKit UI interactions and the socket connection.

#### Benefits

- Faster call decline — no need to wait for full authentication before rejecting
- Eliminates race conditions between login and CallKit UI
- Reduces unnecessary server load when the user quickly declines

### Migration Steps

**No action required.** Your existing app code continues to work without changes. Your app still:
- Calls `processVoIPNotification()` with the same parameters
- Uses CallKit actions (`CXAnswerCallAction`, `CXEndCallAction`) as before
- Receives the same delegate callbacks

### Verification

To verify the new flow, check your logs:

**v2.x logs:**
```
TxClient:: SocketDelegate onSocketConnected()
TxClient:: SocketDelegate onSocketConnected() login with Token
```

**v3.0.0 logs:**
```
TxClient:: SocketDelegate onSocketConnected()
TxClient:: Socket connected isCallFromPush == true
TxClient:: Socket connected from push - logging in immediately
```

## New Features

### 1. Push Notification Call Decline

#### What Changed

In v2.x, declining a call via push notification required the SDK to fully connect before properly rejecting. In v3.0.0, the SDK tracks the decline intent and sends it as part of the login message, providing a faster and more reliable decline.

#### Migration Steps

**No action required.** This improvement is automatic.

### 2. Trickle ICE Support (Optional)

#### What's New

Trickle ICE improves connection establishment time by sending ICE candidates as they are discovered, rather than waiting for all candidates to be gathered.

#### Migration Steps

This feature is opt-in. To enable:

```swift
let txConfig = TxConfig(
    sipUser: "your_sip_user",
    password: "your_password",
    useTrickleIce: true
)

try telnyxClient.connect(txConfig: txConfig)
```

Ensure `useTrickleIce` is passed consistently in all connection scenarios:
- Regular `connect()` calls
- VoIP push notification handling (`processVoIPNotification()`)
- Both Token and SIP credential authentication

#### Benefits

- Reduced call setup latency (typically 20-30% faster)
- Improved reliability in various network conditions

## Demo App Changes

The demo app has been updated to showcase all v3.0.0 features:

1. **Missed Call Notification Handling** — Detects "Missed call!" push notifications and dismisses CallKit UI. See `AppDelegate.swift`.
2. **Trickle ICE Toggle** — Settings UI to enable/disable Trickle ICE, persisted via UserDefaults. See `HomeViewController.swift`.
3. **Custom Server Configuration** — Connect to custom WebSocket servers for development/testing. See `CustomServerConfigView.swift`.

## Recommended Testing

### Missed Call Notifications

1. Have someone call your test device
2. Have the caller hang up before answering
3. Verify the CallKit UI dismisses automatically
4. Ensure no stale notifications can be accepted

### Push Notification Call Decline

1. Receive a VoIP push notification for an incoming call
2. Quickly decline the call via CallKit
3. Verify the call declines immediately without delays

### Trickle ICE (if enabled)

1. Make an outbound call with `useTrickleIce: true`
2. Test in various network conditions (Wi-Fi, cellular, network switching)
3. Verify call quality and connection stability

## Rollback Strategy

If you encounter issues, rollback to v2.x:

```ruby
# In your Podfile
pod 'TelnyxRTC', '~> 2.4.0'
```

```bash
pod update TelnyxRTC
```

## Support & Resources

- [GitHub Issues](https://github.com/team-telnyx/telnyx-webrtc-ios/issues)
- [Telnyx WebRTC Documentation](https://developers.telnyx.com/docs/v2/webrtc)
- [SDK Changelog](https://github.com/team-telnyx/telnyx-webrtc-ios/blob/main/CHANGELOG.md)
