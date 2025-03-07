# Push Notification Troubleshooting

This guide helps you troubleshoot common issues that prevent push notifications from being delivered in the Telnyx WebRTC iOS SDK.

## Common Points of Failure

### 1. VoIP Push Notification Certificate

One of the most critical components for iOS push notifications is the VoIP Push Notification Certificate.

**How to verify:**
- Check that you have generated a valid VoIP Push Notification Certificate in the Apple Developer Portal
- Verify that the certificate is not expired
- Ensure the certificate is generated for the correct bundle ID used in your app
- Confirm whether you need a development (sandbox) or production certificate based on your build configuration

**Solution:**
- Follow Apple's official documentation to generate a new VoIP Push Notification Certificate
- Upload the correct certificate (development or production) to the Telnyx Portal
- Ensure the certificate matches your app's bundle ID
- For different environments (development, staging, production), create separate certificates if using different bundle IDs

### 2. Push Token Not Passed to Login

A common issue is that the push token is not being passed correctly during the login process.

**How to verify:**
- Check your application logs to ensure the push token is being retrieved successfully
- Verify that the login message contains the push token
- Look for logs similar to: `Push token received: [your-token]`

**Solution:**
- Make sure you're retrieving the push token as shown in the [App Setup](https://developers.telnyx.com/docs/voice/webrtc/ios-sdk/push-notification/app-setup) guide
- Ensure the token is passed to the `connect()` method within the [TelnyxConfig](https://developers.telnyx.com/docs/voice/webrtc/ios-sdk/config/txconfig) object
- Verify that the token is not null or empty before passing it

### 3. Wrong Push Credential Assigned to SIP Connection

If the push credential is not correctly assigned to your SIP credential, the server won't know where to send push notifications.

**How to verify:**
- Log into the Telnyx Portal and check your SIP Connection settings
- Verify that the correct iOS VoIP push credential is selected in the WebRTC tab

**Solution:**
- Follow the steps in the [Portal Setup](https://developers.telnyx.com/docs/voice/webrtc/ios-sdk/push-notification/portal-setup) guide to properly assign the push credential
- Make sure you've selected the correct credential for your application environment (development or production)
- If using multiple environments, ensure each has its own SIP connection with the appropriate certificate

### 4. APNS Environment Mismatch

iOS apps can target either the APNS Sandbox (development) or Production environment, and this must match your certificate and build configuration.

**How to verify:**
- Check your build configuration (Debug vs Release)
- Verify the APNS environment setting in your TelnyxConfig
- Confirm which certificate (development or production) is uploaded to the Telnyx Portal

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