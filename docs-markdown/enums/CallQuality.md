**ENUM**

# `CallQuality`

```swift
public enum CallQuality: String
```

Quality rating for a WebRTC call based on MOS score

## Cases
### `excellent`

```swift
case excellent
```

MOS > 4.2

### `good`

```swift
case good
```

`4.1 <= MOS <= 4.2`

### `fair`

```swift
case fair
```

`3.7 <= MOS <= 4.0`

### `poor`

```swift
case poor
```

`3.1 <= MOS <= 3.6`

### `bad`

```swift
case bad
```

`MOS <= 3.0`

### `unknown`

```swift
case unknown
```

Unable to calculate quality
