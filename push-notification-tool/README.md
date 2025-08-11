# Telnyx VoIP Push Notification Tester

A simple Node.js/TypeScript tool to test VoIP push notifications for iOS apps using the Telnyx WebRTC SDK. This tool helps developers validate their certificate setup and test their app's VoIP integration.

## Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- iOS app with VoIP capabilities configured
- Apple Push Notification certificate files (cert.pem and key.pem)
- Device token from your iOS app

## Quick Start

1. **Navigate to the tool directory**:
   ```bash
   cd push-notification-tool
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Run the tool**:
   ```bash
   npm run dev
   ```

4. **Follow the interactive prompts** to configure and send a test push notification.

## Smart Configuration Management

The tool automatically saves your configuration and offers smart options on subsequent runs:

### First Time Usage
- **Fresh Setup**: Complete configuration wizard for new users
- All settings are saved for future use

### Subsequent Usage
The tool presents three options:
1. **Use Previous Configuration**: Quick start with saved settings
2. **Update Some Values**: Selectively modify specific fields (device token, certificates, etc.)
3. **Start Fresh**: Complete new configuration setup

### Configuration Features
- **Automatic Save**: Settings are saved after successful configuration
- **Smart Defaults**: Previous values shown in brackets `[current_value]`
- **Quick Updates**: Press Enter to keep current values, or type new ones
- **Secure Storage**: Sensitive data like passphrases are never saved

## What You'll Need

### 1. Device Token
- A 64-character hex string obtained from your iOS app
- Usually retrieved in your app's delegate methods after registering for VoIP notifications

### 2. Bundle ID
- Your app's bundle identifier (e.g., `com.yourcompany.yourapp`)
- Must match the one used in your Apple Developer Portal

### 3. Apple Push Notification Certificate Files
- **cert.pem**: Your Apple Push Notification certificate in PEM format
- **key.pem**: Your private key in PEM format
- These files are typically generated when you create a push notification certificate in Apple Developer Portal
- Follow the [Telnyx Push Notification Setup Guide](https://developers.telnyx.com/docs/voice/webrtc/ios-sdk/push-notification/portal-setup) for detailed instructions

## Usage Examples

### Basic Test
The tool will prompt you for all required information:
- Device token (64 hex characters)
- Bundle ID
- Path to cert.pem file
- Path to key.pem file
- Environment (sandbox/production)

## Default VoIP Payload Structure

The tool automatically generates a VoIP notification with the payload structure expected by the Telnyx iOS SDK:

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

### Required Fields in `metadata`:
- **`voice_sdk_id`**: UUID for establishing WebSocket connection to Telnyx servers
- **`call_id`**: UUID for the incoming call

### Optional Fields in `metadata`:
- **`caller_name`**: Display name for CallKit and UI
- **`caller_number`**: Phone number or caller identifier

The tool automatically generates proper UUIDs for `voice_sdk_id` and `call_id` on each run.

## Build and Run Options

### Development Mode
```bash
npm run dev
```
Runs directly with ts-node for quick testing.

### Production Build
```bash
npm run build
npm start
```
Compiles TypeScript to JavaScript and runs the compiled version.

### Clean Build
```bash
npm run clean
npm run build
```

## Troubleshooting

### Common Issues

1. **Invalid Device Token**
   - Ensure the token is exactly 64 hex characters
   - Remove any spaces or special characters
   - Make sure you're using a VoIP token, not a regular push token

2. **Certificate Issues**
   - Verify both cert.pem and key.pem file paths are correct
   - Ensure certificate files are in proper PEM format
   - Check that the certificate is valid and not expired
   - Make sure the private key is not encrypted (tool assumes no passphrase)

3. **Bundle ID Mismatch**
   - Bundle ID must exactly match your app's identifier
   - For VoIP, the topic becomes `{bundleId}.voip`

4. **Environment Selection**
   - Use `sandbox` for development/TestFlight builds
   - Use `production` for App Store builds
   - Wrong environment will result in delivery failures

### Expected iOS App Behavior

When the push is sent successfully, your iOS app should:
1. Receive the VoIP notification even when backgrounded/terminated
2. Trigger your `pushRegistry:didReceiveIncomingPushWithPayload:` method
3. Present a CallKit incoming call UI (if properly implemented)
4. Connect to Telnyx servers using the payload data

## Integration with Telnyx iOS SDK

This tool generates VoIP notifications compatible with the Telnyx WebRTC iOS SDK. The payload structure matches what the SDK expects for incoming call notifications.

### Typical iOS App Flow:
1. App registers for VoIP notifications
2. App sends device token to Telnyx servers
3. Incoming call triggers this tool (or Telnyx servers) to send VoIP push
4. iOS receives push and wakes app
5. App processes payload and establishes WebRTC connection
6. Call UI is presented to user

## File Structure

```
push-notification-tool/
├── src/
│   └── index.ts          # Main application code
├── dist/                 # Compiled JavaScript (after build)
├── package.json          # Dependencies and scripts
├── tsconfig.json         # TypeScript configuration
└── README.md            # This file
```

## Security Notes

- Never commit your certificate files (cert.pem, key.pem) to version control
- Store certificate files securely and restrict access
- Use environment variables for production deployments
- Validate device tokens before using them
- Use unencrypted private keys for simplicity (or encrypt them outside the tool)

## Contributing

This tool is part of the Telnyx iOS WebRTC SDK repository. When making changes:
1. Follow the existing TypeScript conventions
2. Update this README if adding new features
3. Test with both sandbox and production environments
4. Ensure compatibility with the iOS SDK payload format