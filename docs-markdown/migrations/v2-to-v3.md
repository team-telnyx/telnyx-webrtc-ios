# Migration Guide: v2.x to v3.0.0

This guide covers the migration from Telnyx WebRTC iOS SDK v2.x to v3.0.0.

## Overview

Version 3.0.0 introduces significant improvements to push notification handling and call flow management, while maintaining backward compatibility with existing implementations. The main enhancements focus on:

- Improved missed call notification handling
- Enhanced push notification call decline flow
- Optional Trickle ICE support for faster connection establishment

## ⚠️ Breaking Changes

### Missed Call Notification Handling (Required)

**Action Required:** v3.0.0 requires you to implement a handler for missed call VoIP push notifications.

**Why This is Critical:**

Per Apple's PushKit policy, apps receiving VoIP push notifications **must report all incoming calls to CallKit**. Starting in v3.0.0, Telnyx servers send "Missed call!" push notifications when calls are rejected remotely or missed.

**Failure to handle these notifications can result in:**
- ⚠️ Apple disabling VoIP push notification delivery to your app
- ⚠️ Users no longer receiving incoming call notifications
- ⚠️ Complete loss of VoIP functionality in your app

**This is not optional** - it's a mandatory requirement to maintain VoIP push notification functionality on iOS.

**SDK Compatibility Note:**

Your existing v2.x SDK integration will continue to work for regular calls without code changes. However, you **must** implement the missed call notification handler to comply with Apple's requirements and maintain VoIP functionality.

## Important: Push Notification Flow Changes

### What Changed Internally (No Action Required)

v3.0.0 introduces a **significant internal improvement** to how push notification calls are handled. This change is **fully backward compatible** and requires **no code changes** in your app, but understanding the new flow is important for debugging and optimization.

#### v2.x Behavior (Old Flow)

When a VoIP push notification was received in v2.x:

1. App calls `processVoIPNotification(txConfig:serverConfiguration:pushMetaData:)`
2. SDK internally calls `connectFromPush()` which:
   - Stores the `TxConfig`
   - Connects the WebSocket
3. When socket connects (`onSocketConnected()`):
   - SDK **immediately sends login message** to B2BUA
   - Client becomes authenticated and ready to receive INVITE
4. User can now accept or decline the call via CallKit
5. SDK processes the accept/decline action

**Issue with v2.x:** The SDK was already logged in before the user made a decision, which could cause race conditions and unnecessary server connections if the user quickly declined.

#### v3.0.0 Behavior (New Flow - Improved)

When a VoIP push notification is received in v3.0.0:

1. App calls `processVoIPNotification(txConfig:serverConfiguration:pushMetaData:)` (same method signature)
2. SDK internally calls `connectSocketOnly()` which:
   - Stores the `TxConfig` for later use
   - Connects the WebSocket **without logging in**
3. When socket connects (`onSocketConnected()`):
   - SDK detects `isCallFromPush == true`
   - SDK **waits for user action** (no login message sent yet)
4. User accepts or declines via CallKit:
   - **If user accepts**: SDK calls `performLogin(declinePush: false)` and sends login message
   - **If user declines**: SDK calls `performLogin(declinePush: true)` and sends login message with `decline_push` parameter
5. SDK processes the accept/decline action based on the login response

**Benefits of v3.0.0:**
- ✅ Faster call decline (no need to wait for full authentication)
- ✅ Eliminates race conditions between login and CallKit UI
- ✅ Reduces unnecessary server load if user quickly declines
- ✅ More predictable behavior for both accept and decline flows

### Migration Steps

**No action required** - Your existing app code continues to work without changes. The new flow is handled entirely within the SDK.

Your app still:
- Calls `processVoIPNotification()` with the same parameters
- Uses CallKit actions (`CXAnswerCallAction`, `CXEndCallAction`) as before
- Receives the same delegate callbacks

The improvement is **transparent** to your application code.

### Verification

To verify the new flow is working correctly, check your logs:

**v2.x logs (old):**
```
TxClient:: processVoIPNotification - No Active Calls disconnect
TxClient:: No Active Calls Connecting Again
TxClient:: SocketDelegate onSocketConnected()
TxClient:: SocketDelegate onSocketConnected() login with Token
```

**v3.0.0 logs (new):**
```
TxClient:: processVoIPNotification - No Active Calls disconnect
TxClient:: No Active Calls - Only connecting socket, not logging in
TxClient:: SocketDelegate onSocketConnected()
TxClient:: Socket connected from push - waiting for user action before login
[User accepts/declines]
TxClient:: answerFromCallkit - Socket connected, performing login with decline_push: false
```

Notice that in v3.0.0, the login happens **after** the user makes a decision.

## New Features & Improvements

### 1. Missed Call Handling

#### What Changed

In v2.x, when a call was rejected remotely (e.g., the caller hung up before you answered), the CallKit UI would remain visible, potentially allowing users to accept stale notifications. **Missed call notifications were not sent to v2.x clients.**

In v3.0.0, **Telnyx servers now send missed call push notifications** to iOS SDK v3.0.0+ clients. Your app can detect and handle these notifications to automatically dismiss the CallKit UI, preventing users from attempting to answer missed calls.

**Important:** Missed call push notifications are **only sent to iOS SDK v3.0.0 and higher**. Apps using v2.x will not receive these notifications.

#### Migration Steps

**Action Required** - To take advantage of missed call notifications in v3.0.0, you must implement the detection and handling logic in your app.

> **Note:** If you don't implement this handler, missed call push notifications will still be delivered to your app, but the CallKit UI will not be automatically dismissed. Implementing this handler is **strongly recommended** to provide the best user experience.

Update your VoIP push notification handler to detect and handle missed call notifications:

```swift
func handleVoIPPushNotification(payload: PKPushPayload) {
    // Check if this is a missed call notification
    if let aps = payload.dictionaryPayload["aps"] as? [String: Any],
       let alert = aps["alert"] as? String,
       alert == "Missed call!" {
        
        // Handle missed call notification
        if let metadata = payload.dictionaryPayload["metadata"] as? [String: Any] {
            var callID = UUID.init().uuidString
            if let newCallId = (metadata["call_id"] as? String),
               !newCallId.isEmpty {
                callID = newCallId
            }
            
            if let uuid = UUID(uuidString: callID) {
                print("Received missed call notification for call: \(callID)")
                handleMissedCallNotification(callUUID: uuid, pushMetaData: metadata)
            }
        }
        return
    }
    
    // Handle regular incoming call notification as before
    // ... your existing code
}

/// Handle missed call VoIP push notification by reporting the call as answered elsewhere
func handleMissedCallNotification(callUUID: UUID, pushMetaData: [String: Any]) {
    guard let provider = callKitProvider else {
        print("CallKit provider not available for missed call handling")
        return
    }
    
    // Report the call as ended with .answeredElsewhere reason to dismiss CallKit UI
    provider.reportCall(with: callUUID, endedAt: Date(), reason: .answeredElsewhere)
    print("Reported missed call as answered elsewhere for call: \(callUUID)")
    
    // Clean up any stored call references
    // ... clean up your call state as needed
}
```

#### How It Works

**Server-Side Behavior (v3.0.0+):**
- Telnyx servers detect when a call is missed or rejected remotely
- Servers send a special "Missed call!" push notification to **v3.0.0+ iOS clients only**
- v2.x clients do not receive these notifications

**Client-Side Implementation:**
When a VoIP push notification is received for a call that has already been rejected or missed:

1. Your app detects the "Missed call!" alert in the push payload
2. Calls `handleMissedCallNotification()` to report the call as ended
3. CallKit UI is automatically dismissed via `.answeredElsewhere` reason
4. Users cannot accept stale call notifications

This eliminates the race condition where CallKit notifications could appear before the SDK was ready to handle them properly.

#### Push Notification Payload Format

Missed call notifications have a specific payload structure:

```json
{
  "aps": {
    "alert": "Missed call!"
  },
  "metadata": {
    "call_id": "uuid-of-the-call",
    // ... other metadata fields
  }
}
```

Your app detects the `"Missed call!"` alert string to differentiate from regular incoming call notifications.

#### Implementation Reference

See the [demo app's AppDelegate.swift](https://github.com/team-telnyx/telnyx-webrtc-ios/blob/main/TelnyxWebRTCDemo/AppDelegate.swift) for a complete implementation example.

### 2. Push Notification Call Decline

#### What Changed

In v2.x, declining a call via push notification could experience race conditions, requiring the SDK to fully connect before properly declining the call.

In v3.0.0, calls can now be immediately rejected without waiting for full SDK connection, providing a faster and more reliable decline experience.

#### Migration Steps

**No action required** - This improvement is automatic and requires no code changes in your application.

#### Benefits

- Faster call decline response
- Eliminates race conditions with CallKit notifications
- Improved user experience when quickly declining calls

### 3. Trickle ICE Support (Optional)

#### What's New

Trickle ICE improves connection establishment time and reliability by sending ICE candidates immediately as they are discovered, rather than waiting for all candidates to be gathered.

#### Migration Steps

This feature is **opt-in**. To enable Trickle ICE:

**1. Basic Implementation**

```swift
// Create your TxConfig with Trickle ICE enabled
let txConfig = TxConfig(
    sipUser: "your_sip_user",
    password: "your_password",
    useTrickleIce: true  // Enable Trickle ICE
)

// Connect as usual
try telnyxClient.connect(txConfig: txConfig)
```

**2. Persistent Setting (Recommended)**

For production apps, store the Trickle ICE preference in UserDefaults:

```swift
// UserDefaults extension
extension UserDefaults {
    func saveUseTrickleIce(_ enabled: Bool) {
        set(enabled, forKey: "USE_TRICKLE_ICE")
        synchronize()
    }
    
    func getUseTrickleIce() -> Bool {
        // Default to true if not set (recommended for v3.0.0+)
        if object(forKey: "USE_TRICKLE_ICE") == nil {
            return true
        }
        return bool(forKey: "USE_TRICKLE_ICE")
    }
}

// Use the setting when creating TxConfig
let useTrickleIce = UserDefaults.standard.getUseTrickleIce()

let txConfig = TxConfig(
    sipUser: "your_sip_user",
    password: "your_password",
    useTrickleIce: useTrickleIce
)

// Also pass it when processing VoIP notifications
try telnyxClient.processVoIPNotification(
    txConfig: txConfig,
    serverConfiguration: serverConfig,
    pushMetaData: pushMetaData
)
```

**3. Default Value on First Launch**

```swift
// Initialize default values on first app launch
private func initializeUserDefaults() {
    let hasInitializedDefaults = UserDefaults.standard.bool(
        forKey: "HasInitializedTrickleICEDefaults"
    )
    
    if !hasInitializedDefaults {
        // Set Trickle ICE to true by default for new users
        if UserDefaults.standard.object(forKey: "USE_TRICKLE_ICE") == nil {
            UserDefaults.standard.saveUseTrickleIce(true)
        }
        
        UserDefaults.standard.set(true, forKey: "HasInitializedTrickleICEDefaults")
        UserDefaults.standard.synchronize()
    }
}
```

#### Important: Apply to All Connection Points

Ensure `useTrickleIce` is passed consistently in **all** connection scenarios:

- ✅ Regular `connect()` calls
- ✅ VoIP push notification handling (`processVoIPNotification()`)
- ✅ Both Token and SIP credential authentication

#### Benefits

- Reduced call setup latency (typically 20-30% faster)
- Faster connection establishment
- Improved reliability in various network conditions
- Better performance on slower networks

#### When to Use

Enable Trickle ICE if:
- You want to minimize call setup time
- Your application operates in environments with varying network conditions
- You're starting fresh with v3.0.0 (recommended as default)

Keep it disabled if:
- Your current implementation works well without it
- You prefer to test the feature before rolling it out to production
- You need to maintain parity with legacy systems that don't support Trickle ICE

#### Implementation Reference

See the demo app for complete implementation examples:
- [UserDefaultExtension.swift](https://github.com/team-telnyx/telnyx-webrtc-ios/blob/main/TelnyxWebRTCDemo/Extensions/UserDefaultExtension.swift) - Trickle ICE storage
- [HomeViewController.swift](https://github.com/team-telnyx/telnyx-webrtc-ios/blob/main/TelnyxWebRTCDemo/ViewControllers/HomeViewController.swift) - Trickle ICE configuration
- [AppDelegateCallKitExtension.swift](https://github.com/team-telnyx/telnyx-webrtc-ios/blob/main/TelnyxWebRTCDemo/Extensions/AppDelegateCallKitExtension.swift) - VoIP notification handling

## Demo App Changes

The demo app has been updated to showcase all v3.0.0 features. Key changes include:

### New Features in Demo App

1. **Missed Call Notification Handling**
   - Detects "Missed call!" push notifications
   - Automatically dismisses CallKit UI for missed calls
   - See: `AppDelegate.swift` → `handleMissedCallNotification()`

2. **Trickle ICE Toggle**
   - Settings UI to enable/disable Trickle ICE
   - Persistent storage via UserDefaults
   - Default enabled for new installations
   - See: `HomeViewController.swift` → `showHiddenOptions()`

3. **Custom Server Configuration** (Development/Testing)
   - Ability to connect to custom WebSocket servers
   - Useful for local development and testing
   - See: `CustomServerConfigView.swift`

### Demo App as Reference Implementation

The demo app serves as the **reference implementation** for all v3.0.0 features. When implementing:

1. **Review the demo app first** - It demonstrates best practices
2. **Check all connection points** - Regular calls, VoIP notifications, etc.
3. **Test both authentication methods** - Token and SIP credentials

### Comparing v2.4.0 vs v3.0.0 Demo App

Key file changes:
- `AppDelegate.swift` - Missed call handling logic added
- `AppDelegateCallKitExtension.swift` - Trickle ICE support in VoIP notifications
- `UserDefaultExtension.swift` - New settings for Trickle ICE and custom servers
- `HomeViewController.swift` - UI for Trickle ICE toggle and initialization

Run this command to see all demo app changes:
```bash
git diff 2.4.0..3.0.0 -- TelnyxWebRTCDemo/
```

## Recommended Testing

While v3.0.0 is backward compatible, we recommend testing these scenarios to verify the improvements:

### Missed Call Notifications

1. Have someone call your test device
2. Have the caller hang up before answering
3. Verify the CallKit UI dismisses automatically
4. Ensure no stale notifications can be accepted

### Push Notification Call Decline

1. Receive a VoIP push notification for an incoming call
2. Quickly decline the call via CallKit
3. Verify the call declines immediately without delays
4. Check that no race conditions occur during SDK connection

### Trickle ICE (if enabled)

1. Make an outbound call with `useTrickleIce: true`
2. Measure call setup time compared to v2.x
3. Test in various network conditions (Wi-Fi, cellular, network switching)
4. Verify call quality and connection stability

## Rollback Strategy

If you encounter any issues with v3.0.0, you can safely rollback to v2.x:

```ruby
# In your Podfile
pod 'TelnyxRTC', '~> 2.4.0'
```

Then run:
```bash
pod update TelnyxRTC
```

## Support & Resources

- [GitHub Issues](https://github.com/team-telnyx/telnyx-webrtc-ios/issues)
- [Telnyx WebRTC Documentation](https://developers.telnyx.com/docs/v2/webrtc)
- [SDK Changelog](https://github.com/team-telnyx/telnyx-webrtc-ios/blob/main/CHANGELOG.md)

## Summary

v3.0.0 brings significant improvements to push notification handling and call flow management without requiring code changes. The automatic improvements to missed call handling and push notification call decline enhance the user experience, while Trickle ICE provides an optional performance boost for applications that need it.

All v2.x applications can upgrade to v3.0.0 with confidence, as the SDK maintains full backward compatibility.
