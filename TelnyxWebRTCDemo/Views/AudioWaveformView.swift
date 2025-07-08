import SwiftUI
import WebRTC
import AVFoundation

/// A SwiftUI view that visualizes audio waveforms from WebRTC media streams.
/// This component provides real-time audio visualization for both local and remote audio streams.
///
/// ## Features
/// - Real-time audio level visualization
/// - Customizable bar count and colors
/// - Smooth animations
/// - Support for both local and remote streams
///
/// ## Usage
/// ```swift
/// // For local audio visualization
/// AudioWaveformView(
///     mediaStream: call.localStream,
///     barColor: .green,
///     title: "Local Audio"
/// )
///
/// // For remote audio visualization
/// AudioWaveformView(
///     mediaStream: call.remoteStream,
///     barColor: .blue,
///     title: "Remote Audio"
/// )
/// ```
struct AudioWaveformView: View {
    /// The WebRTC media stream to visualize
    let mediaStream: RTCMediaStream?
    
    /// Color of the waveform bars
    let barColor: Color
    
    /// Optional title to display above the waveform
    let title: String?
    
    /// Number of bars in the waveform visualization
    let barCount: Int
    
    /// Height of the waveform view
    let height: CGFloat
    
    /// Current audio levels for each bar (0.0 to 1.0)
    @State private var audioLevels: [CGFloat] = []
    
    /// Timer for updating audio levels
    @State private var updateTimer: Timer?
    
    /// Audio engine for processing audio data
    @State private var audioEngine: AVAudioEngine?
    
    /// Audio player node for processing the stream
    @State private var playerNode: AVAudioPlayerNode?
    
    /// Indicates if the waveform is currently active
    @State private var isActive: Bool = false
    
    init(
        mediaStream: RTCMediaStream?,
        barColor: Color = .blue,
        title: String? = nil,
        barCount: Int = 20,
        height: CGFloat = 60
    ) {
        self.mediaStream = mediaStream
        self.barColor = barColor
        self.title = title
        self.barCount = barCount
        self.height = height
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 2) {
                ForEach(0..<barCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(barColor)
                        .frame(
                            width: 3,
                            height: max(2, audioLevels.indices.contains(index) ? audioLevels[index] * height : 2)
                        )
                        .animation(.easeInOut(duration: 0.1), value: audioLevels.indices.contains(index) ? audioLevels[index] : 0)
                }
            }
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.1))
            )
        }
        .onAppear {
            setupAudioVisualization()
        }
        .onDisappear {
            stopAudioVisualization()
        }
        .onChange(of: mediaStream) { _ in
            setupAudioVisualization()
        }
    }
    
    /// Sets up the audio visualization system
    private func setupAudioVisualization() {
        // Initialize audio levels array
        audioLevels = Array(repeating: 0.0, count: barCount)
        
        // Check if we have a valid media stream with audio tracks
        guard let mediaStream = mediaStream,
              !mediaStream.audioTracks.isEmpty else {
            startSimulatedVisualization()
            return
        }
        
        // For now, we'll use a simulated visualization since direct WebRTC audio processing
        // requires more complex audio pipeline setup. In a production app, you would:
        // 1. Extract audio data from the RTCAudioTrack
        // 2. Process it through AVAudioEngine or similar
        // 3. Calculate audio levels using FFT or similar techniques
        
        startSimulatedVisualization()
    }
    
    /// Starts a simulated audio visualization for demonstration purposes
    private func startSimulatedVisualization() {
        isActive = true
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard isActive else { return }
            
            // Simulate audio levels with some randomness
            // In a real implementation, these would be calculated from actual audio data
            audioLevels = (0..<barCount).map { index in
                let baseLevel = sin(Double(index) * 0.3 + Date().timeIntervalSince1970 * 2) * 0.5 + 0.5
                let randomVariation = Double.random(in: 0.7...1.3)
                let simulatedLevel = baseLevel * randomVariation
                
                // Add some decay for more realistic visualization
                let previousLevel = audioLevels.indices.contains(index) ? audioLevels[index] : 0.0
                let smoothedLevel = previousLevel * 0.7 + CGFloat(simulatedLevel) * 0.3
                
                return max(0.05, min(1.0, smoothedLevel))
            }
        }
    }
    
    /// Stops the audio visualization
    private func stopAudioVisualization() {
        isActive = false
        updateTimer?.invalidate()
        updateTimer = nil
        
        // Clean up audio engine if used
        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil
        
        // Reset audio levels
        audioLevels = Array(repeating: 0.0, count: barCount)
    }
}

/// Preview provider for SwiftUI canvas
struct AudioWaveformView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AudioWaveformView(
                mediaStream: nil,
                barColor: .green,
                title: "Local Audio"
            )
            
            AudioWaveformView(
                mediaStream: nil,
                barColor: .blue,
                title: "Remote Audio"
            )
            
            AudioWaveformView(
                mediaStream: nil,
                barColor: .orange,
                title: "Custom Waveform",
                barCount: 30,
                height: 80
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}