//
//  CodecSelectionView.swift
//  TelnyxRTC
//
//  Created by AI SWE Agent on 08/10/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import SwiftUI
import TelnyxRTC

struct CodecSelectionView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: HomeViewModel

    @State private var availableCodecs: [TxCodecCapability] = []
    @State private var selectedCodecs: [TxCodecCapability] = []

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

                    Text("Preferred Audio Codecs")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "#1D1D1D"))

                    Spacer()

                    Button("Save") {
                        saveCodecs()
                        isPresented = false
                    }
                    .foregroundColor(Color(hex: "#00E3AA"))
                }
                .padding()
                .background(Color.white)

                Divider()

                // Description
                Text("Select your preferred audio codecs for calls. The selected codecs will be attempted as preference during call negotiation.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#525252"))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Codec List
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(availableCodecs) { codec in
                            CodecRow(
                                codec: codec,
                                isSelected: selectedCodecs.contains(codec),
                                onToggle: { toggleCodec(codec) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color(hex: "#FEFDF5"))
            .onAppear {
                loadCodecs()
            }
        }
    }

    private func loadCodecs() {
        // Get available codecs from SDK using AppDelegate
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let txClient = appDelegate.telnyxClient else {
            return
        }
        availableCodecs = txClient.getSupportedAudioCodecs()

        // Load previously selected codecs from storage
        selectedCodecs = viewModel.getPreferredAudioCodecs()
    }

    private func toggleCodec(_ codec: TxCodecCapability) {
        if selectedCodecs.contains(codec) {
            selectedCodecs.removeAll { $0 == codec }
        } else {
            selectedCodecs.append(codec)
        }
    }

    private func saveCodecs() {
        // Save only selected codecs
        viewModel.setPreferredAudioCodecs(selectedCodecs)
    }
}

struct CodecRow: View {
    let codec: TxCodecCapability
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? Color(hex: "#00E3AA") : Color(hex: "#525252"))
                    .font(.system(size: 24))

                // Codec Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(codecName(from: codec.mimeType))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#1D1D1D"))

                    HStack(spacing: 8) {
                        Text("\(codec.clockRate) Hz")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#525252"))

                        if let channels = codec.channels {
                            Text("•")
                                .foregroundColor(Color(hex: "#525252"))
                            Text("\(channels) ch")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#525252"))
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func codecName(from mimeType: String) -> String {
        // Extract codec name from MIME type (e.g., "audio/opus" -> "Opus")
        let components = mimeType.split(separator: "/")
        guard components.count == 2 else { return mimeType }
        return String(components[1]).capitalized
    }
}

struct CodecSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        CodecSelectionView(
            isPresented: .constant(true),
            viewModel: HomeViewModel()
        )
    }
}
