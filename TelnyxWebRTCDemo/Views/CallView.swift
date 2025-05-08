import SwiftUI
import TelnyxRTC

struct CallView: View {
    @ObservedObject var viewModel: CallViewModel
    @State var isPhoneNumber: Bool

    let onStartCall: () -> Void
    let onEndCall: () -> Void
    let onRejectCall: () -> Void
    let onAnswerCall: () -> Void
    let onMuteUnmuteSwitch: (Bool) -> Void
    let onToggleSpeaker: () -> Void
    let onHold: (Bool) -> Void
    let onDTMF: (String) -> Void
    

    var body: some View {
        VStack {
            switch viewModel.callState {
                case .DONE:
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
                VStack(spacing: 16) {
                    Text("Call Quality Metrics")
                        .font(.headline)

                    HStack {
                        Text("Jitter:")
                        Spacer()
                        Text("\(metrics.jitter, specifier: "%.3f") s")
                    }

                    HStack {
                        Text("MOS:")
                        Spacer()
                        Text("\(metrics.mos, specifier: "%.1f")")
                    }

                    HStack {
                        Text("Quality:")
                        Spacer()
                        Text(metrics.quality.rawValue.capitalized)
                    }

                    Button("Close") {
                        viewModel.showCallMetricsPopup = false
                    }
                    .padding(.top)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .padding()
            }
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
        
           
            
            Spacer()
            
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
            .padding()
            
            //Keep Keyboard above Textfiled
            Spacer().frame(height: 600)
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
                        
            HStack {
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
                
                Button(action: {
                    viewModel.showCallMetricsPopup.toggle()
                }) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(Color(hex: "#1D1D1D"))
                        .frame(width: 60, height: 60)
                        .background(Color(hex: "#F5F3E4"))
                        .clipShape(Circle())
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.dtmfButton)

            }
            
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
            
          
        }
        Spacer()
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
            onDTMF: { _ in }
        )
    }
}
