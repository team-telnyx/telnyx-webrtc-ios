# Migration Guide: v3.x to v4.0.0

This guide covers the migration from Telnyx WebRTC iOS SDK v3.x to v4.0.0.

## Overview

Version 4.0.0 introduces a new opt-in mechanism for missed call notifications and an improved push notification login flow. The main changes are:

- Opt-in `enableMissedCallNotifications` flag on `TxConfig`
- Immediate login after socket connects from a VoIP push notification
- Missed call notifications delivered when calls end before the socket connects

## Breaking Changes

### Missed Call Notifications Are Now Opt-In

In v3.x, all clients receive missed call VoIP push notifications. In v4.0.0, this behavior is controlled by the `enableMissedCallNotifications` flag on `TxConfig`.

**Default value:** `false` (disabled)

When enabled, the SDK sends the user agent as `iOS-mpn-<sdk-version>` instead of the default `iOS-<sdk-version>`. This signals to Telnyx servers that your app supports missed call notifications.

#### Migration Steps

If your app already handles missed call notifications (as described in the [v2-to-v3 migration guide](./v2-to-v3.md)), enable the flag to continue receiving them:

**SIP credentials:**

```swift
let txConfig = TxConfig(
    sipUser: sipUser,
    password: password,
    pushDeviceToken: pushToken,
    enableMissedCallNotifications: true
)
```

**Token authentication:**

```swift
let txConfig = TxConfig(
    token: token,
    pushDeviceToken: pushToken,
    enableMissedCallNotifications: true
)
```

Pass this flag consistently in all connection scenarios:
- Regular `connect()` calls
- VoIP push notification handling (`processVoIPNotification()`)
- Both Token and SIP credential authentication

If your app does **not** handle missed call notifications, no action is needed — the default (`false`) means Telnyx servers will not send missed call pushes to your app.

## Push Notification Flow Changes

### What Changed

v4.0.0 changes the push notification login flow. After the WebSocket connects from a VoIP push, the SDK now logs in immediately instead of waiting for the user to accept or decline via CallKit.

#### v3.x Behavior

1. VoIP push arrives, app calls `processVoIPNotification()`
2. SDK connects the WebSocket without logging in
3. SDK waits for the user to accept or decline via CallKit
4. Based on the user's action, SDK sends login with `decline_push: true/false`

#### v4.0.0 Behavior

1. VoIP push arrives, app calls `processVoIPNotification()`
2. SDK connects the WebSocket
3. On socket connect, SDK logs in immediately (does not wait for user action)
4. If the user has already accepted or declined via CallKit before the socket connected, the login includes that decision
5. If the call ended before the socket connected (e.g., the caller hung up), and `enableMissedCallNotifications` is `true`, the server sends a "Missed call!" VoIP push notification

The immediate login reduces latency for call setup and simplifies the internal state machine.

### Missed Call Notification Handling

The handling code for missed call notifications remains the same as in v3.x. If you already implemented the temporary CallKit call workaround from the [v2-to-v3 migration guide](./v2-to-v3.md), keep that flow and report the ended calls as `.unanswered`:

```swift
func handleVoIPPushNotification(payload: PKPushPayload) {
    if let aps = payload.dictionaryPayload["aps"] as? [String: Any],
       let alert = aps["alert"] as? String,
       alert == "Missed call!" {

        if let metadata = payload.dictionaryPayload["metadata"] as? [String: Any] {
            var callID = UUID().uuidString
            if let newCallId = (metadata["call_id"] as? String),
               !newCallId.isEmpty {
                callID = newCallId
            }

            if let uuid = UUID(uuidString: callID) {
                handleMissedCallNotification(callUUID: uuid)
            }
        }
        return
    }

    // Handle regular incoming call notification
    // ... your existing code
}

func handleMissedCallNotification(callUUID: UUID) {
    guard let provider = callKitProvider else { return }

    let tempUUID = UUID()
    let update = CXCallUpdate()
    update.remoteHandle = CXHandle(type: .generic, value: " ")

    provider.reportNewIncomingCall(with: tempUUID, update: update) { _ in
        provider.reportCall(with: callUUID, endedAt: Date(), reason: .unanswered)
        provider.reportCall(with: tempUUID, endedAt: Date(), reason: .unanswered)
    }
}
```

## Migration Checklist

- **Enable missed call notifications (optional):** Add `enableMissedCallNotifications: true` to your `TxConfig` in all connection points if you want to continue receiving missed call pushes.
- **Handle missed call pushes (only if flag is enabled):** Implement the dummy CallKit call workaround (same as v3.x).
- **Update Podfile:** Point to v4.0.0.
- **No other code changes required.** The immediate-login behavior is handled internally by the SDK.

## Recommended Testing

### Missed Call Notifications (if enabled)

1. Enable `enableMissedCallNotifications: true` in your `TxConfig`
2. Receive a VoIP push for an incoming call
3. Have the caller hang up quickly (before your app connects the socket)
4. Verify a "Missed call!" push is received and the CallKit UI dismisses
5. Verify that calls answered normally are not affected

### Without Missed Call Notifications

1. Leave `enableMissedCallNotifications` as default (`false`)
2. Verify incoming calls work as before
3. Verify no "Missed call!" pushes are received

## Rollback Strategy

If you encounter issues, rollback to v3.x:

```ruby
# In your Podfile
pod 'TelnyxRTC', '~> 3.0.0'
```

```bash
pod update TelnyxRTC
```

## Support & Resources

- [GitHub Issues](https://github.com/team-telnyx/telnyx-webrtc-ios/issues)
- [Telnyx WebRTC Documentation](https://developers.telnyx.com/docs/v2/webrtc)
- [SDK Changelog](https://github.com/team-telnyx/telnyx-webrtc-ios/blob/main/CHANGELOG.md)
