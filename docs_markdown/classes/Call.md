**CLASS**

# `Call`

```swift
public class Call
```

A Call is the representation of an audio or video call between two WebRTC Clients, SIP clients or phone numbers.
The call object is created whenever a new call is initiated, either by you or the remote caller.
You can access and act upon calls initiated by a remote caller by registering to TxClientDelegate of the TxClient

## Examples:
### Create a call:

```
   // Create a client instance
   self.telnyxClient = TxClient()

   // Asign the delegate to get SDK events
   self.telnyxClient?.delegate = self

   // Connect the client (Check TxClient class for more info)
   self.telnyxClient?.connect(....)

   // Create the call and start calling
   self.currentCall = try self.telnyxClient?.newCall(callerName: "Caller name",
                                                     callerNumber: "155531234567",
                                                     // Destination is required and can be a phone number or SIP URI
                                                     destinationNumber: "18004377950",
                                                     callId: UUID.init())
```

### Answer an incoming call:
```
//Init your client
func initTelnyxClient() {
   //
   self.telnyxClient = TxClient()

   // Asign the delegate to get SDK events
   self.telnyxClient?.delegate = self

   // Connect the client (Check TxClient class for more info)
   self.telnyxClient?.connect(....)
}

extension ViewController: TxClientDelegate {
    //....
    func onIncomingCall(call: Call) {
        //We are automatically answering any incoming call as an example, but
        //maybe you want to store a reference of the call, and answer the call after a button press.
        self.myCall = call.answer()
    }
}
```

## Properties
### `inviteCustomHeaders`

```swift
public internal(set) var inviteCustomHeaders: [String:String]?
```

Custum headers pased /from webrtc telnyx_rtc.INVITE Messages

### `answerCustomHeaders`

```swift
public internal(set) var answerCustomHeaders: [String:String]?
```

Custum headers pased tfrom telnyx_rtc.ANSWER webrtcMessages

### `sessionId`

```swift
public internal(set) var sessionId: String?
```

The Session ID of the current connection

### `telnyxSessionId`

```swift
public internal(set) var telnyxSessionId: UUID?
```

Telnyx call session ID.

### `telnyxLegId`

```swift
public internal(set) var telnyxLegId: UUID?
```

Telnyx call leg ID

### `callInfo`

```swift
public var callInfo: TxCallInfo?
```

`TxCallInfo` Contains the required information of the current Call.

### `callState`

```swift
public var callState: CallState = .NEW
```

`CallState` The actual state of the Call.

## Methods
### `startDebugStats()`

```swift
public func startDebugStats()
```
