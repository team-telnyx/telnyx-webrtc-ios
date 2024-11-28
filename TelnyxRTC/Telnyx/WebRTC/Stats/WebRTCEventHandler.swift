import WebRTC

protocol WebRTCEventHandler {
    var onSignalingStateChange: ((RTCSignalingState) -> Void)? { get set }
    var onAddStream: ((RTCMediaStream) -> Void)? { get set }
    var onRemoveStream: ((RTCMediaStream) -> Void)? { get set }
    var onNegotiationNeeded: (() -> Void)? { get set }
    var onIceConnectionChange: ((RTCIceConnectionState) -> Void)? { get set }
    var onIceGatheringChange: ((RTCIceGatheringState) -> Void)? { get set }
    var onIceCandidate: ((RTCIceCandidate) -> Void)? { get set }
    var onRemoveIceCandidates: (([RTCIceCandidate]) -> Void)? { get set }
    var onDataChannel: ((RTCDataChannel) -> Void)? { get set }
}

