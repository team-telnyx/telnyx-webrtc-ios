## WebRTC Statistics

The SDK provides WebRTC statistics functionality to assist with troubleshooting and monitoring call quality. This feature is controlled through the `debug` flag in the `TxClient` configuration.

### Enabling WebRTC Statistics

To enable WebRTC statistics logging:

```Swift
let txConfig = TxConfig(sipUser: sipUser,
                       password: password,
                       pushDeviceToken: "DEVICE_APNS_TOKEN",
                       debug: true) // Enable WebRTC statistics
```

### Understanding WebRTC Statistics

When `debug: true` is configured:
- WebRTC statistics logs are automatically collected during calls
- Logs are sent to the Telnyx portal and are accessible in the Object Storage section
- Statistics are linked to the SIP credential used for testing
- The logs help the Telnyx support team diagnose issues and optimize call quality
- All statistics are presented in the Telnyx portal under the Object Storage section


### Real-time Call Quality Monitoring

The SDK provides real-time call quality metrics through the `onCallQualityChange` callback on the `Call` object. This allows you to monitor call quality in real-time and provide feedback to users.

#### Using onCallQualityChanged

```Swift
// When creating a new call set debug to true for CallQualityMetrics
let call = try telnyxClient.newCall(callerName: "Caller name",
                                   callerNumber: "155531234567",
                                   destinationNumber: "18004377950",
                                   callId: UUID.init(),
                                   debug:true) // Enable Call Quality 
                                   
//When accepting a call
telnyxClient?.answerFromCallkit(answerAction: action,
                                debug:true)  // Enable Call Quality

or 

call?.answer(debug:true) // Enable Call Quality

// Set the onCallQualityChange callback
call.onCallQualityChange = { metrics in
    // Handle call quality metrics
    print("Call quality: \(metrics.quality.rawValue)")
    print("MOS score: \(metrics.mos)")
    print("Jitter: \(metrics.jitter * 1000) ms")
    print("Round-trip time: \(metrics.rtt * 1000) ms")
    
    // Update UI based on call quality
    switch metrics.quality {
    case .excellent, .good:
        // Show excellent/good quality indicator
        self.qualityIndicator.backgroundColor = .green
    case .fair:
        // Show fair quality indicator
        self.qualityIndicator.backgroundColor = .yellow
    case .poor, .bad:
        // Show poor/bad quality indicator
        self.qualityIndicator.backgroundColor = .red
        // Optionally show a message to the user
    case .unknown:
        // Quality couldn't be determined
        self.qualityIndicator.backgroundColor = .gray
    }
}
```

#### CallQualityMetrics Properties

The `CallQualityMetrics` object provides the following properties:

| Property | Type | Description |
|----------|------|-------------|
| `jitter` | Double | Jitter in seconds (multiply by 1000 for milliseconds) |
| `rtt` | Double | Round-trip time in seconds (multiply by 1000 for milliseconds) |
| `mos` | Double | Mean Opinion Score (1.0-5.0) |
| `quality` | CallQuality | Call quality rating based on MOS |
| `inboundAudio` | [String: Any]? | Inbound audio statistics |
| `outboundAudio` | [String: Any]? | Outbound audio statistics |
| `remoteInboundAudio` | [String: Any]? | Remote inbound audio statistics |
| `remoteOutboundAudio` | [String: Any]? | Remote outbound audio statistics |

#### CallQuality Enum

The `CallQuality` enum provides the following values:

| Value | MOS Range | Description |
|-------|-----------|-------------|
| `.excellent` | `MOS > 4.2` | Excellent call quality |
| `.good` | `4.1 <= MOS <= 4.2` | Good call quality |
| `.fair` | `3.7 <= MOS <= 4.0` | Fair call quality |
| `.poor` | `3.1 <= MOS <= 3.6` | Poor call quality |
| `.bad` | `MOS <= 3.0` | Bad call quality |
| `.unknown` | N/A | Unable to calculate quality |

#### Best Practices for Call Quality Monitoring

1. **User Feedback**:
    - Consider showing a visual indicator of call quality to users
    - For poor quality calls, provide suggestions (e.g., "Try moving to an area with better connectivity")

2. **Logging**:
    - Log quality metrics for later analysis
    - Track quality trends over time to identify patterns

3. **Adaptive Behavior**:
    - Implement adaptive behaviors based on call quality
    - For example, suggest switching to audio-only if video quality is poor

4. **Performance Considerations**:
    - The callback is triggered periodically (approximately every 2 seconds)

### Important Notes

1. **Log Access**:
    - If you run the app using SIP credential A with `debug: true`, the WebRTC logs will be available in the Telnyx portal account associated with credential A
    - Logs are stored in the Object Storage section of your Telnyx portal

2. **Troubleshooting Support**:
    - WebRTC statistics are primarily intended to assist the Telnyx support team
    - When requesting support, enable `debug: true` in `TxClient` for all instances
    - Provide the `debug ID` or `callId` when contacting support
    - Statistics logging is disabled by default to optimize performance

3. **Best Practices**:
    - Enable `debug: true` only when troubleshooting is needed
    - Remember to provide the `debug ID` or `callId` in support requests
    - Consider disabling debug mode in production unless actively investigating issues

---
<br />
