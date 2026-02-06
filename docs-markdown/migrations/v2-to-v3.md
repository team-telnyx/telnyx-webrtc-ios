# Migration Guide: v2.x to v3.0.0

This guide covers the migration from Telnyx WebRTC iOS SDK v2.x to v3.0.0.

## Overview

Version 3.0.0 introduces significant improvements to push notification handling and call flow management, while maintaining backward compatibility with existing implementations. The main enhancements focus on:

- Improved missed call notification handling
- Enhanced push notification call decline flow
- Optional Trickle ICE support for faster connection establishment

## Breaking Changes

**None** - v3.0.0 is fully backward compatible with v2.x implementations. All changes are opt-in or automatic improvements that don't require code changes.

## New Features & Improvements

### 1. Missed Call Handling

#### What Changed

In v2.x, when a call was rejected remotely (e.g., the caller hung up before you answered), the CallKit UI would remain visible, potentially allowing users to accept stale notifications.

In v3.0.0, the SDK now automatically dismisses the CallKit UI when calls are rejected remotely, preventing users from attempting to answer missed calls.

#### Migration Steps

**No action required** - This improvement is automatic and requires no code changes in your application.

#### How It Works

When a VoIP push notification is received for a call that has already been rejected or missed:

1. The SDK detects the call has ended remotely
2. CallKit UI is automatically dismissed
3. Users cannot accept stale call notifications

This eliminates the race condition where CallKit notifications could appear before the SDK was ready to handle them properly.

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

#### Benefits

- Reduced call setup latency
- Faster connection establishment
- Improved reliability in various network conditions

#### When to Use

Enable Trickle ICE if:
- You want to minimize call setup time
- Your application operates in environments with varying network conditions
- You're starting fresh with v3.0.0

Keep it disabled if:
- Your current implementation works well without it
- You prefer to test the feature before rolling it out to production

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
