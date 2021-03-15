//
//  TxError.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 3/14/21.
//

import Foundation

enum TxErrors : Error {
  case destinationNumberIsRequired
  case tokenIsRequired
  case userNameIsRequired
  case passwordIsRequired
  case sessionIdIsRequired
  case socketNotConnected
  case socketCancelled
}


extension TxErrors: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .destinationNumberIsRequired:
            return "destinationNumber is missing. A destination number is required to start a call."
        case .userNameIsRequired:
            return "User name is required."
        case .passwordIsRequired:
            return "Password is required."
        case .tokenIsRequired:
            return "Token is required."
        case .socketNotConnected:
            return "Socket connection cancelled."
        case .socketCancelled:
            return "Socket is not connected, check that you have called .connect() first."
        case .sessionIdIsRequired:
          return "SessionId is missing, check that you have called .connect() first."
        }
    }
}
