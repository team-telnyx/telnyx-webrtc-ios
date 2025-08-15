## Push Notification Troubleshooting

This guide helps you troubleshoot common issues that prevent push notifications from being delivered in the Telnyx WebRTC iOS SDK.

## Common Points of Failure

### 1. VoIP Push Notification Certificate

One of the most critical components for iOS push notifications is the VoIP Push Notification Certificate. A single VoIP Services Certificate supports both sandbox and production environments for the same bundle ID.

**How to verify:**
- Check that you have generated a valid VoIP Services Certificate in the Apple Developer Portal
- Verify that the certificate is not expired
- Ensure the certificate is generated for the correct bundle ID used in your app
- Verify that the VoIP Services Certificate establishes connectivity between your notification server and both APNS sandbox and production environments

**Solution:**
- Follow [Apple's official documentation](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_certificate-based_connection_to_apns) to generate a new VoIP Services Certificate
- Upload the certificate to the Telnyx Portal
- Ensure the certificate matches your app's bundle ID
- For different bundle IDs (e.g., com.myapp.dev, com.myapp), create separate VoIP Services Certificates
- Note: A separate certificate is required for each app you distribute, but each certificate works for both sandbox and production

### 2. Push Token Not Passed to Login

A common issue is that the push token is not being passed correctly during the login process.

**How to verify:**
- Check your application logs to ensure the push token is being retrieved successfully
- Verify that the login message contains the push token
- Look for logs similar to: `Push token received: [your-token]`

**Solution:**
- Make sure you're retrieving the push token as shown in the [App Setup](https://developers.telnyx.com/docs/voice/webrtc/ios-sdk/push-notification/app-setup) guide
- Ensure the token is passed to the `connect()` method within the [TelnyxConfig](https://developers.telnyx.com/docs/voice/webrtc/ios-sdk/structs/tx-config) object
- Verify that the token is not null or empty before passing it

### 3. Wrong Push Credential Assigned to SIP Connection

If the push credential is not correctly assigned to your SIP credential, the server won't know where to send push notifications.

**How to verify:**
- Log into the Telnyx Portal and check your SIP Connection settings
- Verify that the correct iOS VoIP push credential is selected in the WebRTC tab

**Solution:**
- Follow the steps in the [Portal Setup](https://developers.telnyx.com/docs/voice/webrtc/ios-sdk/push-notification/portal-setup) guide to properly assign the push credential
- Make sure you've selected the correct credential for your application.
- If using multiple environments, ensure each has its own SIP connection with the appropriate certificate

### 4. APNS Environment Mismatch

OS apps can target either the APNS Sandbox (development) or Production environment, and this must align with your build configuration.

**How to verify:**
- Check your build configuration (Debug vs Release).
- Ensure that the APNS environment setting in your TxConfig (`pushEnvironment` property) is not being forced.
- Confirm that the correct VoIP Services Certificate, valid for both production and development, is uploaded to the Telnyx Portal.

**Solution:**
- For Debug builds running from Xcode:
  * Use a Sandbox (development) certificate
  * Set `pushEnvironment` to `sandbox` in TelnyxConfig if needed
- For Release builds or TestFlight:
  * Use a Production certificate
  * Set `pushEnvironment` to `production` in TelnyxConfig if needed
- If generating an IPA:
  * Ensure it's signed with the correct profile (development or distribution)
  * Match the APNS environment to your signing profile

### 5. Info.plist Configuration

Proper configuration in Info.plist is essential for push notifications to work.

**How to verify:**
- Check that push notifications are enabled in your app's capabilities
- Verify that VoIP push notifications are properly configured
- Ensure background modes are enabled for VoIP

**Solution:**
- Add the following to your Info.plist:
  ```xml
  <key>UIBackgroundModes</key>
  <array>
      <string>voip</string>
  </array>
  ```
- Enable "Voice over IP" and "Background fetch" in Xcode capabilities
- Verify that your app has the required entitlements for push notifications

## Testing VoIP Push Notifications

### VoIP Push Notification Testing Tool

To help validate your push notification setup, the repository includes a dedicated testing tool that allows you to send test VoIP push notifications directly to your device.

**Location:** `push-notification-tool/` in the repository root

### Quick Setup

1. **Navigate to the tool directory:**
   ```bash
   cd push-notification-tool
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Run the tool:**
   ```bash
   npm run dev
   ```

### What You'll Need

- **Device Token**: 64-character hex string from your iOS app's VoIP registration
- **Bundle ID**: Your app's identifier (e.g., `com.yourcompany.app`)
- **Certificate Files**: `cert.pem` and `key.pem` from your VoIP push certificate
- **Environment**: `sandbox` for development/TestFlight, `production` for App Store

### How It Works

The tool generates VoIP push notifications with the exact payload structure expected by the Telnyx iOS SDK:

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

### Testing Workflow

1. **Configure Once**: Enter your device token, bundle ID, certificate paths, and environment
2. **Send Test Push**: The tool sends a VoIP notification to your device
3. **Verify Receipt**: Check that your app receives the push and processes it correctly
4. **Continuous Testing**: Send multiple pushes, reconfigure settings, or test different scenarios
5. **Troubleshoot Issues**: Use detailed error responses to identify configuration problems

### Common Test Scenarios

- **Certificate Validation**: Verify your cert.pem and key.pem files work
- **Environment Testing**: Test both sandbox and production APNS environments
- **Device Token Validation**: Confirm your app generates valid VoIP device tokens
- **Payload Processing**: Ensure your app correctly handles the metadata structure
- **Multiple Devices**: Quickly switch between different device tokens
- **Reliability Testing**: Send multiple pushes to test consistency

### Troubleshooting with the Tool

The tool provides detailed error responses that help identify issues:

- **BadDeviceToken**: Device token is invalid or expired
- **BadCertificate**: Certificate files are invalid or expired
- **BadTopic**: Bundle ID doesn't match certificate
- **DeviceTokenNotForTopic**: Device token doesn't match certificate bundle ID
- **TopicDisallowed**: Certificate doesn't have VoIP permissions

### Integration Testing

After successful push delivery, verify your app:

1. **Receives the Push**: Check that `pushRegistry:didReceiveIncomingPushWithPayload:` is called
2. **Processes Metadata**: Verify `voice_sdk_id` and `call_id` are extracted correctly
3. **Calls processVoIPNotification**: Ensure the SDK method is called with correct parameters
4. **Shows CallKit UI**: Confirm incoming call interface appears (if using CallKit)
5. **Establishes Connection**: Verify WebSocket connection to Telnyx servers

## Additional Troubleshooting Steps

1. **Check APNS Status**
   - Use Apple's developer tools to verify APNS connectivity
   - Monitor for any APNS feedback about invalid tokens or delivery failures

2. **Verify Bundle ID Configuration**
   - Ensure your bundle ID matches across:
     * Xcode project settings
     * Provisioning profiles
     * VoIP push certificates
     * Telnyx Portal configuration

3. **Test with Development Environment First**
   - Start testing with sandbox/development environment
   - Use debug builds and development certificates
   - Monitor system logs for push notification related messages

4. **Check Network Connectivity**
   - Ensure your device has a stable internet connection
   - Verify that your app can connect to APNS servers
   - Test both Wi-Fi and cellular connections

5. **Verify Certificate Validity**
   - Check the expiration date of your VoIP push certificate
   - Ensure the certificate is properly exported with private key
   - Verify the certificate is in the correct format when uploaded to Telnyx

## Still Having Issues?

If you've gone through all the troubleshooting steps and are still experiencing problems:

1. Check the Telnyx WebRTC SDK documentation for any updates or known issues
2. Contact Telnyx Support with detailed information about your setup and the issues you're experiencing
3. Include logs, error messages, and steps to reproduce the problem when contacting support
4. Provide your development environment details:
   - Xcode version
   - iOS version
   - SDK version
   - Build configuration (Debug/Release)
   - Certificate type (Development/Production)