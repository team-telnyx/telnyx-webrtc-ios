//
//  TxError.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 3/14/21.
//

import Foundation

/// `TxError` is the error type returned by Telnyx WebRTC SDK. It encompasses a few different types of errors, each with
/// their own associated reasons.
public enum TxError : Error {

    /// The underlying reason of the Socket connection failure
    public enum SocketFailureReason {
        /// Socket is not connected. Check that you have an active connection.
        case socketNotConnected
        /// Socket connection was cancelled.
        case socketCancelled
    }

    /// The underlying reason of client setup configuration errors
    public enum ClientConfigurationFailureReason {
        /// `sip user` is missing when using the USER / PASSWORD login method
        case userNameIsRequired
        /// `password` is missing when using the USER / PASSWORD login method
        case passwordIsRequired
        /// `token` is missing when using the Token login method.
        case tokenIsRequired
    }

    /// The underlying reason of the call errors
    public enum CallFailureReason {
        /// There's no destination number when placing an outbound call
        case destinationNumberIsRequired
        /// Session Id is missing when starting a call. Check you're logged in before starting a call.
        case sessionIdIsRequired
    }

    /// Socket connection failures.
    case socketConnectionFailed(reason: SocketFailureReason)
    /// There's an invalid parameter when setting up the SDK
    case clientConfigurationFailed(reason: ClientConfigurationFailureReason)
    /// There's an invalid parameter when starting a call
    case callFailed(reason: CallFailureReason)
}

// MARK: - Underlying errors

extension TxError.SocketFailureReason {
    var underlyingError: Error? {
        switch self {
        case .socketCancelled, .socketNotConnected:
            return nil
        }
    }
}

extension TxError.ClientConfigurationFailureReason {
    var underlyingError: Error? {
        switch self {
        case .passwordIsRequired,
             .userNameIsRequired,
             .tokenIsRequired:
            return nil
        }
    }
}

extension TxError.CallFailureReason {
    var underlyingError: Error? {
        switch self {
        case .destinationNumberIsRequired,
             .sessionIdIsRequired:
            return nil
        }
    }
}


// MARK: - Error Descriptions
extension TxError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .socketConnectionFailed(reason):
            return "Socket error: \(reason.localizedDescription ?? "No description.")"
        case let .clientConfigurationFailed(reason):
            return "Client configuration error: \(reason.localizedDescription ?? "No description.")"
        case let .callFailed(reason):
            return "Call failed: \(reason.localizedDescription ?? "No description.")"
        }
    }
}

extension TxError.SocketFailureReason: LocalizedError {
    public var localizedDescription: String? {
        switch self {
        case .socketNotConnected:
            return "Socket connection cancelled."
        case .socketCancelled:
            return "Socket is not connected, check that you have called .connect() first."
        }
    }
}

extension TxError.ClientConfigurationFailureReason {
    public var localizedDescription: String? {
        switch self {
        case .userNameIsRequired:
            return "User name is required."
        case .passwordIsRequired:
            return "Password is required."
        case .tokenIsRequired:
            return "Token is required."
        }
    }
}

extension TxError.CallFailureReason {
    public var localizedDescription: String? {
        switch self {
        case .destinationNumberIsRequired:
            return "destinationNumber is missing. A destination number is required to start a call."
        case .sessionIdIsRequired:
            return "sessionId is missing, check that you have called .connect() first."
        }
    }
}
