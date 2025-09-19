import SwiftUI
import TelnyxRTC

struct CallView: View {
    @ObservedObject var viewModel: CallViewModel
    @State var isPhoneNumber: Bool
    @State private var showCallHistory = false

    let onStartCall: () -> Void
    let onEndCall: () -> Void
    let onRejectCall: () -> Void
    let onAnswerCall: () -> Void
    let onMuteUnmuteSwitch: (Bool) -> Void
    let onToggleSpeaker: () -> Void
    let onHold: (Bool) -> Void
    let onDTMF: (String) -> Void
    let onRedial: ((String) -> Void)?
    let onIceRestart: () -> Void
    let onResetAudio: () -> Void
    

    var body: some View {
        VStack {
            switch viewModel.callState {
                case .DONE(let reason):
                    callView
                case .NEW:
                    incomingCallView
                case .ACTIVE, .HELD, .CONNECTING, .RINGING, .RECONNECTING, .DROPPED:
                    callingView
            }
        }
        .sheet(isPresented: $viewModel.showDTMFKeyboard) {
            VStack {
                DTMFKeyboardView(
                    viewModel: DTMFKeyboardViewModel(),
                    onClose: { viewModel.showDTMFKeyboard = false },
                    onDTMF: { key in
                        onDTMF(key)
                    }
                )
                .background(Color.white)
            }
            .ignoresSafeArea(edges: .bottom)
        }.sheet(isPresented: $viewModel.showCallMetricsPopup) {
            if let metrics = viewModel.callQualityMetrics {
                CallQualityMetricsView(
                    metrics: metrics,
                    onClose: {
                        viewModel.showCallMetricsPopup = false
                    }
                )
            }
        }.sheet(isPresented: $showCallHistory) {
            CallHistoryBottomSheet(
                profileId: CallHistoryManager.shared.currentProfileId,
                onRedial: { phoneNumber, callerName in
                    viewModel.sipAddress = phoneNumber
                    onRedial?(phoneNumber)
                },
                onClearHistory: {
                    // History cleared
                }
            )
        }
    }
    
    @ViewBuilder
    private var callView: some View {
        VStack {
            DestinationToggle(
                isFirstOptionSelected: $isPhoneNumber,
                firstOption: "Sip address",
                secondOption: "Phone number"
            )
            .padding(.horizontal, 30)
            
            if isPhoneNumber {
                VStack {
                    TextField("Enter Phone number", text: $viewModel.sipAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("+") {
                                    viewModel.sipAddress += "+"
                                }
                                .font(.title)
                                .foregroundColor(.black)
                                Spacer()
                            }
                        }
                        .accessibilityIdentifier(AccessibilityIdentifiers.numberToCallTextField)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 8)
            } else {
                VStack {
                    TextField("Enter Sip address", text: $viewModel.sipAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .accessibilityIdentifier(AccessibilityIdentifiers.numberToCallTextField)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 8)
            }

            VStack(spacing: 20) {
                // Call History Button
          
                // Call Button
                Button(action: {
                    onStartCall()
                }) {
                    Image("Call")
                        .foregroundColor(Color(hex: "#1D1D1D"))
                        .frame(width: 60, height: 60)
                        .background(Color(hex: "#00E3AA"))
                        .clipShape(Circle())
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.callButton)
            }
            .padding()
         
            
            Button(action: {
                showCallHistory = true
            }) {
                Text("Call History")
                    .font(.body)
                    .foregroundColor(Color(hex: "#1D1D1D"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color(hex: "#1D1D1D"), lineWidth: 2)
                    )
                    .accessibilityIdentifier("callHistoryButton")
            }

            // Keep Keyboard below Textfiled
            Spacer().frame(height: 100)
        }
    }
    
    @ViewBuilder
    private var callingView: some View {
        VStack {
            TextField("Enter sip address or phone number", text: $viewModel.sipAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 30)
                .padding(.vertical, 8)
                .disabled(true)
                .opacity(0.5)
             // MARK: - Audio Waveform Visualization Section
            // This section displays real-time audio waveforms using lists of audio levels
            // The waveforms show inbound and outbound audio levels collected over time
            VStack(spacing: 12) {
                AudioWaveformView(
                    audioLevels: viewModel.inboundAudioLevels,
                    barColor: .green,
                    title: "Inbound Audio",
                    minBarHeight: 3.0,
                    maxBarHeight: 40.0
                )
                
                AudioWaveformView(
                    audioLevels: viewModel.outboundAudioLevels,
                    barColor: .blue,
                    title: "Outbound Audio",
                    minBarHeight: 3.0,
                    maxBarHeight: 40.0
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.08))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            .padding(.horizontal, 16)
                        
            GeometryReader { geometry in
                VStack(spacing: 16) {
                    // Primera fila - Botones principales (4 botones)
                    HStack(spacing: max(8, (geometry.size.width - 300) / 6)) {
                        Button(action: {
                            viewModel.isMuted.toggle()
                            onMuteUnmuteSwitch(viewModel.isMuted)
                        }) {
                            Image(systemName: viewModel.isMuted ? "mic.slash.fill" : "mic.fill")
                                .foregroundColor(Color(hex: "#1D1D1D"))
                                .frame(width: 60, height: 60)
                                .background(Color(hex: "#F5F3E4"))
                                .clipShape(Circle())
                        }
                        .accessibilityIdentifier(AccessibilityIdentifiers.muteButton)
                        
                        Button(action: {
                            viewModel.isSpeakerOn.toggle()
                            onToggleSpeaker()
                        }) {
                            Image(systemName: viewModel.isSpeakerOn ? "speaker.wave.3.fill" : "speaker.slash.fill")
                                .foregroundColor(Color(hex: "#1D1D1D"))
                                .frame(width: 60, height: 60)
                                .background(Color(hex: "#F5F3E4"))
                                .clipShape(Circle())
                        }
                        .accessibilityIdentifier(AccessibilityIdentifiers.speakerButton)

                        Button(action: {
                            viewModel.isOnHold.toggle()
                            onHold(viewModel.isOnHold)
                        }) {
                            Image(systemName: viewModel.isOnHold ? "play.fill" : "pause")
                                .foregroundColor(Color(hex: "#1D1D1D"))
                                .frame(width: 60, height: 60)
                                .background(Color(hex: "#F5F3E4"))
                                .clipShape(Circle())
                        }
                        .accessibilityIdentifier(AccessibilityIdentifiers.holdButton)

                        Button(action: {
                            viewModel.showDTMFKeyboard.toggle()
                        }) {
                            Image(systemName: "circle.grid.3x3.fill")
                                .foregroundColor(Color(hex: "#1D1D1D"))
                                .frame(width: 60, height: 60)
                                .background(Color(hex: "#F5F3E4"))
                                .clipShape(Circle())
                        }
                        .accessibilityIdentifier(AccessibilityIdentifiers.dtmfButton)
                    }
                    
                    // Segunda fila - Botones adicionales (3 botones centrados)
                    HStack(spacing: max(8, (geometry.size.width - 200) / 4)) {
                        Spacer()
                        
                        Button(action: {
                            viewModel.showCallMetricsPopup.toggle()
                        }) {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(Color(hex: "#1D1D1D"))
                                .frame(width: 60, height: 60)
                                .background(Color(hex: "#F5F3E4"))
                                .clipShape(Circle())
                        }
                        .accessibilityIdentifier("callMetricsButton")
                        
                        Button(action: {
                            onIceRestart()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(Color(hex: "#1D1D1D"))
                                .frame(width: 60, height: 60)
                                .background(Color(hex: "#F5F3E4"))
                                .clipShape(Circle())
                        }
                        .accessibilityIdentifier("iceRestartButton")
                        
                        Button(action: {
                            onResetAudio()
                        }) {
                            Image(systemName: "waveform.and.magnifyingglass")
                                .foregroundColor(Color(hex: "#1D1D1D"))
                                .frame(width: 60, height: 60)
                                .background(Color(hex: "#F5F3E4"))
                                .clipShape(Circle())
                        }
                        .accessibilityIdentifier("resetAudioButton")
                        
                        Spacer()
                    }
                }
            }
            .frame(height: 160)
            
            Button(action: {
                onEndCall()
            }) {
                Image(systemName: "phone.down.fill")
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color(hex: "#EB0000"))
                    .clipShape(Circle())
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.hangupButton)
            .padding()
            
            Spacer()
        }
    }

    @ViewBuilder
    private var incomingCallView: some View {
        VStack {
            Spacer()
            
            HStack {
                Button(action: {
                    onRejectCall()
                }) {
                    Image("ic-hangup")
                        .foregroundColor(Color(hex: "#1D1D1D"))
                        .frame(width: 60, height: 60)
                        .background(Color(hex: "#EB0000"))
                        .clipShape(Circle())
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.rejectButton)
                .padding()

                Button(action: {
                    onAnswerCall()
                }) {
                    Image("Call")
                        .foregroundColor(Color(hex: "#1D1D1D"))
                        .frame(width: 60, height: 60)
                        .background(Color(hex: "#00E3AA"))
                        .clipShape(Circle())
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.answerButton)
                .padding()
            }
            
            Spacer()
        }
    }
}

struct CallView_Previews: PreviewProvider {
    static var previews: some View {
        CallView(
            viewModel: CallViewModel(), isPhoneNumber: true,
            onStartCall: {},
            onEndCall: {},
            onRejectCall: {},
            onAnswerCall: {},
            onMuteUnmuteSwitch: { _ in },
            onToggleSpeaker: {},
            onHold: { _ in },
            onDTMF: { _ in },
            onRedial: { _ in },
            onIceRestart: {},
            onResetAudio: {}
        )
    }
}
