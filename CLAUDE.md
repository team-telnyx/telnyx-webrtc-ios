# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the Telnyx iOS Voice SDK - a WebRTC-based voice calling solution for iOS applications. The project consists of a demo application and the core `TelnyxRTC` framework.

## Code Style
- Please reference the [Swift Style Guide](https://google.github.io/swift/) for general Swift coding conventions.
- Follow Apple's [API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) for public APIs.

## Workflow
- Don't change the verto message json structure without confirming first.
- When making changes to the SDK, ensure that you update the demo application accordingly to demonstrate the new functionality.
- Follow the established architecture patterns for WebRTC, including peer connection management, ICE candidate handling, and call state management.
- Ensure that all new features and bug fixes are accompanied by appropriate unit tests in the `TelnyxRTCTests` target.
- If asked to make a pull request, ensure you use the format described at .github/pull_request_template.md, including a clear description of the changes, any relevant issue numbers, and testing instructions.
- Please do not update podspec and Podfile files without confirming the changes with the team first.

## Development Commands

### Building and Running
```bash
# Open the workspace
open TelnyxRTC.xcworkspace

# Build the framework
xcodebuild -workspace TelnyxRTC.xcworkspace -scheme TelnyxRTC -configuration Release

# Run tests
xcodebuild test -workspace TelnyxRTC.xcworkspace -scheme TelnyxRTC -destination 'platform=iOS Simulator,name=iPhone 14'

# Build the demo app
xcodebuild -workspace TelnyxRTC.xcworkspace -scheme TelnyxWebRTCDemo -configuration Debug
```

### Development Tools
```bash
# Install dependencies
pod install

# Update dependencies
pod update

# Clean build artifacts
xcodebuild clean -workspace TelnyxRTC.xcworkspace -scheme TelnyxRTC
```

### Testing
```bash
# Run unit tests
xcodebuild test -workspace TelnyxRTC.xcworkspace -scheme TelnyxRTC -destination 'platform=iOS Simulator,name=iPhone 14'

# Run UI tests
xcodebuild test -workspace TelnyxRTC.xcworkspace -scheme TelnyxWebRTCDemoUITests -destination 'platform=iOS Simulator,name=iPhone 14'
```

## Architecture Overview

### Project Structure
- `/TelnyxRTC/` - Core SDK framework
- `/TelnyxWebRTCDemo/` - Demo application
- `/TelnyxRTCTests/` - Unit tests
- `/TelnyxWebRTCDemoUITests/` - UI tests
- `/docs-markdown/` - API documentation

### Core SDK Architecture (`/TelnyxRTC/`)

**Main Classes:**
- `TxClient` - Primary SDK entry point for connection management
- `Call` - Call control and state management
- `Socket` - WebSocket communication layer
- `Peer` - WebRTC peer connection management

**Key Components:**
- **Config System**: `TxConfig` for authentication and configuration
- **Message Handling**: Verto protocol implementation for signaling
- **Push Notifications**: VoIP push notification handling with CallKit integration
- **Call Quality**: Real-time metrics collection
- **Logging**: Configurable logging system with custom logger support

### Demo App Architecture (`/TelnyxWebRTCDemo/`)

**State Management:**
- MVVM pattern with clear separation of concerns
- Delegate pattern for SDK events

**Push Notification System:**
- CallKit integration for native call UI
- PushKit for VoIP notifications
- Background/foreground state management

**Key Features:**
- CallKit integration
- Push notification handling
- Audio session management
- Call state handling
- Multiple credential support

### Platform-Specific Considerations

**iOS Requirements:**
- iOS 13.0+ deployment target
- CallKit integration for native call UI
- PushKit for VoIP notifications
- Required permissions in Info.plist:
  - Microphone usage
  - Background modes (Voice over IP, Audio, AirPlay, and Picture in Picture)
  - Push notifications

### WebRTC Flow
1. Authentication via `TxClient.connect()`
2. WebSocket connection established through `Socket`
3. SIP signaling via Verto protocol messages
4. WebRTC peer connection setup through `Peer` class
5. Media stream handling and call state management

### Configuration Files
- `TelnyxRTC.podspec` - Framework dependencies and configuration
- `Podfile` - Demo app dependencies (for both framework and iOS demo app)
- `Info.plist` - Required permissions and capabilities
- `PrivacyInfo.xcprivacy` - Privacy manifest for App Store

### iOS Version Requirements
- The demo app must be developed using SwiftUI
- All changes must maintain iOS 13.0+ compatibility
- Do not introduce changes that would require increasing the minimum supported iOS version
- Use SwiftUI features that are compatible with iOS 13.0+
- When using newer SwiftUI features, provide fallback implementations for iOS 13.0+ 

## Documentation Verification

Before submitting changes, it's crucial to verify and update relevant documentation. The following files should be reviewed and updated as needed:

### Main Documentation Files

1. **Error Handling**
   - `docs-markdown/error-handling/error-handling.md`
   - Update any new error codes or behaviors

2. **Push Notifications**
   - `docs-markdown/push-notification/app-setup.md`
   - `docs-markdown/push-notification/portal-setup.md`
   - `docs-markdown/push-notification/troubleshooting.md`
   - Verify configuration changes or new common issues

3. **WebRTC Stats**
   - `docs-markdown/webrtc-stats/webrtc-stats.md`
   - Update if there are new metrics or changes to existing ones

4. **Sample App**
   - `docs-markdown/sample-app/README.md`
   - Update setup and usage instructions

5. **Main Documentation**
   - `README.md`
   - Review and update general SDK documentation

### Verification Process

1. Review changes and their impact on documentation
2. Update relevant files with:
   - New features
   - API changes
   - New requirements
   - Common issue solutions
3. Verify code examples are up to date
4. Ensure documentation is clear and consistent


### Important Notes

- Maintain consistent tone throughout documentation
- Include practical examples when possible
- Document common use cases
- Keep documentation in English
- Verify correct Markdown formatting


#### Documentation Rules

1. **Public Functions**
   - Document all parameters
   - Specify return type
   - Document possible errors
   - Include usage examples when relevant

2. **Public Variables and Properties**
   - Describe purpose
   - Specify type
   - Document valid values or restrictions
   - Include usage examples if necessary

3. **Protocols and Classes**
   - Document general purpose
   - Describe main responsibilities
   - Include implementation examples

### Xcode Command Limitations

All Xcode-related commands and tests should be skipped if Claude is not running on a macOS system with Xcode installed. In such cases, proceed with the requested changes without executing any Xcode commands.

This includes skipping:
- Build commands
- Test executions
- Documentation generation
- Development tool commands
