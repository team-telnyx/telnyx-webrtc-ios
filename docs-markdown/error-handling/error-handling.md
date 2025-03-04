# Error Handling in Telnyx WebRTC iOS SDK

This document provides a comprehensive overview of error handling in the Telnyx WebRTC iOS SDK, including when the `onClientError` callback is triggered, the types of errors that can occur, and how the SDK handles reconnection attempts.

## Table of Contents

1. [Introduction](#introduction)
2. [The `onClientError` Callback](#the-onclienterror-callback)
3. [Error Types](#error-types)
   - [Server Errors](#server-errors)
   - [Local Errors](#local-errors)
   - [Socket Connection Errors](#socket-connection-errors)
4. [Reconnection Process](#reconnection-process)
5. [Best Practices](#best-practices)

## Introduction

The Telnyx WebRTC iOS SDK provides robust error handling mechanisms to help developers manage various error scenarios that may occur during the lifecycle of a WebRTC connection. Understanding these error handling mechanisms is crucial for building reliable applications that can gracefully recover from failures.

## The `onClientError` Callback

The `onClientError` callback is part of the `TxClientDelegate` protocol and is triggered when an error occurs in the SDK. This callback provides a way for your application to be notified of errors and take appropriate action.

```swift
func onClientError(error: Error)
```

### When is `onClientError` Called?

The `onClientError` callback is triggered in the following scenarios:

1. **Gateway Registration Failure**: When the client fails to register with the Telnyx gateway after multiple retry attempts.
   - Error Type: `TxError.serverError(reason: .gatewayNotRegistered)`

2. **Server Error Messages**: When the server sends an error message through the WebSocket connection.
   - Error Type: `TxError.serverError(reason: .signalingServerError(message: String, code: String))`

3. **Socket Connection Errors**: When there are issues with the WebSocket connection.
   - These errors are propagated through the Socket class to the TxClient.

## Error Types

The SDK uses the `TxError` enum to represent different types of errors that can occur. Understanding these error types can help you handle specific error scenarios appropriately.

### Server Errors

Server errors are represented by the `TxError.serverError` case with a `ServerErrorReason` enum:

```swift
public enum ServerErrorReason {
    /// Any server signaling error. We get the message and code from the server
    case signalingServerError(message: String, code: String)
    /// Gateway is not registered.
    case gatewayNotRegistered
}
```

#### Signaling Server Errors

These errors occur when the Telnyx signaling server returns an error response. The error includes:
- A message describing the error
- An error code

Common signaling server errors include authentication failures, invalid requests, and service unavailability.

#### Gateway Not Registered Errors

This error occurs when the client fails to register with the Telnyx gateway after multiple retry attempts (default: 3 attempts). This can happen due to:
- Network connectivity issues
- Invalid credentials
- Server-side issues

### Local Errors

Local errors are errors that occur within the SDK itself, not directly related to server communication:

1. **Client Configuration Errors** (`TxError.clientConfigurationFailed`):
   - Missing username/password when using credential-based authentication
   - Missing token when using token-based authentication
   - Missing required configuration parameters

2. **Call Errors** (`TxError.callFailed`):
   - Missing destination number when placing an outbound call
   - Missing session ID when starting a call (indicates the client is not properly connected)

### Socket Connection Errors

Socket connection errors are represented by the `TxError.socketConnectionFailed` case with a `SocketFailureReason` enum:

```swift
public enum SocketFailureReason {
    /// Socket is not connected. Check that you have an active connection.
    case socketNotConnected
    /// Socket connection was cancelled.
    case socketCancelled(nativeError: Error)
}
```

These errors occur when:
- The WebSocket connection cannot be established
- The connection is interrupted or closed unexpectedly
- The connection attempt is cancelled

## Reconnection Process

The SDK includes an automatic reconnection mechanism to handle temporary network issues:

1. **Gateway Registration Retry**:
   - When the gateway state check fails, the SDK will retry up to 3 times (configurable via `MAX_REGISTER_RETRY`)
   - Each retry occurs after a fixed interval (default: 3 seconds, set by `DEFAULT_REGISTER_INTERVAL`)
   - If all retries fail, an `onClientError` with `gatewayNotRegistered` reason is triggered

2. **Network Monitoring**:
   - The SDK includes a `NetworkMonitor` class that continuously monitors network connectivity
   - When network state changes (e.g., from no connection to WiFi), the SDK attempts to reconnect automatically
   - Network state changes are handled in the `onNetworkStateChange` callback

3. **Call Reconnection**:
   - When network connectivity is lost during an active call, the call state is updated to `DROPPED` with a `networkLost` reason
   - When connectivity is restored, the SDK attempts to reconnect the client

## Best Practices

To effectively handle errors in your application:

1. **Always implement the `onClientError` callback** in your `TxClientDelegate`:
   ```swift
   func onClientError(error: Error) {
       if let txError = error as? TxError {
           switch txError {
           case .serverError(let reason):
               // Handle server errors
               switch reason {
               case .gatewayNotRegistered:
                   // Handle gateway registration failure
               case .signalingServerError(let message, let code):
                   // Handle signaling server errors
               }
           case .socketConnectionFailed(let reason):
               // Handle socket connection failures
           case .clientConfigurationFailed(let reason):
               // Handle configuration errors
           case .callFailed(let reason):
               // Handle call-specific errors
           }
       }
       
       // Update UI or take appropriate action
   }
   ```

2. **Understand the difference between socket connection and client registration**:
   - **Socket Connection**: Represents the WebSocket connection to the Telnyx server
     - Managed through `onSocketConnected()` and `onSocketDisconnected()` callbacks
     - Only indicates that a network connection to the server exists
     - A connected socket does NOT mean the client is ready to make/receive calls
   
   - **Client Registration (Gateway State)**: Represents the SIP registration state
     - Managed through the `onClientReady()` callback
     - Only when this callback is triggered is the client fully registered and ready
     - The client must be in the `REGED` state to make/receive calls
     - Registration happens automatically after socket connection is established

3. **Handle the registration retry process**:
   - The SDK automatically attempts to register with the gateway up to 3 times (configurable via `MAX_REGISTER_RETRY`)
   - Each retry occurs after a fixed interval (default: 3 seconds)
   - If all retries fail, an `onClientError` with `gatewayNotRegistered` reason is triggered
   - Example implementation:
     ```swift
     func onClientError(error: Error) {
         if let txError = error as? TxError,
            case .serverError(let reason) = txError,
            case .gatewayNotRegistered = reason {
             
             // Registration failed after multiple attempts
             showRegistrationFailureUI()
             
             // You might want to implement your own retry logic here
             DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                 // Attempt to reconnect after 5 seconds
                 try? client.connect(txConfig: yourTxConfig)
             }
         }
     }
     ```

4. **Handle call reconnection during network changes**:
   - The SDK includes network state monitoring that detects:
     - Network type changes (WiFi to cellular, etc.)
     - Airplane mode toggling
     - Network loss and recovery
   
   - **Call States During Reconnection**:
     - When network is lost during a call, the call state changes to `DROPPED` with reason `.networkLost`
     - During reconnection attempts, the call state changes to `RECONNECTING` with reason `.networkSwitch`
     - Your UI should reflect these states to keep users informed
     - Example implementation:
       ```swift
       func onCallStateUpdated(callState: CallState, callId: UUID) {
           switch callState {
           case .RECONNECTING(let reason):
               if reason == .networkSwitch {
                   // Show reconnecting UI
                   showReconnectingIndicator()
               }
           case .DROPPED(let reason):
               if reason == .networkLost {
                   // Show network lost UI
                   showNetworkLostIndicator()
               }
           case .ACTIVE:
               // Call is active again after reconnection
               hideReconnectingIndicator()
           default:
               break
           }
       }
       ```

5. **Monitor socket and client states together**:
   - A client can be disconnected from the socket but still in an ongoing call reconnection process
   - Always check both the socket connection state and call states when making UI decisions
   - Example implementation:
     ```swift
     func onSocketDisconnected() {
         // Only show disconnected UI if there are no active calls in reconnection
         if !hasActiveCallsInReconnection() {
             showDisconnectedUI()
         } else {
             showReconnectingUI()
         }
     }
     
     private func hasActiveCallsInReconnection() -> Bool {
         // Check if any calls are in RECONNECTING state
         return client.calls.values.contains { call in
             if case .RECONNECTING = call.callState {
                 return true
             }
             return false
         }
     }
     ```

6. **Log errors** for debugging purposes:
   - Use the error information provided in the callbacks to log detailed error information
   - Include error codes and messages in your logs to help with troubleshooting
