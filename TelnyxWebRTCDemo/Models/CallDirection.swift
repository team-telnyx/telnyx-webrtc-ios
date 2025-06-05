/// Call direction enumeration
public enum CallDirection: String, CaseIterable {
    case incoming = "incoming"
    case outgoing = "outgoing"
}

/// Call status enumeration
public enum CallStatus: String, CaseIterable {
    case answered = "answered"
    case missed = "missed"
    case rejected = "rejected"
    case failed = "failed"
    case cancelled = "cancelled"
}