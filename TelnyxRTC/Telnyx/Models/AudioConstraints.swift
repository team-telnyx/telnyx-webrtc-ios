//
//  AudioConstraints.swift
//  TelnyxRTC
//
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import Foundation

/// Represents audio processing constraints for WebRTC media streams.
/// These constraints control audio processing features that improve call quality
/// by reducing echo, background noise, and normalizing audio levels.
///
/// Aligns with the W3C MediaTrackConstraints specification for audio.
///
/// - Note: For more information on the W3C specification, see:
///   - Echo Cancellation: https://w3c.github.io/mediacapture-main/getusermedia.html#def-constraint-echoCancellation
///   - Noise Suppression: https://w3c.github.io/mediacapture-main/getusermedia.html#dfn-noisesuppression
///   - Auto Gain Control: https://w3c.github.io/mediacapture-main/getusermedia.html#dfn-autogaincontrol
public struct AudioConstraints {
    
    /// Enable/disable echo cancellation. When enabled, removes acoustic
    /// echo caused by audio feedback between microphone and speaker.
    public let echoCancellation: Bool
    
    /// Enable/disable noise suppression. When enabled, reduces background
    /// noise to improve voice clarity.
    public let noiseSuppression: Bool
    
    /// Enable/disable automatic gain control. When enabled, automatically
    /// adjusts microphone gain to normalize audio levels.
    public let autoGainControl: Bool
    
    /// Default audio constraints with all features enabled
    public static let `default` = AudioConstraints()
    
    /// Initialize audio constraints with specified values
    /// - Parameters:
    ///   - echoCancellation: Enable/disable echo cancellation. Default: true
    ///   - noiseSuppression: Enable/disable noise suppression. Default: true
    ///   - autoGainControl: Enable/disable automatic gain control. Default: true
    public init(echoCancellation: Bool = true,
                noiseSuppression: Bool = true,
                autoGainControl: Bool = true) {
        self.echoCancellation = echoCancellation
        self.noiseSuppression = noiseSuppression
        self.autoGainControl = autoGainControl
    }
}