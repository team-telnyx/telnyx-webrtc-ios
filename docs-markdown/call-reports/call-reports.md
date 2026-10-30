## Call Reports v1.0

The iOS SDK automatically collects call quality statistics and diagnostic information during calls to help troubleshoot issues and improve call quality.

### Overview

Call Reports automatically gather WebRTC statistics and call events during your calls. This information is sent to Telnyx servers when calls end, enabling our support team to diagnose issues and help improve your call experience.

**This feature is enabled by default** and works automatically without any configuration needed.

### What Information is Collected

The SDK collects:

- **Call quality metrics** - Audio quality indicators like jitter, packet loss, and bitrate
- **Connection statistics** - Network performance data including round-trip time
- **Call lifecycle events** - State changes and important milestones during the call
- **Call setup timings** - How long each setup step took, from peer creation through ICE, DTLS and answer, as `[CallTimings]` log lines in the same format as the JS and Android SDKs. The lines are added once the call is active and DTLS has connected, and are included whatever `callReportLogLevel` is set to.

All data is collected locally during the call and sent to Telnyx servers after the call ends. Calls that end before they become active, such as missed, rejected or failed calls, are reported with their logs only.

### Difference from WebRTC Statistics

The SDK provides two separate features for call monitoring:

| Feature | Purpose | Default State | Use Case |
|---------|---------|---------------|----------|
| **Call Reports v1.0** | Automatic post-call diagnostics | **Enabled** | Troubleshooting and quality analysis |
| **WebRTC Statistics** | Real-time stats streaming | Disabled | Live debugging during development |

- **Call Reports** collect data during calls and send it after calls end - designed for production use
- **WebRTC Statistics** (enabled via `debug: true`) stream real-time data during calls - designed for development

Both features can be used together or independently.

### Configuration (Optional)

Call Reports work automatically with default settings. Advanced users can customize the behavior:

```swift
let txConfig = TxConfig(
    sipUser: sipUser,
    password: password,
    enableCallReports: true,          // Enable/disable (default: true)
    callReportInterval: 5.0,          // Collection interval in seconds (default: 5.0)
    callReportLogLevel: "debug",      // Log detail level (default: "debug")
    callReportMaxLogEntries: 1000     // Max log entries (default: 1000)
)
```

**Default settings are recommended for most use cases.**

### Disabling Call Reports

If you need to disable automatic reporting (e.g., for privacy or bandwidth reasons):

```swift
let txConfig = TxConfig(
    sipUser: sipUser,
    password: password,
    enableCallReports: false  // Disable call reports
)
```

### Privacy & Data Usage

- Data is only collected during active calls
- Information is sent securely to Telnyx servers after calls end
- No personal conversation content is collected - only technical call quality metrics
- Minimal bandwidth impact (data sent after call completion)

### Troubleshooting Support

When contacting Telnyx support about call quality issues:

1. Ensure `enableCallReports: true` (default)
2. Provide your **call ID** or **timestamp** of the problematic call
3. Our support team will have access to the diagnostic data automatically

### Best Practices

1. **Leave enabled in production** - Call Reports are designed to be lightweight and help diagnose real-world issues
2. **Combine with Call Quality Metrics** - Use `enableQualityMetrics: true` for real-time user feedback during calls
3. **Use WebRTC Statistics for development** - Enable `debug: true` when actively troubleshooting during development

### Related Documentation

- [WebRTC Statistics](../webrtc-stats/webrtc-stats.md) - Real-time stats streaming for development
- [Call Quality Metrics](../structs/CallQualityMetrics.md) - Real-time quality monitoring
- [TxConfig](../structs/TxConfig.md) - SDK configuration options

---
