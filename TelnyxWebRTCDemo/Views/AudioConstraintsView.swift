//
//  AudioConstraintsView.swift
//  TelnyxRTC
//
//  Created by Claude Code on 2025-11-25.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import SwiftUI
import TelnyxRTC

struct AudioConstraintsView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: HomeViewModel

    @State private var echoCancellation: Bool = true
    @State private var noiseSuppression: Bool = true
    @State private var autoGainControl: Bool = true

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(Color(hex: "#525252"))

                    Spacer()

                    Text("Audio Processing")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "#1D1D1D"))

                    Spacer()

                    Button("Save") {
                        saveAudioConstraints()
                        isPresented = false
                    }
                    .foregroundColor(Color(hex: "#00E3AA"))
                }
                .padding()
                .background(Color.white)

                Divider()

                // Description
                Text("Configure audio processing constraints for WebRTC calls. These settings control echo cancellation, noise suppression, and automatic gain control.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#525252"))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Constraints List
                ScrollView {
                    VStack(spacing: 12) {
                        AudioConstraintRow(
                            title: "Echo Cancellation",
                            description: "Removes acoustic echo from speaker feedback",
                            icon: "speaker.wave.2.fill",
                            isEnabled: $echoCancellation
                        )

                        AudioConstraintRow(
                            title: "Noise Suppression",
                            description: "Reduces background noise for clearer voice",
                            icon: "waveform.path",
                            isEnabled: $noiseSuppression
                        )

                        AudioConstraintRow(
                            title: "Auto Gain Control",
                            description: "Automatically adjusts microphone volume",
                            icon: "slider.horizontal.3",
                            isEnabled: $autoGainControl
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color(hex: "#FEFDF5"))
            .onAppear {
                loadCurrentConstraints()
            }
        }
    }

    private func loadCurrentConstraints() {
        let constraints = viewModel.getAudioConstraints()
        echoCancellation = constraints.echoCancellation
        noiseSuppression = constraints.noiseSuppression
        autoGainControl = constraints.autoGainControl
    }

    private func saveAudioConstraints() {
        let constraints = AudioConstraints(
            echoCancellation: echoCancellation,
            noiseSuppression: noiseSuppression,
            autoGainControl: autoGainControl
        )
        viewModel.setAudioConstraints(constraints)
    }
}

struct AudioConstraintRow: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isEnabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .foregroundColor(Color(hex: "#00E3AA"))
                .font(.system(size: 24))
                .frame(width: 32)

            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#1D1D1D"))

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#525252"))
            }

            Spacer()

            // Toggle
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#00E3AA")))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct AudioConstraintsView_Previews: PreviewProvider {
    static var previews: some View {
        AudioConstraintsView(
            isPresented: .constant(true),
            viewModel: HomeViewModel()
        )
    }
}
