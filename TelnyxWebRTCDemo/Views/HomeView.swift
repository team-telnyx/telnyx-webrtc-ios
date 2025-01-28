import SwiftUI

enum SocketState {
    case connected
    case disconnected
}

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    @State private var isAnimating: Bool = false
    @State private var textOpacity: Double = 0.0
    
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    let onLongPressLogo: () -> Void
    
    let profileView: AnyView
    let callView: AnyView
    
    var body: some View {
        ZStack {
            VStack {
                GeometryReader { geometry in
                    VStack {
                        Spacer().frame(height: isAnimating ? 50 : (geometry.size.height / 2 - 100))
                        Image("telnyx-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200)
                            .onLongPressGesture {
                                onLongPressLogo()
                            }
                        Spacer().frame(height: isAnimating ? 0 : (geometry.size.height / 2 - 100))
                        
                        if isAnimating {
                            VStack {
                                Text("Please confirm details below and click ‘Connect’ to make a call.")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundColor(Color(hex: "1D1D1D"))
                                    .padding(.top, 20)
                                    .padding(20)
                                
                                // Socket State
                                VStack {
                                    Text("Socket")
                                        .font(.system(size: 18, weight: .regular))
                                        .foregroundColor(Color(hex: "#525252"))
                                        .padding(.top, 10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    HStack {
                                        Circle()
                                            .fill(viewModel.socketState == .connected ? Color(hex: "00E3AA") : Color(hex: "D40000"))
                                            .frame(width: 8, height: 8)
                                        Text(viewModel.socketState == .connected ? "Connected" : "Disconnected")
                                            .font(.system(size: 18, weight: .regular))
                                            .foregroundColor(Color(hex: "1D1D1D"))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 5)
                                }
                                .padding(.leading, 30)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Session
                                VStack {
                                    Text("Session ID")
                                        .font(.system(size: 18, weight: .regular))
                                        .foregroundColor(Color(hex: "#525252"))
                                        .padding(.top, 10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Text(viewModel.sessionId)
                                        .font(.system(size: 18, weight: .regular))
                                        .foregroundColor(Color(hex: "1D1D1D"))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.leading, 30)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Profile or Call view
                                profileOrCallView(for: viewModel.socketState)
                                
                                Spacer()
                                
                                if viewModel.socketState == .disconnected {
                                    Button(action: onConnect) {
                                        Text("Connect")
                                            .font(.system(size: 16).bold())
                                            .foregroundColor(.white)
                                            .frame(maxWidth: 300)
                                            .padding(.vertical, 12)
                                            .background(Color(hex: "#1D1D1D"))
                                            .cornerRadius(20)
                                    }
                                    .padding(.horizontal, 60)
                                    .padding(.bottom, 20)
                                } else {
                                    Button(action: onDisconnect) {
                                        Text("Disconnect")
                                            .font(.system(size: 16).bold())
                                            .foregroundColor(.white)
                                            .frame(maxWidth: 300)
                                            .padding(.vertical, 12)
                                            .background(Color(hex: "#1D1D1D"))
                                            .cornerRadius(20)
                                    }
                                    .padding(.horizontal, 60)
                                    .padding(.bottom, 20)
                                }
                                
                                
                                // Environment Text
                                Text(viewModel.environment)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color(hex: "1D1D1D"))
                                    .padding(.bottom, 20)
                            }
                            .opacity(textOpacity)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            isAnimating = true
                        }
                        withAnimation(.easeInOut(duration: 1.0).delay(1.0)) {
                            textOpacity = 1.0
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            
            if viewModel.isLoading {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#00E3AA")))
                        .scaleEffect(1.5)
                }
            }
        }
    }
    
    @ViewBuilder
    private func profileOrCallView(for state: SocketState) -> some View {
        switch state {
            case .disconnected:
                profileView
            case .connected:
                callView
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(
            viewModel: HomeViewModel(),
            onConnect: {},
            onDisconnect: {},
            onLongPressLogo: {},
            profileView: AnyView(
                ProfileView(
                    viewModel: ProfileViewModel(),
                    onAddProfile: {},
                    onSwitchProfile: {})),
            callView: AnyView(
                CallView(
                    viewModel: CallViewModel(),
                    onStartCall: {},
                    onEndCall: {},
                    onMuteUnmuteSwitch: { _ in },
                    onToggleSpeaker: { _ in }))
        )
    }
}

