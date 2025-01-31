**EXTENSION**

# `WebRTCStatsReporter`
```swift
extension WebRTCStatsReporter
```

## Methods
### `dispose()`

```swift
public func dispose()
```

### `setupEventHandler()`

```swift
public func setupEventHandler()
```

Sets up handlers for various WebRTC events to collect debugging information.
This method configures callbacks for:
- Media stream and track events
- ICE candidate gathering and selection
- Signaling state changes
- Connection state changes
- ICE gathering state changes
- Negotiation events

Each event handler collects relevant data and sends it to Telnyx's servers
for analysis and debugging purposes.
