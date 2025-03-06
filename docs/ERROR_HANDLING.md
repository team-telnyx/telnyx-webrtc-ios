# Error Handling in Telnyx WebRTC iOS SDK

This document describes the error handling mechanisms in the Telnyx WebRTC iOS SDK, specifically focusing on when and why the `onClientError` callback is triggered.

## Error Scenarios

### 1. Gateway Registration Status

The SDK monitors the gateway registration status and triggers an error in the following scenario:
- When the gateway status is not "REGED" (registered) after an initial attempt and retry
- Location: [TxClient.swift#L538](https://github.com/team-telnyx/telnyx-webrtc-ios/blob/main/TelnyxRTC/Telnyx/TxClient.swift#L538)
- This ensures that the client is properly connected to the Telnyx network

Example:
```swift
if gatewayState != "REGED" {
    // After retry attempt fails
    delegate?.onClientError(error: "Gateway registration failed")
}
```

### 2. WebSocket Error Messages

The SDK handles error messages received through the WebSocket connection:
- When the server sends an error message via WebSocket
- Location: [TxClient.swift#L933](https://github.com/team-telnyx/telnyx-webrtc-ios/blob/main/TelnyxRTC/Telnyx/TxClient.swift#L933)
- These errors typically indicate issues with the connection or server-side problems

Example:
```swift
// When receiving a WebSocket message
if message.type == "error" {
    delegate?.onClientError(error: message.error)
}
```

## Error Handling Best Practices

When implementing the `onClientError` delegate method in your application:

1. Log the error for debugging purposes
2. Implement appropriate error recovery mechanisms
3. Consider displaying user-friendly error messages
4. Implement reconnection logic if appropriate

Example Implementation:
```swift
extension YourClass: TxClientDelegate {
    func onClientError(error: String) {
        // Log the error
        print("Telnyx Client Error: \(error)")
        
        // Implement appropriate error handling
        if error.contains("Gateway registration failed") {
            // Handle gateway registration failure
            attemptReconnection()
        } else {
            // Handle other types of errors
            showErrorToUser(message: error)
        }
    }
}
```

## Common Error Scenarios and Solutions

1. Gateway Registration Failure
   - Cause: Network connectivity issues or invalid credentials
   - Solution: Check network connection and credential validity

2. WebSocket Connection Errors
   - Cause: Network interruption or server issues
   - Solution: Implement automatic reconnection with exponential backoff

## Additional Resources

- [Telnyx WebRTC iOS SDK GitHub Repository](https://github.com/team-telnyx/telnyx-webrtc-ios)
- [API Documentation](https://developers.telnyx.com/docs/v2/webrtc)