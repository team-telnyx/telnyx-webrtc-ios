**ENUM**

# `TxError.CallFailureReason`

```swift
public enum CallFailureReason
```

The underlying reason of the call errors

## Cases
### `destinationNumberIsRequired`

```swift
case destinationNumberIsRequired
```

There's no destination number when placing an outbound call

### `sessionIdIsRequired`

```swift
case sessionIdIsRequired
```

Session Id is missing when starting a call. Check you're logged in before starting a call.
