import WebRTC
import Foundation

extension RTCConfiguration {
    func telnyx_to_stats_dictionary() -> [String: Any] {
        var configurationData = [String: Any]()
        configurationData["bundlePolicy"] = self.bundlePolicy.telnyx_to_string()
        configurationData["iceTransportPolicy"] = self.iceTransportPolicy.telnyx_to_string()
        configurationData["rtcpMuxPolicy"] = self.rtcpMuxPolicy.telnyx_to_string()
        configurationData["continualGatheringPolicy"] = self.continualGatheringPolicy.telnyx_to_string()
        configurationData["sdpSemantics"] = self.sdpSemantics.telnyx_to_string()
        configurationData["iceCandidatePoolSize"] = self.iceCandidatePoolSize
        configurationData["iceServers"] = self.iceServers.map { $0.telnyx_to_stats_dictionary() }
        configurationData["rtcpAudioReportIntervalMs"] = self.rtcpAudioReportIntervalMs
        configurationData["rtcpVideoReportIntervalMs"] = self.rtcpVideoReportIntervalMs
        
        return configurationData
    }
}
