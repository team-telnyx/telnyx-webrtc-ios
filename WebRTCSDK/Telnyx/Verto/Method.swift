//
//  Method.swift
//  WebRTCSDK
//
//  Created by Guillermo Battistel on 03/03/2021.
//

import Foundation

enum Method : String {
    //implemented
    case LOGIN = "login"
    case ANSWER = "telnyx_rtc.answer"
    case INVITE = "telnyx_rtc.invite"
    case RINGING = "telnyx_rtc.ringing"
    case CLIENT_READY = "telnyx_rtc.clientReady"
    case BYE = "telnyx_rtc.bye"
    case MODIFY = "telnyx_rtc.modify"
    case MEDIA = "telnyx_rtc.media"

    //not implemented
    case INFO = "telnyx_rtc.info"
    case ATTACH = "telnyx_rtc.attach"
    case DISPLAY = "telnyx_rtc.display"
    case EVENT = "telnyx_rtc.event"
    case PUNT = "telnyx_rtc.punt"
    case BROADCAST = "telnyx_rtc.broadcast"
    case UNSUBSCRIBE = "telnyx_rtc.unsubscribe"
}
