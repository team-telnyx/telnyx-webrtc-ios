**ENUM**

# `TxError.ClientConfigurationFailureReason`

```swift
public enum ClientConfigurationFailureReason
```

The underlying reason of client setup configuration errors

## Cases
### `userNameAndPasswordAreRequired`

```swift
case userNameAndPasswordAreRequired
```

`sip user`and `sip password` are  missing when using the USER / PASSWORD login method

### `userNameIsRequired`

```swift
case userNameIsRequired
```

`sip user` is missing when using the USER / PASSWORD login method

### `passwordIsRequired`

```swift
case passwordIsRequired
```

`password` is missing when using the USER / PASSWORD login method

### `tokenIsRequired`

```swift
case tokenIsRequired
```

`token` is missing when using the Token login method.

### `voiceSdkIsRequired`

```swift
case voiceSdkIsRequired
```

`token` is missing when using the Token login method.
