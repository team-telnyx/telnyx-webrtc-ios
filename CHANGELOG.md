# CHANGELOG

## [0.1.42](https://github.com/team-telnyx/telnyx-webrtc-ios/releases/tag/0.1.42) (2025-01-04)

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
