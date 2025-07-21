import SwiftUI
import TelnyxRTC

/// A SwiftUI view that visualizes audio waveforms using current audio levels.
/// This component provides sharp, realistic audio visualization matching the Android implementation.
/// 
/// Unlike a scrolling timeline, this creates a fixed-width waveform that shows the current
/// audio level distributed across frequency bands, similar to an audio equalizer.
///
/// ## Features
/// - Real-time audio level visualization using current audio data
/// - Fixed-width bars that represent frequency distribution
/// - Sharp, responsive waveform animation
/// - Matches Android AudioWaveform behavior with `weight(1f)` and `Arrangement.SpaceBetween`
///
/// ## Usage
/// ```swift
/// // Using current audio level from CallViewModel
/// AudioWaveformView(
///     audioLevels: [viewModel.currentInboundAudioLevel],
///     barColor: .green,
///     title: "Inbound Audio"
/// )
///
/// // Using current audio level from CallViewModel
/// AudioWaveformView(
///     audioLevels: [viewModel.currentOutboundAudioLevel],
///     barColor: .blue,
///     title: "Outbound Audio"
/// )
/// ```
struct AudioWaveformView: View {
    /// Array of audio levels (0.0 to 1.0) for each bar
    let audioLevels: [Float]

    /// Color of the waveform bars
    let barColor: Color

    /// Optional title to display above the waveform
    let title: String?

    /// Minimum bar height in points
    let minBarHeight: CGFloat

    /// Maximum bar height in points
    let maxBarHeight: CGFloat

    /// State to track previous levels for smooth decay
    @State private var displayLevels: [Float] = []

    /// Timer for decay animation
    @State private var decayTimer: Timer?

    init(
        audioLevels: [Float],
        barColor: Color = .blue,
        title: String? = nil,
        minBarHeight: CGFloat = 2.0,
        maxBarHeight: CGFloat = 50.0
    ) {
        self.audioLevels = audioLevels
        self.barColor = barColor
        self.title = title
        self.minBarHeight = minBarHeight
        self.maxBarHeight = maxBarHeight
    }

    var body: some View {
        VStack(spacing: 4) {
            if let title = title {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 1) {
                let frequencyBands = generateFrequencyBands(from: audioLevels)

                ForEach(frequencyBands.indices, id: \.self) { index in
                    let currentDisplayLevel = displayLevels.indices.contains(index) ? displayLevels[index] : 0.0
                    let clampedLevel = max(0.0, min(1.0, CGFloat(currentDisplayLevel)))

                    let barHeight = clampedLevel > 0
                        ? max(minBarHeight, minBarHeight + (clampedLevel * (maxBarHeight - minBarHeight)))
                        : minBarHeight

                    RoundedRectangle(cornerRadius: 1)
                        .fill(clampedLevel > 0.01 ? barColor : barColor.opacity(0.1))
                        .frame(width: 2, height: barHeight)
                        .animation(.easeOut(duration: 0.05), value: barHeight)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: maxBarHeight)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.1))
            )
        }
        .onAppear {
            initializeDisplayLevels()
            startDecayTimer()
        }
        .onDisappear {
            stopDecayTimer()
        }
        .onChange(of: audioLevels) { _ in
            updateDisplayLevels()
        }
    }

    /// Initialize display levels array
    private func initializeDisplayLevels() {
        let frequencyBands = generateFrequencyBands(from: audioLevels)
        if displayLevels.isEmpty {
            displayLevels = Array(repeating: 0.0, count: frequencyBands.count)
        }
    }

    /// Generates frequency bands from the current audio level array
    private func generateFrequencyBands(from audioLevels: [Float]) -> [Float] {
        let currentLevel = audioLevels.last ?? 0.0
        let barCount = 80
        var frequencyBands: [Float] = []

        for i in 0..<barCount {
            let normalizedIndex = Float(i) / Float(barCount - 1)
            let frequencyLevel = generateFrequencyLevel(
                currentLevel: currentLevel,
                frequencyIndex: normalizedIndex
            )
            frequencyBands.append(frequencyLevel)
        }

        return frequencyBands
    }

    /// Generates a frequency level for a specific frequency band
    private func generateFrequencyLevel(currentLevel: Float, frequencyIndex: Float) -> Float {
        guard currentLevel > 0.0 else { return 0.0 }

        let lowFreqWeight = 1.0 - (frequencyIndex * 0.6)
        let randomVariation = Float.random(in: 0.7...1.3)
        let frequencyResponse = currentLevel * lowFreqWeight * randomVariation

        return frequencyResponse > 0.05 ? min(1.0, frequencyResponse) : 0.0
    }

    /// Updates display levels with immediate rise and fast decay
    private func updateDisplayLevels() {
        let frequencyBands = generateFrequencyBands(from: audioLevels)

        // Ensure displayLevels array matches the size
        if displayLevels.count != frequencyBands.count {
            displayLevels = Array(repeating: 0.0, count: frequencyBands.count)
        }

        // Update display levels with immediate rise behavior
        for i in 0..<frequencyBands.count {
            let targetLevel = frequencyBands[i]
            let currentLevel = displayLevels[i]

            // Immediate rise, no decay here (handled by timer)
            if targetLevel > currentLevel {
                displayLevels[i] = targetLevel
            }
        }
    }

    /// Starts the decay timer for smooth bar retraction
    private func startDecayTimer() {
        decayTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            withAnimation(.easeOut(duration: 0.05)) {
                applyDecay()
            }
        }
    }

    /// Stops the decay timer
    private func stopDecayTimer() {
        decayTimer?.invalidate()
        decayTimer = nil
    }

    /// Applies fast decay to display levels
    private func applyDecay() {
        let decayRate: Float = 0.85 // Fast decay - adjust between 0.8-0.9 for different speeds

        for i in 0..<displayLevels.count {
            displayLevels[i] *= decayRate

            // Set to zero if very low to avoid floating point precision issues
            if displayLevels[i] < 0.01 {
                displayLevels[i] = 0.0
            }
        }
    }
}
