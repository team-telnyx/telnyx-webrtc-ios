# CHANGELOG

## [2.2.2](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/2.2.2) (2025-10-08)

### Features
- **Anonymous Login for AI-Agent**: Added support for anonymous authentication specifically designed for AI-Agent integration, allowing connections without traditional credentials

### Bug Fixes
- Fixed speaker restoration after ACM (AudioDeviceModule) buffer reset to maintain the previously selected audio route
- Fixed User-Agent header formatting and content

## [2.2.1](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/2.2.1) (2025-09-23)

### Bug Fixes
- Improve audio connection performance by removing unnecessary audio device resets during mute/unmute operations
- Maintain audio route change subscriptions throughout the client lifecycle instead of unsubscribing on disconnect

## [2.2.0](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/2.2.0) (2025-09-19)

### Features
- **ICE Renegotiation**: Enhanced ICE candidate renegotiation process to improve call quality during network fluctuations
- **ACM Buffer Reset**: Implemented automatic AudioDeviceModule (ACM) buffer reset mechanism based on RTT monitoring to reduce audio delay. The ACM buffer is automatically reset when RTT exceeds 1000ms. Requires `debug: true` and `enableQualityMetrics: true` flags in `TxConfig` to enable RTT monitoring and automatic buffer reset functionality
- **WebRTC Stats Control**: Added new `sendWebRTCStatsViaSocket` flag in `TxConfig` to control whether WebRTC statistics are sent via socket to Telnyx servers

## [2.1.0](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/2.1.0) (2025-07-31)

### Features
- SDK Region Selection

### Enhancements
- Improved reconnection logic for thread safety

## [2.0.2](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/2.0.2) (2025-05-26)

### Bug Fixes
- Improved call quality metrics for real-time monitoring of call quality metrics
- Fix cause codes for reject and normal clearing

## [2.0.1](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/2.0.1) (2025-05-26)

### Bug Fixes
- Fixed initialization of `reconnectTimeOut` parameter in `TxConfig` that was not being properly assigned during configuration

## [2.0.0](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/2.0.0) (2025-05-21)

### Features
- WEBRTC-2686: Expose Call Termination Reasons in SDK and Surface Error Messages

### Fixes
- Fix Ringback Tone for parked calls


## [1.2.3](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/1.2.3) (2025-05-02)

### Enhancements
- Implemented CallQuality metrics for real-time monitoring of call quality metrics including:
  - Jitter measurements
  - Packet loss statistics
  - Latency tracking
  - MOS (Mean Opinion Score) estimation
  
## [1.2.2](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/1.2.2) (2025-03-20)

### Enhancements
- Improved call reconnection process for better reliability during network changes
- Added configurable reconnection timeout for more control over network recovery

## [1.2.1](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/1.2.1) (2025-03-11)

### Bug Fixes
- Disabled WebRTC stats during socket reconnection process to improve call reconnection speed.

## [1.2.0](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/1.2.0) (2025-03-01)

### Enhacement
- **Custom Logs Support**: 
  - Added support for custom logs in the SDK. You can now pass a customLogger in TxConfig to handle SDK logs.
  - If no custom logger is provided, logs will be printed to the console based on the configured logLevel (.none by default).

### Reconnection Enhancements
- Improved call reconnection handling when switching networks (Wi-Fi / mobile data).
- New CallState: Introduced a new DROPPED state to better track when a call is lost due to network issues.

```Swift
/// `CallState` represents the state of the call
public enum CallState: Equatable {
    /// New call has been created in the client.
    case NEW
    /// The outbound call is being sent to the server.
    case CONNECTING
    /// Call is pending to be answered. Someone is attempting to call you.
    case RINGING
    /// Call is active when two clients are fully connected.
    case ACTIVE
    /// Call has been held.
    case HELD
    /// Call has ended.
    case DONE
    /// The active call is being recovered. Usually after a network switch or bad network
    case RECONNECTING(reason: Reason)
    /// The active call is dropped. Usually when the network is lost.
    case DROPPED(reason: Reason)

    /// Enum to represent reasons for reconnection or call drop.
    public enum Reason: String {
        case networkSwitch = "Network switched"
        case networkLost = "Network lost"
        case serverError = "Server error"
    }

    /// Helper function to get the reason for the state (if applicable).
    public func getReason() -> String? {
        switch self {
        case let .RECONNECTING(reason), let .DROPPED(reason):
            return reason.rawValue
        default:
            return nil
        }
    }
}

```

## [1.1.0](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/1.1.0) (2025-02-17)

### Bug Fixes
- Fix callstate sequence for outgoing and incoming calls
- Fix network switch for foreground calls

## [1.0.0](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/1.0.0) (2025-02-11)

### Enhacement
- Added forceRelayCandidate configuration:
    - Allows control over local network access on iOS.
    - When set to true, the connection will only use TURN servers, preventing local network candidate gathering and avoiding the permission popup.

- Enabled SDK support for simulators on Mac with M-series chips: Improved compatibility to allow testing the SDK on Apple Silicon simulators.

## [0.1.42](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/0.1.42) (2025-02-04)

### Bug Fixes
- Removed Bugsnag dependency

## [0.1.41](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/0.1.41) (2025-01-27)

### Bug Fixes
- Improved the CallKit speaker button behavior to ensure consistent functionality. The button now accurately reflects the current audio output state. Adjustments were made to the RTCAudioSession handling to resolve the issue.

## [0.1.40](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/0.1.40) (2025-01-22)

### Bug Fixes
- Fix build on SPM: Added Foundation imports.

## [0.1.39](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/0.1.39) (2025-01-10)

### Enhacement
- Enable/Disable WebRTC Statistics: You can now toggle WebRTC Statistics. When enabled, all WebRTC stats are uploaded to our servers. These statistics can be accessed via the Telnyx Portal under the Object Storage section associated with the account used to generate the credentials for the SDK login.


## [0.1.38](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/0.1.38) (2024-11-13)

### Bug Fixes
- Prevent adding ICE candidates after negotiation ends or connection is established


## [0.1.37](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/0.1.37) (2024-10-29)

### Bug Fixes

- Enhanced WebSocket and RTC peer reconnection logic to ensure seamless recovery during network disconnections or switches.


## [0.1.36](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/0.1.36) (2024-10-17)

### Bug Fixes

- Resolved a race condition affecting the handling of early "Bye" messages.


## [0.1.35](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/0.1.35) (2024-09-19)

### Bug Fixes

- Privacy Manifest improvements


## [0.1.34](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/0.1.34) (2024-09-04)

### Enhancement

- WebRTC Debug Report: upload debug data.

### Bug Fixes

- Reconnect when network disconnect
- Generic Client Error Fix for Attach Call Method : If attach_call call fails the sdk invokes the remoteCallEnded(..) method to identify and end the call



## [0.1.33](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/0.1.33) (2024-08-28)

### Enhancement

- WebRTC Debug Report: added timestamp and data type.


## [0.1.31](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/0.1.31) (2024-07-24)

### Feature

- WebRTC Debug Report: Collect debug statistics


## [0.1.30](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/0.1.30) (2024-07-24)

### Bug Fixing

- Fix Package.Swift file to support Swift Package Manager.


## [0.1.29](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/0.1.29) (2024-06-26)

### Bug Fixing

- Updated sdpSemantics to use `unifiedPlan`
- Fix WebRTC Audio Session


## [0.1.28](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/0.1.28) (2024-05-14)

### Bug Fixing

- Privacy Manifest improvements


## [0.1.28](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/0.1.27) (2024-05-09)

### Bug Fixing

- Added Privacy Manifest
