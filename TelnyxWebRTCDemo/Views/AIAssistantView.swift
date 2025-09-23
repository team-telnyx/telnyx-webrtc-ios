//
//  AIAssistantView.swift
//  TelnyxWebRTCDemo
//
//  Created by AI SWE Agent on 31/07/2025.
//

import SwiftUI
import TelnyxRTC

struct AIAssistantView: View {
    @ObservedObject var viewModel: AIAssistantViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "brain")
                        .font(.system(size: 30))
                        .foregroundColor(Color(hex: "#00E3AA"))
                    
                    Text("AI Assistant")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "#1D1D1D"))
                    
                    Text("Connect to an AI Assistant for intelligent conversations")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(hex: "#525252"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Connection Status
                VStack(spacing: 15) {
                    Text("Connection Status")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "#1D1D1D"))
                    
                    HStack {
                        Circle()
                            .fill(viewModel.isConnected ? Color(hex: "00E3AA") : Color(hex: "D40000"))
                            .frame(width: 12, height: 12)
                        
                        Text(viewModel.connectionStatusText)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color(hex: "#1D1D1D"))
                    }
                    
                    if let sessionId = viewModel.sessionId, !sessionId.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Session ID")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "#525252"))
                            
                            Text(sessionId)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color(hex: "#1D1D1D"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 30)
                
                // Call State
                if viewModel.isConnected {
                    VStack(spacing: 15) {
                        Text("Call State")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "#1D1D1D"))
                        
                        let stateInfo = callStateInfo(for: viewModel.callState)
                        HStack {
                            Circle()
                                .fill(stateInfo.color)
                                .frame(width: 12, height: 12)
                            
                            Text(stateInfo.text)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(Color(hex: "#1D1D1D"))
                        }
                    }
                    .padding(.horizontal, 30)
                }
                
                // Widget Settings Display
                if let widgetSettings = viewModel.widgetSettings {
                    VStack(spacing: 10) {
                        Text("Assistant Configuration")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "#1D1D1D"))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            if let theme = widgetSettings.theme {
                                HStack {
                                    Text("Theme:")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(hex: "#525252"))
                                    Text(theme)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(Color(hex: "#1D1D1D"))
                                }
                            }
                            
                            if let language = widgetSettings.language {
                                HStack {
                                    Text("Language:")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(hex: "#525252"))
                                    Text(language)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(Color(hex: "#1D1D1D"))
                                }
                            }
                            
                            HStack {
                                Text("Auto Start:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "#525252"))
                                Text(widgetSettings.autoStart ? "Yes" : "No")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color(hex: "#1D1D1D"))
                            }
                            
                            HStack {
                                Text("Show Transcript:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "#525252"))
                                Text(widgetSettings.showTranscript ? "Yes" : "No")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color(hex: "#1D1D1D"))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 30)
                }
                
                Spacer()
                
                // Target ID Input (when not connected)
                if !viewModel.isConnected {
                    VStack(spacing: 15) {
                        Text("Assistant Target ID")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "#1D1D1D"))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Enter Target ID", text: $viewModel.targetIdInput)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 16))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            Text("Enter the Target ID for the AI Assistant you want to connect to.")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color(hex: "#525252"))
                        }
                    }
                    .padding(.horizontal, 30)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 15) {
                    if !viewModel.isConnected {
                        Button(action: {
                            viewModel.connectToAssistant()
                        }) {
                            Text("Connect to Assistant")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    viewModel.targetIdInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                                    Color.gray : Color(hex: "#00E3AA")
                                )
                                .cornerRadius(25)
                        }
                        .disabled(viewModel.isLoading || viewModel.targetIdInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    } else {
                        // Call Controls
                        if viewModel.callState == .NEW || viewModel.callState == .DONE(reason: nil) {
                            Button(action: {
                                viewModel.startAssistantCall()
                            }) {
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text("Call Assistant")
                                }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(hex: "#00E3AA"))
                                .cornerRadius(25)
                            }
                            .disabled(viewModel.isLoading)
                        } else if viewModel.callState == .ACTIVE {
                            HStack(spacing: 15) {
                                Button(action: {
                                    viewModel.showTranscriptDialog = true
                                }) {
                                    HStack {
                                        Image(systemName: "text.bubble")
                                        Text("Transcript")
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color(hex: "#3434EF"))
                                    .cornerRadius(20)
                                }
                                
                                Button(action: {
                                    viewModel.endCall()
                                }) {
                                    HStack {
                                        Image(systemName: "phone.down.fill")
                                        Text("End Call")
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color(hex: "#D40000"))
                                    .cornerRadius(20)
                                }
                            }
                        } else {
                            Button(action: {
                                viewModel.endCall()
                            }) {
                                HStack {
                                    Image(systemName: "phone.down.fill")
                                    Text("End Call")
                                }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(hex: "#D40000"))
                                .cornerRadius(25)
                            }
                        }
                        
                        Button(action: {
                            viewModel.disconnect()
                        }) {
                            Text("Disconnect")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "#D40000"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color(hex: "#D40000"), lineWidth: 1)
                                )
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
                }
            }
            .background(Color(hex: "#FEFDF5"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // Disconnect from socket when pressing Back button
                        viewModel.disconnect()
                        viewModel.restoreHomeDelegate()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(Color(hex: "#1D1D1D"))
                    }
                }
            }
        }
        .onDisappear {
            // Ensure delegate is restored when view disappears
            // This breaks the retain cycle before deinit
            viewModel.restoreHomeDelegate()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $viewModel.showTranscriptDialog) {
            TranscriptDialogView(viewModel: viewModel)
                .interactiveDismissDisabled(true)
        }
        .overlay(
            Group {
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#00E3AA")))
                            .scaleEffect(1.5)
                        
                        Text(viewModel.loadingMessage)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#1D1D1D"))
                            .padding(.top, 20)
                    }
                }
            }
        )
    }
    
    private func callStateInfo(for state: CallState) -> (color: Color, text: String) {
        switch state {
        case .DONE(let reason):
            if let reason = reason, let cause = reason.cause {
                return (Color.gray, "DONE - \(cause)")
            }
            return (Color.gray, "DONE")
        case .RINGING:
            return (Color(hex: "#3434EF"), "Ringing")
        case .CONNECTING:
            return (Color(hex: "#008563"), "Connecting")
        case .DROPPED(let reason):
            return (Color(hex: "#D40000"), "Dropped - \(reason.rawValue)")
        case .RECONNECTING(let reason):
            return (Color(hex: "#CF7E20"), "Reconnecting - \(reason.rawValue)")
        case .ACTIVE:
            return (Color(hex: "#008563"), "Active")
        case .NEW:
            return (Color.black, "New")
        case .HELD:
            return (Color(hex: "#008563"), "Held")
        }
    }
}

struct AIAssistantView_Previews: PreviewProvider {
    static var previews: some View {
        AIAssistantView(viewModel: AIAssistantViewModel())
    }
}