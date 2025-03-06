# Error Handling in Telnyx iOS SDK

This document outlines the error handling mechanisms in the Telnyx iOS SDK, specifically focusing on when and why the `onClientError` callback is triggered.

## Error Scenarios

### 1. Gateway Registration Status

The SDK monitors the gateway registration status and triggers an error in the following scenario:

- When the gateway status is not "REGED" (registered) after a retry attempt
- Location: [TxClient.swift#L538](https://github.com/team-telnyx/telnyx-webrtc-ios/blob/main/TelnyxRTC/Telnyx/TxClient.swift#L538)
- This ensures that the client is properly connected to the Telnyx network

Example scenario:
```swift
if gatewayStatus != "REGED" {
    // After retry attempt fails
    delegate?.onClientError(error: TxError.gatewayError)
}
```

### 2. WebSocket Error Messages

The SDK processes error messages received through the WebSocket connection:

- When the server sends an error message via WebSocket
- Location: [TxClient.swift#L933](https://github.com/team-telnyx/telnyx-webrtc-ios/blob/main/TelnyxRTC/Telnyx/TxClient.swift#L933)
- These errors typically indicate server-side issues or invalid requests

Example scenario:
```swift
// When receiving a WebSocket message with an error
delegate?.onClientError(error: TxError.websocketError(message: errorMessage))
```

## Error Types

The SDK uses the `TxError` enum to categorize different types of errors that can occur:

1. Gateway Errors:
   - Registration failures
   - Connection issues
   - Authentication problems

2. WebSocket Errors:
   - Connection drops
   - Invalid messages
   - Server-side errors

## Best Practices

When implementing error handling in your application:

1. Always implement the `onClientError` delegate method
2. Handle both gateway and WebSocket errors appropriately
3. Consider implementing retry logic for transient errors
4. Log errors for debugging purposes

## Example Implementation

```swift
extension YourClass: TxClientDelegate {
    func onClientError(error: TxError) {
        switch error {
        case .gatewayError:
            // Handle gateway registration issues
            print("Gateway error occurred")
            // Implement retry logic if needed
            
        case .websocketError(let message):
            // Handle WebSocket-related errors
            print("WebSocket error: \(message)")
            // Take appropriate action based on the error message
            
        default:
            // Handle other error types
            print("Other error occurred: \(error)")
        }
    }
}
```

## Error Recovery

1. Gateway Registration Errors:
   - Check network connectivity
   - Verify credentials
   - Attempt re-registration after a delay

2. WebSocket Errors:
   - Check connection status
   - Attempt to reconnect if disconnected
   - Validate message format if sending data

## Additional Resources

- [Telnyx iOS SDK Documentation](https://developers.telnyx.com/docs/v2/webrtc/ios)
- [WebRTC Troubleshooting Guide](https://developers.telnyx.com/docs/v2/webrtc/troubleshooting)