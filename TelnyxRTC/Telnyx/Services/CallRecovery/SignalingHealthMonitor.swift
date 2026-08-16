import Foundation
import WebRTC

/// Decides whether a failed active call restarts ICE or uses reconnect/reattach.
///
/// The monitor owns recovery state and timers, while `Call` owns WebRTC
/// renegotiation and `TxClient` owns reconnect/reattach mechanics.
internal final class SignalingHealthMonitor {
    private enum RecoveryMode: Equatable {
        case idle
        case probing
        case iceRestarting
        case reattaching
    }

    private let iceRestartTimeout: TimeInterval
    private let signalingProbeTimeout: TimeInterval
    private let recentInboundActivityThreshold: TimeInterval
    private let confirmedOutboundActivityThreshold: TimeInterval
    private let staleInboundActivityThreshold: TimeInterval
    private let signalingHealthCheckInterval: TimeInterval
    private let isSignalingAvailable: () -> Bool
    private let sendSignalingProbe: () -> String?
    private let startIceRestart: (Call) -> Void
    private let requestReattach: () -> Void

    private weak var recoveringCall: Call?
    private var recoveryMode: RecoveryMode = .idle
    private var iceRestartTimeoutWorkItem: DispatchWorkItem?
    private var signalingProbeTimeoutWorkItem: DispatchWorkItem?
    private var signalingHealthCheckTimer: DispatchSourceTimer?
    private var pendingSignalingProbeId: String?
    private var lastInboundSignalingActivity = Date()
    private var lastConfirmedOutboundActivity = Date()
    private weak var monitoredActiveCall: Call?

    init(
        iceRestartTimeout: TimeInterval = 15,
        signalingProbeTimeout: TimeInterval = 5,
        recentInboundActivityThreshold: TimeInterval = 3,
        confirmedOutboundActivityThreshold: TimeInterval = 45,
        staleInboundActivityThreshold: TimeInterval = 20,
        signalingHealthCheckInterval: TimeInterval = 3,
        isSignalingAvailable: @escaping () -> Bool,
        sendSignalingProbe: @escaping () -> String?,
        startIceRestart: @escaping (Call) -> Void,
        requestReattach: @escaping () -> Void
    ) {
        self.iceRestartTimeout = iceRestartTimeout
        self.signalingProbeTimeout = signalingProbeTimeout
        self.recentInboundActivityThreshold = recentInboundActivityThreshold
        self.confirmedOutboundActivityThreshold = confirmedOutboundActivityThreshold
        self.staleInboundActivityThreshold = staleInboundActivityThreshold
        self.signalingHealthCheckInterval = signalingHealthCheckInterval
        self.isSignalingAvailable = isSignalingAvailable
        self.sendSignalingProbe = sendSignalingProbe
        self.startIceRestart = startIceRestart
        self.requestReattach = requestReattach
    }

    deinit {
        signalingHealthCheckTimer?.setEventHandler {}
        signalingHealthCheckTimer?.cancel()
    }

    func networkPathDidChange() {
        executeOnMain { [weak self] in
            guard let self = self, self.recoveryMode != .reattaching else { return }
            Logger.log.i(message: "[CALL-RECOVERY] Network path changed; using required reconnect/reattach flow")
            self.cancelRecoveryTimeouts()
            self.recoveringCall = nil
            self.recoveryMode = .reattaching
        }
    }

    func iceConnectionStateDidChange(_ call: Call, state: RTCIceConnectionState) {
        guard state == .failed else { return }
        requestRecovery(for: call, trigger: "ice_failed")
    }

    func peerConnectionStateDidChange(_ call: Call, state: RTCPeerConnectionState) {
        guard state == .failed else { return }
        requestRecovery(for: call, trigger: "peer_connection_failed")
    }

    /// Records every inbound signaling frame. A probe is successful only when a
    /// result or error has the exact JSON-RPC id generated for that probe.
    func signalingMessageReceived(_ message: Message) {
        executeOnMain { [weak self] in
            guard let self = self else { return }
            self.lastInboundSignalingActivity = Date()

            guard message.result != nil || message.serverError != nil else { return }
            self.lastConfirmedOutboundActivity = Date()
            guard self.recoveryMode == .probing,
                  self.pendingSignalingProbeId == message.id,
                  let call = self.recoveringCall else { return }

            Logger.log.i(message: "[CALL-RECOVERY] Signaling health probe succeeded")
            self.cancelSignalingProbeTimeout()
            self.recoveryMode = .idle
            self.startIceRestartRecovery(for: call)
        }
    }

    func iceRestartDidComplete(for call: Call) {
        executeOnMain { [weak self] in
            guard let self = self, self.recoveryMode == .iceRestarting, self.recoveringCall === call else { return }
            Logger.log.i(message: "[CALL-RECOVERY] ICE restart answer applied")
            self.finishRecovery()
        }
    }

    func iceRestartRequestDidFail(for call: Call, error: Error) {
        executeOnMain { [weak self] in
            guard let self = self, self.recoveryMode == .iceRestarting, self.recoveringCall === call else { return }
            Logger.log.e(message: "[CALL-RECOVERY] ICE restart failed: \(error.localizedDescription)")
            self.beginReattach()
        }
    }

    func callStateDidChange(_ call: Call) {
        executeOnMain { [weak self] in
            guard let self = self else { return }

            switch call.callState {
            case .ACTIVE:
                if self.recoveryMode == .reattaching {
                    Logger.log.i(message: "[CALL-RECOVERY] Reattached call is active")
                    self.finishRecovery()
                }
                self.monitoredActiveCall = call
                self.startSignalingHealthChecks()
            case .DONE, .DROPPED:
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
        executeOnMain { [weak self] in
            guard let self = self else { return }
            guard call.callState == .ACTIVE else {
                Logger.log.i(message: "[CALL-RECOVERY] Ignoring \(trigger); call is \(call.callState.value)")
                return
            }
            guard self.recoveryMode == .idle else {
                Logger.log.i(message: "[CALL-RECOVERY] Ignoring \(trigger); recovery is already in progress")
                return
            }

            self.recoveringCall = call
            if !self.isSignalingAvailable() {
                Logger.log.w(message: "[CALL-RECOVERY] \(trigger) with signaling unavailable; starting reconnect/reattach")
                self.beginReattach()
            } else if self.hasRecentSignalingActivity() {
                Logger.log.w(message: "[CALL-RECOVERY] \(trigger) with signaling available; starting ICE restart")
                self.startIceRestartRecovery(for: call)
            } else {
                Logger.log.w(message: "[CALL-RECOVERY] \(trigger) with stale signaling; probing before ICE restart")
                self.startSignalingProbe(for: call)
            }
        }
    }

    private func hasRecentSignalingActivity() -> Bool {
        let now = Date()
        return now.timeIntervalSince(lastInboundSignalingActivity) <= recentInboundActivityThreshold
            && now.timeIntervalSince(lastConfirmedOutboundActivity) <= confirmedOutboundActivityThreshold
    }

    private func startIceRestartRecovery(for call: Call) {
        recoveryMode = .iceRestarting
        startIceRestartTimeout(for: call)
        startIceRestart(call)
    }

    private func startSignalingProbe(for call: Call) {
        guard let probeId = sendSignalingProbe() else {
            Logger.log.e(message: "[CALL-RECOVERY] Unable to send signaling health probe")
            beginReattach()
            return
        }

        cancelSignalingProbeTimeout()
        recoveryMode = .probing
        pendingSignalingProbeId = probeId
        let workItem = DispatchWorkItem { [weak self, weak call] in
            guard let self = self,
                  let call = call,
                  self.recoveryMode == .probing,
                  self.recoveringCall === call else { return }
            Logger.log.e(message: "[CALL-RECOVERY] Signaling health probe timed out after \(self.signalingProbeTimeout)s")
            self.beginReattach()
        }
        signalingProbeTimeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + signalingProbeTimeout, execute: workItem)
    }

    private func startSignalingHealthChecks() {
        guard signalingHealthCheckTimer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
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

    private func checkSignalingHealth() {
        guard recoveryMode == .idle,
              let call = monitoredActiveCall,
              call.callState == .ACTIVE else { return }

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
        startSignalingProbe(for: call)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + iceRestartTimeout, execute: workItem)
    }

    private func beginReattach() {
        cancelRecoveryTimeouts()
        recoveryMode = .reattaching
        requestReattach()
    }

    private func finishRecovery() {
        cancelRecoveryTimeouts()
        recoveringCall = nil
        recoveryMode = .idle
    }

    private func cancelRecoveryTimeouts() {
        cancelIceRestartTimeout()
        cancelSignalingProbeTimeout()
    }

    private func cancelIceRestartTimeout() {
        iceRestartTimeoutWorkItem?.cancel()
        iceRestartTimeoutWorkItem = nil
    }

    private func cancelSignalingProbeTimeout() {
        signalingProbeTimeoutWorkItem?.cancel()
        signalingProbeTimeoutWorkItem = nil
        pendingSignalingProbeId = nil
    }

    private func executeOnMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
}
