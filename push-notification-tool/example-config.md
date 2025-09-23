# Example Configuration

This file provides examples of how to use the VoIP Push Notification Tester with various configurations.

## Example 1: Basic Test with Minimal Payload

**Input Values:**
- Device Token: `a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456`
- Bundle ID: `com.telnyx.demo`
- Certificate Path: `/path/to/your/cert.pem`
- Private Key Path: `/path/to/your/key.pem`
- Environment: `sandbox`

**Expected Result:**
```json
{
  "metadata": {
    "voice_sdk_id": "12345678-abcd-1234-abcd-1234567890ab",
    "call_id": "87654321-dcba-4321-dcba-0987654321fe", 
    "caller_name": "Test Caller",
    "caller_number": "+1234567890"
  }
}
```

## Example 2: Custom Caller Information

**Custom Payload (added to metadata):**
```json
{
  "caller_name": "John Smith",
  "caller_number": "+15551234567",
  "department": "Sales",
  "priority": "high"
}
```

**Final Payload:**
```json
{
  "metadata": {
    "voice_sdk_id": "test-voice-sdk-1700000000000",
    "call_id": "test-call-1700000000000",
    "caller_name": "John Smith",
    "caller_number": "+15551234567",
    "department": "Sales",
    "priority": "high"
  }
}
```

## Example 3: Conference Call Simulation

**Custom Payload (added to metadata):**
```json
{
  "caller_name": "Conference Room A",
  "caller_number": "conference-room-a",
  "call_type": "conference",
  "participants": [
    {"name": "Alice", "number": "+15551111111"},
    {"name": "Bob", "number": "+15552222222"}
  ],
  "meeting_id": "meeting-123456"
}
```

## Example 4: Support Call with Priority

**Custom Payload (added to metadata):**
```json
{
  "caller_name": "Telnyx Support",
  "caller_number": "+18005551234",
  "call_type": "support",
  "priority": "urgent",
  "ticket_id": "SUP-789123",
  "estimated_wait_time": 120
}
```

## Device Token Retrieval

### In your iOS app (Swift):

```swift
// In your app delegate or similar
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
    voipRegistry.delegate = self
    voipRegistry.desiredPushTypes = [.voIP]
    return true
}

// PKPushRegistryDelegate method
func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
    if type == .voIP {
        let deviceTokenString = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
        print("VoIP Device Token: \(deviceTokenString)")
        // Use this token with the push notification tester
    }
}
```

## Certificate Setup (PEM Format)

Follow the [Telnyx Push Notification Portal Setup Guide](https://developers.telnyx.com/docs/voice/webrtc/ios-sdk/push-notification/portal-setup) for detailed instructions on creating and converting your certificates to PEM format.

### Quick Overview:
1. **Create a Push Notification Certificate:**
   - Go to Apple Developer Portal → Certificates, Identifiers & Profiles → Certificates
   - Create a new certificate for "Apple Push Notification service SSL"
   - Download the certificate (.cer file)

2. **Convert to PEM format:**
   ```bash
   # Convert certificate
   openssl x509 -in your_certificate.cer -inform DER -out cert.pem -outform PEM
   
   # Convert private key (if you have a .p12 file)
   openssl pkcs12 -in certificate.p12 -out key.pem -nodes -clcerts
   ```

3. **Verify PEM files:**
   - cert.pem should contain `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----`
   - key.pem should contain `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`

## Testing Checklist

- [ ] Device token is 64 hex characters
- [ ] Bundle ID matches your app exactly
- [ ] cert.pem file exists and contains valid certificate
- [ ] key.pem file exists and contains valid private key
- [ ] Private key passphrase is correct (if encrypted)
- [ ] Environment matches your app build (sandbox for dev/TestFlight, production for App Store)
- [ ] iOS app is properly configured for VoIP push notifications
- [ ] iOS app implements PKPushRegistryDelegate methods
- [ ] CallKit integration is working (if using CallKit)

## Common Payload Fields

Here are common fields you might want to include in your custom payload:

```json
{
  "callerName": "Display name for the caller",
  "handle": "Phone number or identifier",
  "hasVideo": true,
  "callType": "incoming|outgoing|conference|support",
  "callId": "unique-identifier-for-this-call",
  "metadata": {
    "any": "additional data your app needs"
  },
  "priority": "normal|high|urgent",
  "ttl": 3600,
  "customData": "any app-specific information"
}
```

## Testing Different Scenarios

### Scenario 1: App in Foreground
- App should receive push and handle immediately
- CallKit UI should appear if implemented

### Scenario 2: App in Background
- iOS should wake your app
- Background processing time is limited
- CallKit is essential for good UX

### Scenario 3: App Terminated
- iOS should launch your app
- App must handle the push in a reasonable time
- CallKit provides the best user experience

### Scenario 4: Device Locked
- CallKit shows incoming call on lock screen
- User can answer directly from lock screen
- App is launched when call is answered