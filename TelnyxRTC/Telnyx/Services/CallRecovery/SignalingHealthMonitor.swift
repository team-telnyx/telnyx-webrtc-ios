import Foundation
import WebRTC

/// Decides whether a failed active call restarts ICE or uses reconnect/reattach.
///
/// The monitor owns recovery state and timers, while `Call` owns WebRTC
/// renegotiation and `TxClient` owns reconnect/reattach mechanics.
internal final class SignalingHealthMonitor {
    /// Serializes recovery transitions and timer callbacks independently of the
    /// main queue, where CallKit and other UI-facing work may run.
    private let queue = DispatchQueue(label: "com.telnyx.SignalingHealthMonitor")

    private enum RecoveryMode: Equatable {
        case idle
        case probing
        case iceRestarting
        case verifyingMedia
        case reattaching
    }

    private enum SignalingProbePurpose {
        case mediaRecovery
        case healthCheck
    }

    private let iceRestartTimeout: TimeInterval
    private let signalingProbeTimeout: TimeInterval
    private let recentInboundActivityThreshold: TimeInterval
    private let confirmedOutboundActivityThreshold: TimeInterval
    private let staleInboundActivityThreshold: TimeInterval
    private let signalingHealthCheckInterval: TimeInterval
    private let inboundRtpStallTimeout: TimeInterval
    private let postIceRestartMediaTimeout: TimeInterval
    private let peerDisconnectedRecoveryDelay: TimeInterval
    private let isSignalingAvailable: () -> Bool
    private let sendSignalingProbe: () -> String?
    private let startIceRestart: (Call) -> Void
    private let shouldForceRelayForRecovery: (Call, @escaping (Bool) -> Void) -> Void
    private let requestReattach: (Bool) -> Void

    private weak var recoveringCall: Call?
    private var recoveryMode: RecoveryMode = .idle
    private var iceRestartTimeoutWorkItem: DispatchWorkItem?
    private var signalingProbeTimeoutWorkItem: DispatchWorkItem?
    private var signalingHealthCheckTimer: DispatchSourceTimer?
    private var mediaVerificationTimeoutWorkItem: DispatchWorkItem?
    private var peerDisconnectedRecoveryWorkItem: DispatchWorkItem?
    private var pendingSignalingProbeId: String?
    private var pendingSignalingProbePurpose: SignalingProbePurpose?
    private var lastInboundSignalingActivity = Date()
    private var lastConfirmedOutboundActivity = Date()
    private weak var monitoredActiveCall: Call?
    private var shouldEvaluateRelayFallback = false
    private var lastInboundRtpPacketCount: Int?
    private var lastInboundRtpProgressAt: Date?
    private var iceRestartStartedAt: Date?
    private var mediaVerificationStartedAt: Date?

    init(
        iceRestartTimeout: TimeInterval = 15,
        signalingProbeTimeout: TimeInterval = 5,
        recentInboundActivityThreshold: TimeInterval = 3,
        confirmedOutboundActivityThreshold: TimeInterval = 45,
        staleInboundActivityThreshold: TimeInterval = 20,
        signalingHealthCheckInterval: TimeInterval = 3,
        inboundRtpStallTimeout: TimeInterval = 3,
        postIceRestartMediaTimeout: TimeInterval = 3,
        peerDisconnectedRecoveryDelay: TimeInterval = 3,
        isSignalingAvailable: @escaping () -> Bool,
        sendSignalingProbe: @escaping () -> String?,
        startIceRestart: @escaping (Call) -> Void,
        shouldForceRelayForRecovery: @escaping (Call, @escaping (Bool) -> Void) -> Void = { _, completion in completion(false) },
        requestReattach: @escaping (Bool) -> Void
    ) {
        self.iceRestartTimeout = iceRestartTimeout
        self.signalingProbeTimeout = signalingProbeTimeout
        self.recentInboundActivityThreshold = recentInboundActivityThreshold
        self.confirmedOutboundActivityThreshold = confirmedOutboundActivityThreshold
        self.staleInboundActivityThreshold = staleInboundActivityThreshold
        self.signalingHealthCheckInterval = signalingHealthCheckInterval
        self.inboundRtpStallTimeout = inboundRtpStallTimeout
        self.postIceRestartMediaTimeout = postIceRestartMediaTimeout
        self.peerDisconnectedRecoveryDelay = peerDisconnectedRecoveryDelay
        self.isSignalingAvailable = isSignalingAvailable
        self.sendSignalingProbe = sendSignalingProbe
        self.startIceRestart = startIceRestart
        self.shouldForceRelayForRecovery = shouldForceRelayForRecovery
        self.requestReattach = requestReattach
    }

    deinit {
        signalingHealthCheckTimer?.setEventHandler {}
        signalingHealthCheckTimer?.cancel()
        peerDisconnectedRecoveryWorkItem?.cancel()
    }

    func networkPathDidChange() {
        executeOnQueue { [weak self] in
            guard let self = self, self.recoveryMode != .reattaching else { return }
            Logger.log.i(message: "[CALL-RECOVERY] Network path changed; using required reconnect/reattach flow")
            self.cancelRecoveryTimeouts()
            self.recoveringCall = nil
            self.shouldEvaluateRelayFallback = false
            self.recoveryMode = .reattaching
        }
    }

    func iceConnectionStateDidChange(_ call: Call, state: RTCIceConnectionState) {
        guard state == .failed else { return }
        executeOnQueue { [weak self] in
            self?.requestRecovery(for: call, trigger: "ice_failed")
        }
    }

    func peerConnectionStateDidChange(_ call: Call, state: RTCPeerConnectionState) {
        executeOnQueue { [weak self] in
            guard let self = self else { return }
            switch state {
            case .failed:
                self.cancelPeerDisconnectedRecovery()
                self.requestRecovery(for: call, trigger: "peer_connection_failed")
            case .disconnected:
                self.startPeerDisconnectedRecoveryDelay(for: call)
            case .connected:
                self.cancelPeerDisconnectedRecovery()
            default:
                break
            }
        }
    }

    /// Records every inbound signaling frame. A probe is successful only when a
    /// result or error has the exact JSON-RPC id generated for that probe.
    func signalingMessageReceived(_ message: Message) {
        executeOnQueue { [weak self] in
            guard let self = self else { return }
            self.lastInboundSignalingActivity = Date()

            guard message.result != nil || message.serverError != nil else { return }
            self.lastConfirmedOutboundActivity = Date()
            guard self.recoveryMode == .probing,
                  self.pendingSignalingProbeId == message.id,
                  let purpose = self.pendingSignalingProbePurpose else { return }

            Logger.log.i(message: "[CALL-RECOVERY] Signaling health probe succeeded")
            self.cancelSignalingProbeTimeout()
            self.recoveryMode = .idle
            switch purpose {
            case .mediaRecovery:
                guard let call = self.recoveringCall else { return }
                self.startIceRestartRecovery(for: call)
            case .healthCheck:
                self.recoveringCall = nil
            }
        }
    }

    func iceRestartDidComplete(for call: Call) {
        executeOnQueue { [weak self] in
            guard let self = self, self.recoveryMode == .iceRestarting, self.recoveringCall === call else { return }
            Logger.log.i(message: "[CALL-RECOVERY] ICE restart answer applied")
            self.cancelIceRestartTimeout()

            // An SDP response only proves signaling succeeded. Media recovery is
            // complete only after the restarted transport receives RTP again.
            if let restartStartedAt = self.iceRestartStartedAt,
               let lastProgressAt = self.lastInboundRtpProgressAt,
               lastProgressAt >= restartStartedAt {
                Logger.log.i(message: "[CALL-RECOVERY] Inbound RTP resumed during ICE restart")
                self.finishRecovery()
                return
            }

            self.recoveryMode = .verifyingMedia
            self.mediaVerificationStartedAt = Date()
            self.startMediaVerificationTimeout(for: call)
        }
    }

    func iceRestartRequestDidFail(for call: Call, error: Error) {
        executeOnQueue { [weak self] in
            guard let self = self, self.recoveryMode == .iceRestarting, self.recoveringCall === call else { return }
            Logger.log.e(message: "[CALL-RECOVERY] ICE restart failed: \(error.localizedDescription)")
            self.beginReattach()
        }
    }

    func callStateDidChange(_ call: Call) {
        executeOnQueue { [weak self] in
            guard let self = self else { return }

            switch call.callState {
            case .ACTIVE:
                if self.recoveryMode == .reattaching {
                    Logger.log.i(message: "[CALL-RECOVERY] Reattached call is active")
                    self.finishRecovery()
                }
                self.monitoredActiveCall = call
                self.startSignalingHealthChecks()
                self.resetInboundRtpTracking()
            case .HELD:
                if self.monitoredActiveCall === call {
                    self.resetInboundRtpTracking()
                }
            case .DONE, .DROPPED:
                self.cancelPeerDisconnectedRecovery()
                if self.monitoredActiveCall === call {
                    self.stopSignalingHealthChecks()
                    self.monitoredActiveCall = nil
                }
                if self.recoveringCall === call {
                    self.finishRecovery()
                }
            default:
                break
            }
        }
    }

    private func requestRecovery(for call: Call, trigger: String) {
        cancelPeerDisconnectedRecovery()
        guard call.callState == .ACTIVE else {
            Logger.log.i(message: "[CALL-RECOVERY] Ignoring \(trigger); call is \(call.callState.value)")
            return
        }
        guard recoveryMode == .idle else {
            Logger.log.i(message: "[CALL-RECOVERY] Ignoring \(trigger); recovery is already in progress")
            return
        }

        recoveringCall = call
        shouldEvaluateRelayFallback = true
        if !isSignalingAvailable() {
            Logger.log.w(message: "[CALL-RECOVERY] \(trigger) with signaling unavailable; starting reconnect/reattach")
            beginReattach()
        } else if hasRecentSignalingActivity() {
            Logger.log.w(message: "[CALL-RECOVERY] \(trigger) with signaling available; starting ICE restart")
            startIceRestartRecovery(for: call)
        } else {
            Logger.log.w(message: "[CALL-RECOVERY] \(trigger) with stale signaling; probing before ICE restart")
            startSignalingProbe(for: call, purpose: .mediaRecovery)
        }
    }

    private func hasRecentSignalingActivity() -> Bool {
        let now = Date()
        return now.timeIntervalSince(lastInboundSignalingActivity) <= recentInboundActivityThreshold
            && now.timeIntervalSince(lastConfirmedOutboundActivity) <= confirmedOutboundActivityThreshold
    }

    private func startIceRestartRecovery(for call: Call) {
        recoveryMode = .iceRestarting
        iceRestartStartedAt = Date()
        startIceRestartTimeout(for: call)
        startIceRestart(call)
    }

    private func startSignalingProbe(for call: Call, purpose: SignalingProbePurpose) {
        guard let probeId = sendSignalingProbe() else {
            Logger.log.e(message: "[CALL-RECOVERY] Unable to send signaling health probe")
            beginReattach()
            return
        }

        cancelSignalingProbeTimeout()
        recoveryMode = .probing
        pendingSignalingProbeId = probeId
        pendingSignalingProbePurpose = purpose
        let workItem = DispatchWorkItem { [weak self, weak call] in
            guard let self = self,
                  let call = call,
                  self.recoveryMode == .probing,
                  self.recoveringCall === call else { return }
            Logger.log.e(message: "[CALL-RECOVERY] Signaling health probe timed out after \(self.signalingProbeTimeout)s")
            self.beginReattach()
        }
        signalingProbeTimeoutWorkItem = workItem
        queue.asyncAfter(deadline: .now() + signalingProbeTimeout, execute: workItem)
    }

    private func startSignalingHealthChecks() {
        guard signalingHealthCheckTimer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + signalingHealthCheckInterval, repeating: signalingHealthCheckInterval)
        timer.setEventHandler { [weak self] in
            self?.checkSignalingHealth()
        }
        signalingHealthCheckTimer = timer
        timer.resume()
    }

    private func stopSignalingHealthChecks() {
        signalingHealthCheckTimer?.setEventHandler {}
        signalingHealthCheckTimer?.cancel()
        signalingHealthCheckTimer = nil
    }

    private func startPeerDisconnectedRecoveryDelay(for call: Call) {
        guard recoveryMode == .idle else { return }
        cancelPeerDisconnectedRecovery()
        let workItem = DispatchWorkItem { [weak self, weak call] in
            guard let self = self,
                  let call = call,
                  self.recoveryMode == .idle,
                  call.callState == .ACTIVE else { return }
            Logger.log.w(message: "[CALL-RECOVERY] Peer remained disconnected for \(self.peerDisconnectedRecoveryDelay)s; starting recovery")
            self.requestRecovery(for: call, trigger: "peer_connection_disconnected")
        }
        peerDisconnectedRecoveryWorkItem = workItem
        queue.asyncAfter(deadline: .now() + peerDisconnectedRecoveryDelay, execute: workItem)
    }

    private func cancelPeerDisconnectedRecovery() {
        peerDisconnectedRecoveryWorkItem?.cancel()
        peerDisconnectedRecoveryWorkItem = nil
    }

    private func resetInboundRtpTracking() {
        lastInboundRtpPacketCount = nil
        lastInboundRtpProgressAt = Date()
        iceRestartStartedAt = nil
        mediaVerificationStartedAt = nil
    }

    /// Receives the inbound packet counter from the call-report collector's
    /// existing WebRTC sample. This intentionally does not request a second
    /// full stats report solely for media health.
    func inboundRtpSampleReceived(_ packetsReceived: Int, for call: Call) {
        executeOnQueue { [weak self] in
            self?.recordInboundRtpPackets(packetsReceived, for: call)
        }
    }

    private func recordInboundRtpPackets(_ packetsReceived: Int, for call: Call) {
        guard monitoredActiveCall === call, call.callState == .ACTIVE else { return }

        let now = Date()
        let previousPacketCount = lastInboundRtpPacketCount
        lastInboundRtpPacketCount = packetsReceived

        guard let previousPacketCount = previousPacketCount else {
            lastInboundRtpProgressAt = now
            return
        }

        guard packetsReceived > previousPacketCount else {
            if recoveryMode == .idle,
               let lastProgressAt = lastInboundRtpProgressAt,
               now.timeIntervalSince(lastProgressAt) >= inboundRtpStallTimeout {
                Logger.log.w(message: "[CALL-RECOVERY] Inbound RTP has not advanced for \(inboundRtpStallTimeout)s; starting ICE restart")
                requestRecovery(for: call, trigger: "inbound_rtp_stalled")
            }
            return
        }

        lastInboundRtpProgressAt = now
        if recoveryMode == .verifyingMedia,
           let verificationStartedAt = mediaVerificationStartedAt,
           now >= verificationStartedAt {
            Logger.log.i(message: "[CALL-RECOVERY] Inbound RTP resumed after ICE restart")
            finishRecovery()
        }
    }

    private func checkSignalingHealth() {
        guard recoveryMode == .idle,
              let call = monitoredActiveCall,
              call.callState == .ACTIVE else { return }
        shouldEvaluateRelayFallback = false

        guard isSignalingAvailable() else {
            Logger.log.w(message: "[CALL-RECOVERY] Signaling socket is unavailable during an active call")
            recoveringCall = call
            beginReattach()
            return
        }

        let now = Date()
        let inboundIsStale = now.timeIntervalSince(lastInboundSignalingActivity) >= staleInboundActivityThreshold
        let outboundIsStale = now.timeIntervalSince(lastConfirmedOutboundActivity) >= confirmedOutboundActivityThreshold
        guard inboundIsStale || outboundIsStale else { return }

        Logger.log.w(message: "[CALL-RECOVERY] Signaling activity is stale during an active call; probing")
        recoveringCall = call
        startSignalingProbe(for: call, purpose: .healthCheck)
    }

    private func startIceRestartTimeout(for call: Call) {
        cancelIceRestartTimeout()
        let workItem = DispatchWorkItem { [weak self, weak call] in
            guard let self = self,
                  let call = call,
                  self.recoveryMode == .iceRestarting,
                  self.recoveringCall === call else { return }
            Logger.log.e(message: "[CALL-RECOVERY] ICE restart timed out after \(self.iceRestartTimeout)s")
            self.beginReattach()
        }
        iceRestartTimeoutWorkItem = workItem
        queue.asyncAfter(deadline: .now() + iceRestartTimeout, execute: workItem)
    }

    private func startMediaVerificationTimeout(for call: Call) {
        cancelMediaVerificationTimeout()
        let workItem = DispatchWorkItem { [weak self, weak call] in
            guard let self = self,
                  let call = call,
                  self.recoveryMode == .verifyingMedia,
                  self.recoveringCall === call else { return }
            Logger.log.e(message: "[CALL-RECOVERY] ICE restart did not restore inbound RTP after \(self.postIceRestartMediaTimeout)s; reattaching")
            self.beginReattach()
        }
        mediaVerificationTimeoutWorkItem = workItem
        queue.asyncAfter(deadline: .now() + postIceRestartMediaTimeout, execute: workItem)
    }

    private func beginReattach() {
        cancelRecoveryTimeouts()
        recoveryMode = .reattaching
        guard shouldEvaluateRelayFallback, let call = recoveringCall else {
            requestReattach(false)
            return
        }

        shouldEvaluateRelayFallback = false
        shouldForceRelayForRecovery(call) { [weak self] shouldForceRelay in
            self?.executeOnQueue { [weak self] in
                guard let self = self, self.recoveryMode == .reattaching else { return }
                if shouldForceRelay {
                    Logger.log.w(message: "[CALL-RECOVERY] Failed VPN direct path; forcing relay for replacement call")
                }
                self.requestReattach(shouldForceRelay)
            }
        }
    }

    private func finishRecovery() {
        cancelRecoveryTimeouts()
        recoveringCall = nil
        shouldEvaluateRelayFallback = false
        recoveryMode = .idle
        iceRestartStartedAt = nil
        mediaVerificationStartedAt = nil
    }

    private func cancelRecoveryTimeouts() {
        cancelIceRestartTimeout()
        cancelSignalingProbeTimeout()
        cancelMediaVerificationTimeout()
    }

    private func cancelIceRestartTimeout() {
        iceRestartTimeoutWorkItem?.cancel()
        iceRestartTimeoutWorkItem = nil
    }

    private func cancelSignalingProbeTimeout() {
        signalingProbeTimeoutWorkItem?.cancel()
        signalingProbeTimeoutWorkItem = nil
        pendingSignalingProbeId = nil
        pendingSignalingProbePurpose = nil
    }

    private func cancelMediaVerificationTimeout() {
        mediaVerificationTimeoutWorkItem?.cancel()
        mediaVerificationTimeoutWorkItem = nil
    }

    private func executeOnQueue(_ block: @escaping () -> Void) {
        queue.async(execute: block)
    }
}
