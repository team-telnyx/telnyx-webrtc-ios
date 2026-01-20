# WEBRTC-2822: Audio Wave UI for Mobile Client Implementation

## Overview
This implementation adds audio waveform visualization capabilities to the Telnyx WebRTC iOS SDK, following the pattern established in the JavaScript SDK.

## Changes Made

### 1. Call.swift - Added Stream Properties
- Added `localStream` property that returns the local media stream from the peer
- Added `remoteStream` property that returns the remote media stream from the peer
- Both properties are computed properties that delegate to the underlying Peer object
- Added comprehensive documentation with usage examples

### 2. Peer.swift - Stream Management
- Added private `_localStream` and `_remoteStream` properties to store media streams
- Added public `localStream` and `remoteStream` computed properties for external access
- Modified `createMediaSenders()` to create and populate the local media stream
- Modified `didAdd stream` callback to assign the remote stream
- Modified `didRemove stream` callback to clear the remote stream reference

### 3. AudioWaveformView.swift - UI Component
- Created a new SwiftUI component for real-time audio waveform visualization
- Supports both local and remote stream visualization
- Customizable bar count, colors, and dimensions
- Includes simulated visualization for demonstration purposes
- Provides foundation for future real audio processing integration

### 4. CallView.swift - UI Integration
- Integrated AudioWaveformView into the calling interface
- Added separate visualizations for local (green) and remote (blue) audio
- Positioned the waveforms prominently in the call interface

### 5. CallViewModel.swift - Data Binding
- Added `currentCall` property to provide access to the Call object
- Enables the UI to access localStream and remoteStream properties

### 6. HomeViewController.swift - State Management
- Updated to set the `currentCall` property in the CallViewModel
- Ensures the UI has access to the current call's media streams

## API Usage

### Accessing Media Streams
```swift
// Access local audio stream
if let localStream = call.localStream {
    let audioTracks = localStream.audioTracks
    // Use for audio processing/visualization
}

// Access remote audio stream
if let remoteStream = call.remoteStream {
    let audioTracks = remoteStream.audioTracks
    // Use for audio processing/visualization
}
```

### Using AudioWaveformView
```swift
// Local audio visualization
AudioWaveformView(
    mediaStream: call.localStream,
    barColor: .green,
    title: "Local Audio"
)

// Remote audio visualization
AudioWaveformView(
    mediaStream: call.remoteStream,
    barColor: .blue,
    title: "Remote Audio"
)
```

## Implementation Notes

### Current Limitations
1. **Simulated Visualization**: The current implementation uses simulated audio levels for demonstration. Real audio processing would require:
   - Audio data extraction from RTCAudioTrack
   - FFT or similar audio analysis
   - Real-time audio level calculation

2. **Video Tracks**: While the infrastructure supports video tracks, the current implementation focuses on audio streams.

### Future Enhancements
1. **Real Audio Processing**: Integrate with AVAudioEngine or similar for actual audio level detection
2. **Performance Optimization**: Optimize for real-time audio processing
3. **Additional Visualizations**: Support for different visualization types (spectrum, oscilloscope, etc.)
4. **Video Stream Support**: Extend to support video stream visualization

## Testing
The implementation can be tested by:
1. Making a call using the demo app
2. Observing the waveform visualizations in the call interface
3. Verifying that both local and remote waveforms are displayed
4. Confirming that the streams are properly accessible via the Call object

## Compatibility
- Follows the same pattern as the JavaScript SDK
- Maintains backward compatibility with existing Call API
- Uses standard WebRTC media stream objects
- Compatible with existing audio/video functionality