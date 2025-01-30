import SwiftUI
import TelnyxRTC

struct CallView: View {
    @ObservedObject var viewModel: CallViewModel
    
    let onStartCall: () -> Void
    let onEndCall: () -> Void
    let onRejectCall: () -> Void
    let onAnswerCall: () -> Void
    let onMuteUnmuteSwitch: (Bool) -> Void
    let onToggleSpeaker: () -> Void
    let onHold: (Bool) -> Void

    var body: some View {
        VStack {
            switch viewModel.callState {
                case .DONE:
                    callView
                case .NEW:
                    incomingCallView
                case .ACTIVE, .HELD, .CONNECTING, .RINGING:
                    callingView
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var callView: some View {
        VStack {
            TextField("Enter sip address or phone number", text: $viewModel.sipAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Spacer()
            
            Button(action: {
                onStartCall()
            }) {
                Image(systemName: "phone.fill")
                    .foregroundColor(Color(hex: "#1D1D1D"))
                    .frame(width: 60, height: 60)
                    .background(Color(hex: "#00E3AA"))
                    .clipShape(Circle())
            }
            .padding()
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var callingView: some View {
        VStack {
            TextField("Enter sip address or phone number", text: $viewModel.sipAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .disabled(true)
                .opacity(0.5)
            
            Spacer()
            
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
                .padding() 
               
                
                Button(action: {
                    onToggleSpeaker()
                }) {
                    Image(systemName: viewModel.isSpeakerOn ? "speaker.wave.3.fill" : "speaker.slash.fill")
                        .foregroundColor(Color(hex: "#1D1D1D"))
                        .frame(width: 60, height: 60)
                        .background(Color(hex: "#F5F3E4"))
                        .clipShape(Circle())
                }
                .padding()

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
                .padding()
            }

             Button(action: {
                    onEndCall()
                }) {
                    Image(systemName: "phone.down.fill")
                        .foregroundColor(Color(hex: "#1D1D1D"))
                        .frame(width: 60, height: 60)
                        .background(Color(hex: "#EB0000"))
                        .clipShape(Circle())
                }
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
                    Image(systemName: "phone.down.fill")
                        .foregroundColor(Color(hex: "#1D1D1D"))
                        .frame(width: 60, height: 60)
                        .background(Color(hex: "#EB0000"))
                        .clipShape(Circle())
                }
                .padding()

                Button(action: {
                    onAnswerCall()
                }) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(Color(hex: "#1D1D1D"))
                        .frame(width: 60, height: 60)
                        .background(Color(hex: "#00E3AA"))
                        .clipShape(Circle())
                }
                .padding()
            }
            
            Spacer()
        }
    }
}

struct CallView_Previews: PreviewProvider {
    static var previews: some View {
        CallView(
            viewModel: CallViewModel(),
            onStartCall: {},
            onEndCall: {},
            onRejectCall: {},
            onAnswerCall: {},
            onMuteUnmuteSwitch: { _ in },
            onToggleSpeaker: {},
            onHold: { _ in })
    }
}
