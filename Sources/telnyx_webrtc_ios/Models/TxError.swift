//
//  TxError.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 3/14/21.
//  Copyright © 2021 Telnyx LLC. All rights reserved.
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
        /// `sip user`and `sip password` are  missing when using the USER / PASSWORD login method
        case userNameAndPasswordAreRequired
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

    /// The underlying reason of the server errors
    public enum ServerErrorReason {
        /// Any server signaling error. We get the message and code from the server
        case signalingServerError(message: String, code: String)
        /// Gateway is not registered.
        case gatewayNotRegistered
    }

    /// Socket connection failures.
    case socketConnectionFailed(reason: SocketFailureReason)
    /// There's an invalid parameter when setting up the SDK
    case clientConfigurationFailed(reason: ClientConfigurationFailureReason)
    /// There's an invalid parameter when starting a call
    case callFailed(reason: CallFailureReason)
    /// When the signaling server sends an error
    case serverError(reason: ServerErrorReason)
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
        case .userNameAndPasswordAreRequired,
             .passwordIsRequired,
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

extension TxError.ServerErrorReason {
    var errorMessage: String? {
        switch self {
            case let .signalingServerError(message: message, code: code):
                return "Message: \(message), code: \(code)"
            case .gatewayNotRegistered:
                return nil
        }
    }

    var underlyingError: Error? {
        switch self {
            case .signalingServerError,
                 .gatewayNotRegistered:
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
        case let .serverError(reason):
            return reason.errorMessage
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
        case .userNameAndPasswordAreRequired:
            return "User name and password are required."
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

extension TxError.ServerErrorReason {
    public var localizedDescription: String {
        switch self {
            case .signalingServerError(message: let message, code: let code):
                return "Server error: \(message), code: \(code)"
            case .gatewayNotRegistered:
                return "Gateway not registered."
        }
    }
}
