//
//  GatewayMessage.swift
//  TelnyxRTC
//
//  Created by Guillermo Battistel on 05/08/2021.
//

internal enum GatewayStates : String {
    case UNREGED = "UNREGED"
    case TRYING = "TRYING"
    case REGISTER = "REGISTER"
    case REGED = "REGED"
    case UNREGISTER = "UNREGISTER"
    case FAILED = "FAILED"
    case FAIL_WAIT = "FAIL_WAIT"
    case EXPIRED = "EXPIRED"
    case NOREG = "NOREG"
}
