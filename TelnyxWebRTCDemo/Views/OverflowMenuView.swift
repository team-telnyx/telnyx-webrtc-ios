//
//  OverflowMenuView.swift
//  TelnyxRTC
//
//  Created by Isaac Akakpo on 2025-06-19.
//


import SwiftUI
import TelnyxRTC

struct OverflowMenuView: View {
    @Binding var showMenu: Bool
    @Binding var showPreCallDiagnosisSheet: Bool
    @Binding var showRegionMenu: Bool
    @Binding var selectedRegion: Region
    @Binding var showAIAssistant: Bool
    @Binding var showCodecSelection: Bool
    @Binding var showWebSocketMessages: Bool
    @ObservedObject var viewModel: HomeViewModel


    var body: some View {
        if showMenu {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { showMenu = false }

            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 10) {
                    MenuButton(
                        title: "Websocket Messages",
                        icon: "message.circle",
                        isDisabled: false
                    ) {
                        showMenu = false
                        showWebSocketMessages = true
                    }
                    MenuButton(
                        title: "AI Assistant",
                        icon: "brain",
                        isDisabled: viewModel.isAIAssistantDisabled
                    ) {
                        if !viewModel.isAIAssistantDisabled {
                            showMenu = false
                            showAIAssistant = true
                        }
                    }
                    MenuButton(
                        title: "Pre-call Diagnosis",
                        icon: "waveform.path.ecg",
                        isDisabled: viewModel.isPreCallDiagnosisDisabled
                    ) {
                        if !viewModel.isPreCallDiagnosisDisabled {
                            showMenu = false
                            showPreCallDiagnosisSheet = true
                        }
                    }
                    MenuButton(
                        title: "Audio Codecs",
                        icon: "waveform",
                        isDisabled: viewModel.isRegionSelectionDisabled
                    ) {
                        if !viewModel.isRegionSelectionDisabled {
                            showMenu = false
                            showCodecSelection = true
                        }
                    }
                    MenuButton(
                        title: "Region: \(selectedRegion.rawValue)",
                        icon: "globe",
                        isDisabled: viewModel.isRegionSelectionDisabled
                    ) {
                        if !viewModel.isRegionSelectionDisabled {
                            showMenu = false
                            showRegionMenu = true
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 10)
                .padding()
            }
        }
    }
}

struct MenuButton: View {
    var title: String
    var icon: String
    var isDisabled: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .foregroundColor(isDisabled ? .gray : .primary)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(isDisabled ? 0.05 : 0.1))
            .cornerRadius(8)
        }
        .disabled(isDisabled)
    }
}
