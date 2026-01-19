# Trickle ICE

The Telnyx iOS WebRTC SDK supports Trickle ICE (Interactive Connectivity Establishment), a technique that allows ICE candidates to be sent incrementally as they are discovered, rather than waiting for all candidates to be gathered before sending the session description.

## Overview

Trickle ICE provides several benefits:

- **Faster Call Setup**: ICE candidates are sent immediately as they're discovered, reducing the time to establish media connections
- **Improved User Experience**: Calls connect more quickly, especially on networks where TURN relay candidates take time to gather
- **Better Network Resilience**: Candidates continue to be sent even if some fail to gather, improving connection reliability

## How Trickle ICE Works

### Standard ICE Flow (Without Trickle)

1. Local peer generates all ICE candidates (host, server reflexive, relay)
2. Wait for all candidates to be gathered
3. Send complete SDP with all candidates included
4. Remote peer processes all candidates at once

### Trickle ICE Flow

1. Local peer sends initial SDP **without** ICE candidates
2. As each ICE candidate is discovered, send it immediately via signaling
3. Remote peer processes candidates incrementally as they arrive
4. Send "end-of-candidates" signal when gathering completes

## Implementation in iOS SDK

The iOS SDK implements Trickle ICE with special handling for different call scenarios:

### Outbound Calls (Calling Side)

For outbound calls, candidates are sent immediately as they are discovered:

```
1. Call initiated → OFFER sent without candidates
2. Host candidates discovered → Sent immediately
3. Server reflexive candidates → Sent immediately
4. TURN relay candidates → Sent immediately
5. ICE gathering complete → "end-of-candidates" sent
```

### Inbound Calls (Answering Side)

For inbound calls, candidates are queued until the ANSWER is sent to prevent race conditions:

```
1. INVITE received → Peer created
2. Candidates discovered → Queued (not sent yet)
3. User answers call → ANSWER sent
4. Queued candidates → Flushed and sent immediately
5. New candidates → Sent immediately as discovered
6. ICE gathering complete → "end-of-candidates" sent
```

**Why queue candidates on answering side?**

Queuing candidates until the ANSWER is sent prevents a race condition where ICE candidates arrive at the server before the ANSWER message. Some servers may reject or discard candidates that arrive before the answer, causing connection failures.

## Configuration

Trickle ICE is automatically managed by the SDK and requires no explicit configuration. The SDK intelligently handles candidate sending based on call direction and state.

## Candidate Processing

### Candidate Cleaning

Before sending, ICE candidate strings are cleaned to remove WebRTC-specific extensions that may not be compatible with all servers:

**Standard Fields (Kept)**:
- Foundation, component, transport, priority
- IP address, port
- Candidate type (host, srflx, relay)
- Related address/port (for relay candidates)

**WebRTC Extensions (Removed)**:
- network-id
- generation
- ufrag
- network-cost

This ensures maximum compatibility with Telnyx servers and other SIP endpoints.

## Timing and Timeouts

The SDK uses a **3-second timeout** to detect when ICE candidate gathering has completed. This timer:

- Starts when the first candidate is sent
- Resets each time a new candidate is sent
- Triggers "end-of-candidates" when no new candidates arrive for 3 seconds

This timeout provides sufficient time for TURN relay candidates to be discovered, even on slower networks.

## ICE Gathering States

The SDK monitors WebRTC ICE gathering states:

- `new`: Initial state
- `gathering`: ICE candidates are being discovered
- `complete`: All candidates have been gathered

When `complete` state is reached, the SDK immediately sends the "end-of-candidates" signal, overriding the 3-second timer.

## Signaling Messages

### Trickle Candidate Message

Individual candidates are sent using the Verto `verto.trickle` method:

```json
{
  "jsonrpc": "2.0",
  "method": "verto.trickle",
  "params": {
    "callId": "uuid",
    "sessionId": "session-id",
    "candidate": "candidate:... (cleaned)",
    "sdpMid": "audio",
    "sdpMLineIndex": 0
  }
}
```

### End of Candidates Message

When gathering completes, an end-of-candidates signal is sent:

```json
{
  "jsonrpc": "2.0",
  "method": "verto.trickle",
  "params": {
    "callId": "uuid",
    "sessionId": "session-id",
    "candidate": null
  }
}
```

## Best Practices

1. **No Manual Configuration Required**: The SDK handles Trickle ICE automatically based on server capabilities

2. **CallKit Integration**: Ensure proper CallKit integration to handle the answering flow correctly, allowing the SDK to flush queued candidates at the right time

3. **Network Changes**: The SDK continues to gather and send new candidates if network conditions change during a call (continual gathering)

4. **Logging**: Enable detailed logging to troubleshoot ICE-related issues:
   ```swift
   let config = TxConfig(
       sipUser: sipUser,
       password: password,
       logLevel: .all
   )
   ```

5. **Push Notifications**: When answering from push notifications, use `answerFromCallkit()` to ensure proper candidate queuing and flushing

## Troubleshooting

### Candidates Not Being Sent

If candidates aren't being sent during a call:

1. Check that the WebSocket connection is established
2. Verify `sessionId` and `callId` are set correctly
3. Enable `.all` logging to see candidate generation logs
4. Look for `[TRICKLE-ICE]` prefixed log messages

### Remote Audio Issues

If remote audio is not heard:

1. Verify candidates are being sent (check logs for "Sent trickle candidate")
2. Check that answering side queued and flushed candidates after ANSWER
3. Ensure "end-of-candidates" was sent
4. Verify remote peer is also sending candidates

### Call Setup Delays

If calls take too long to connect:

1. Check if TURN relay candidates are timing out
2. Verify firewall settings allow UDP/TCP connections to TURN servers
3. Consider network latency - TURN candidates require server round-trip time
4. Check logs for ICE gathering completion time

## Technical Implementation Details

### Key Classes

- **Peer.swift**: Manages ICE candidate generation, queuing, and sending
- **SdpUtils.swift**: Handles candidate string cleaning
- **Call.swift**: Coordinates candidate flushing after ANSWER
- **CandidateMessage**: Verto message structure for trickle candidates

### Thread Safety

All candidate operations are performed on the appropriate WebRTC threads:
- Candidate generation callbacks come from WebRTC internal threads
- Signaling messages are sent via the socket's dispatch queue
- State changes are synchronized to prevent race conditions

### Memory Management

- Queued candidates are stored temporarily until ANSWER is sent
- Queue is cleared after flushing or when call ends
- Timers are invalidated when calls terminate

## Related Documentation

- [TxClient Configuration](../extensions/TxClient.md)
- [Call Management](../extensions/Call.md)
- [WebRTC Statistics](../extensions/WebRTCStatsReporter.md)
