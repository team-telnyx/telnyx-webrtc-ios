**STRUCT**

# `WidgetSettings`

```swift
public struct WidgetSettings
```

Represents widget settings for AI assistant interface

## Properties
### `theme`

```swift
public let theme: String?
```

### `language`

```swift
public let language: String?
```

### `autoStart`

```swift
public let autoStart: Bool
```

### `showTranscript`

```swift
public let showTranscript: Bool
```

### `customStyles`

```swift
public let customStyles: [String: Any]?
```

### `agentThinkingText`

```swift
public let agentThinkingText: String
```

### `audioVisualizerConfig`

```swift
public let audioVisualizerConfig: AudioVisualizerConfig?
```

### `defaultState`

```swift
public let defaultState: String
```

### `giveFeedbackUrl`

```swift
public let giveFeedbackUrl: String?
```

### `logoIconUrl`

```swift
public let logoIconUrl: String?
```

### `position`

```swift
public let position: String
```

### `reportIssueUrl`

```swift
public let reportIssueUrl: String?
```

### `speakToInterruptText`

```swift
public let speakToInterruptText: String
```

### `startCallText`

```swift
public let startCallText: String
```

### `viewHistoryUrl`

```swift
public let viewHistoryUrl: String?
```

## Methods
### `init(theme:language:autoStart:showTranscript:customStyles:agentThinkingText:audioVisualizerConfig:defaultState:giveFeedbackUrl:logoIconUrl:position:reportIssueUrl:speakToInterruptText:startCallText:viewHistoryUrl:)`

```swift
public init(
    theme: String? = "dark",
    language: String? = nil,
    autoStart: Bool = false,
    showTranscript: Bool = true,
    customStyles: [String: Any]? = nil,
    agentThinkingText: String = "",
    audioVisualizerConfig: AudioVisualizerConfig? = nil,
    defaultState: String = "collapsed",
    giveFeedbackUrl: String? = nil,
    logoIconUrl: String? = nil,
    position: String = "fixed",
    reportIssueUrl: String? = nil,
    speakToInterruptText: String = "",
    startCallText: String = "",
    viewHistoryUrl: String? = nil
)
```
