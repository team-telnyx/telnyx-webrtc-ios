//
//  UserDefaultExtension.swift
//  TelnyxWebRTCDemo
//
//  Created by Guillermo Battistel on 18/05/2021.
//

import Foundation
import TelnyxRTC

enum UserDefaultsKey: String {
    case selectedSipCredential = "SELECTED_SIP_CREDENTIAL"
    case sipCredentials = "SIP_CREDENTIALS"
    case pushDeviceToken = "PUSH_DEVICE_TOKEN"
    case callDestination = "CALL_DESTINATION"
    case webrtcEnvironment = "WEBRTC_ENVIRONMENT"
    case forceRelayCandidate = "FORCE_RELAY_CANDIDATE"
    case webrtcStats = "WEBRTC_STATS"
    case sendWebRTCStatsViaSocket = "SEND_WEBRTC_STATS_VIA_SOCKET"
    case useTrickleIce = "USE_TRICKLE_ICE"
    case preferredAudioCodecs = "PREFERRED_AUDIO_CODECS"
}

extension UserDefaults {
    
    // MARK: - Push Token
    func savePushToken(_ pushToken: String) {
        set(pushToken, forKey: UserDefaultsKey.pushDeviceToken.rawValue)
    }
    
    func deletePushToken() {
        removeObject(forKey: UserDefaultsKey.pushDeviceToken.rawValue)
    }
    
    func getPushToken() -> String? {
        return string(forKey: UserDefaultsKey.pushDeviceToken.rawValue)
    }
    
    func saveCallDestination(_ callDestination: String) {
        set(callDestination, forKey: UserDefaultsKey.callDestination.rawValue)
    }
    
    func getCallDestination() -> String {
        return string(forKey: UserDefaultsKey.callDestination.rawValue) ?? ""
    }
    
    func getEnvironment() -> WebRTCEnvironment {
        let value = string(forKey: UserDefaultsKey.webrtcEnvironment.rawValue) ?? ""
        return WebRTCEnvironment.fromString(value)
    }
    
    func saveEnvironment(_ environment: WebRTCEnvironment) {
        let value = environment.toString()
        set(value, forKey: UserDefaultsKey.webrtcEnvironment.rawValue)
    }
    
    // MARK: - Force Relay Candidate
    func saveForceRelayCandidate(_ forceRelay: Bool) {
        set(forceRelay, forKey: UserDefaultsKey.forceRelayCandidate.rawValue)
    }
    
    func getForceRelayCandidate() -> Bool {
        return bool(forKey: UserDefaultsKey.forceRelayCandidate.rawValue)
    }
    
    // MARK: - WebRTC Stats
    func saveWebRTCStats(_ enabled: Bool) {
        set(enabled, forKey: UserDefaultsKey.webrtcStats.rawValue)
    }
    
    func getWebRTCStats() -> Bool {
        // Default to true if not set
        if object(forKey: UserDefaultsKey.webrtcStats.rawValue) == nil {
            return true
        }
        return bool(forKey: UserDefaultsKey.webrtcStats.rawValue)
    }
    
    // MARK: - Send WebRTC Stats Via Socket
    func saveSendWebRTCStatsViaSocket(_ enabled: Bool) {
        set(enabled, forKey: UserDefaultsKey.sendWebRTCStatsViaSocket.rawValue)
    }

    func getSendWebRTCStatsViaSocket() -> Bool {
        // Default to false if not set
        if object(forKey: UserDefaultsKey.sendWebRTCStatsViaSocket.rawValue) == nil {
            return false
        }
        return bool(forKey: UserDefaultsKey.sendWebRTCStatsViaSocket.rawValue)
    }

    // MARK: - Use Trickle ICE
    func saveUseTrickleIce(_ enabled: Bool) {
        set(enabled, forKey: UserDefaultsKey.useTrickleIce.rawValue)
    }

    func getUseTrickleIce() -> Bool {
        // Default to false if not set
        if object(forKey: UserDefaultsKey.useTrickleIce.rawValue) == nil {
            return false
        }
        return bool(forKey: UserDefaultsKey.useTrickleIce.rawValue)
    }

    // MARK: - Preferred Audio Codecs
    func savePreferredAudioCodecs(_ codecs: [TxCodecCapability]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(codecs) {
            set(encoded, forKey: UserDefaultsKey.preferredAudioCodecs.rawValue)
        }
    }

    func getPreferredAudioCodecs() -> [TxCodecCapability] {
        guard let data = data(forKey: UserDefaultsKey.preferredAudioCodecs.rawValue) else {
            return []
        }
        let decoder = JSONDecoder()
        return (try? decoder.decode([TxCodecCapability].self, from: data)) ?? []
    }

    func deletePreferredAudioCodecs() {
        removeObject(forKey: UserDefaultsKey.preferredAudioCodecs.rawValue)
    }
}

