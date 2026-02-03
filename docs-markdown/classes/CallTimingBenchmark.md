**CLASS**

# `CallTimingBenchmark`

```swift
public class CallTimingBenchmark
```

Helper class to track timing benchmarks during call connection.
Used to identify performance bottlenecks in the call setup process.
All benchmarks are collected and logged together when the call connects.
Thread-safe singleton implementation that tracks call connection milestones.

## Methods
### `start(isOutbound:)`

```swift
public static func start(isOutbound: Bool = false)
```

Starts the benchmark timer.
- Parameter isOutbound: indicates if this is an outbound call (true) or inbound (false).

#### Parameters

| Name | Description |
| ---- | ----------- |
| isOutbound | indicates if this is an outbound call (true) or inbound (false). |

### `mark(_:)`

```swift
public static func mark(_ milestone: String)
```

Records a milestone with the current elapsed time.
- Parameter milestone: The name of the milestone to record

#### Parameters

| Name | Description |
| ---- | ----------- |
| milestone | The name of the milestone to record |

### `markFirstCandidate()`

```swift
public static func markFirstCandidate()
```

Records the first ICE candidate (only once per call).

### `end()`

```swift
public static func end()
```

Ends the benchmark and logs a formatted summary of all milestones.

### `reset()`

```swift
public static func reset()
```

Resets the benchmark state for the next call.

### `isRunning()`

```swift
public static func isRunning() -> Bool
```

Checks if a benchmark is currently active.
- Returns: true if benchmarking is currently running, false otherwise
