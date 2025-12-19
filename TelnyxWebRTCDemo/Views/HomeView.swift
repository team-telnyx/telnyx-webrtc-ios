import SwiftUI
import TelnyxRTC

enum SocketState {
    case clientReady
    case connected
    case disconnected
}

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    
    @State private var isAnimating: Bool = false
    @State private var textOpacity: Double = 0.0
    @State private var keyboardHeight: CGFloat = 0
    @State private var scrollToKeyboard: Bool = false
    @State private var showPreCallDiagnosisSheet = false
    @State private var showMenu = false
    @State private var showAIAssistant = false
    @State private var showCodecSelection = false

    @State private var showRegionMenu = false
    @State private var showWebSocketMessages = false
    @StateObject private var aiAssistantViewModel = AIAssistantViewModel()
    
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    let onLongPressLogo: () -> Void
    
    let profileView: AnyView
    let callView: AnyView
    
    var body: some View {
        ScrollViewReader { proxy in
            
            ZStack {
                VStack {
                    // Top Menu Bar
                  
                    GeometryReader { geometry in
                        let safeHeight = max(geometry.size.height / 2 - 100, 0)
                        
                        ScrollView {
                            VStack {
                                Spacer().frame(height: isAnimating ? 50 : safeHeight)
                                
                                HStack {
                                    Spacer()
                                    
                                    Button(action: {
                                        showMenu.toggle()
                                    }) {
                                        Image(systemName: "ellipsis")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(Color(hex: "#1D1D1D"))
                                            .frame(width: 44, height: 44)
                                            .background(Color.white.opacity(0.8))
                                            .clipShape(Circle())
                                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    }
                                    .padding(.trailing, 20)
                                    .padding(.top, 10)
                                }
                                .zIndex(1)
                                
                                Image("telnyx-logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200)
                                    .onLongPressGesture {
                                        onLongPressLogo()
                                    }
                                    .accessibilityIdentifier(AccessibilityIdentifiers.homeViewLogo)
                                
                                
                                if isAnimating {
                                    VStack {
                                        if viewModel.socketState == .connected || viewModel.socketState == .clientReady {
                                            Text("Enter a destination (phone number or SIP user) to initiate your call.")
                                                .font(.system(size: 18, weight: .regular))
                                                .foregroundColor(Color(hex: "1D1D1D"))
                                                .padding(20)
                                        } else {
                                            Text("Please confirm details below and click ‘Connect’ to make a call.")
                                                .font(.system(size: 18, weight: .regular))
                                                .foregroundColor(Color(hex: "1D1D1D"))
                                                .padding(20)
                                        }
                                        statesView()
                                        
                                        // Profile or Call view
                                        profileOrCallView(for: viewModel.socketState)
                                            .padding(.bottom, 16)
                                            .id("keyboard")
                                        
                                        Spacer()
                                    }
                                    .opacity(textOpacity)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, keyboardHeight)
                            .animation(.easeOut(duration: 0.3), value: keyboardHeight)
                            .onChange(of: scrollToKeyboard) { shouldScroll in
                                if shouldScroll {
                                    withAnimation {
                                        proxy.scrollTo("keyboard", anchor: .bottom)
                                    }
                                }
                            }
                            .onAppear {
                                withAnimation(nil) {
                                    isAnimating = true
                                }
                                withAnimation(nil) {
                                    textOpacity = 1.0
                                }
                                setupKeyboardObservers()
                                // Refresh profile and region when view appears
                                profileViewModel.refreshProfile()
                            }
                            .onDisappear {
                                removeKeyboardObservers()
                            }
                        }
                    }
                    if viewModel.callState == .NEW || .DONE(reason: nil) == viewModel.callState {
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
                            .accessibilityIdentifier(AccessibilityIdentifiers.connectButton)
                            .padding(.horizontal, 60)
                            .padding(.bottom, 20)
                        } else {
                            Button(action: onDisconnect) {
                                Text("Disconnect")
                                    .font(.system(size: 16).bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: 300, minHeight: 16)
                                    .padding(.vertical, 12)
                                    .background(Color(hex: "#1D1D1D"))
                                    .cornerRadius(100)
                            }
                            .accessibilityIdentifier(AccessibilityIdentifiers.disconnectButton)
                            .padding(.horizontal, 60)
                            .padding(.bottom, 10)
                        }
                        
                        // Environment Text
                        Text(viewModel.environment)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "#525252"))
                            .padding(.bottom, 30)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                if viewModel.isLoading {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#00E3AA")))
                            .scaleEffect(1.5)
                    }
                }
                
                // Menu Overlay
                OverflowMenuView(
                              showMenu: $showMenu,
                              showPreCallDiagnosisSheet: $showPreCallDiagnosisSheet,
                              showRegionMenu: $showRegionMenu,
                              selectedRegion: $profileViewModel.selectedRegion,
                              showAIAssistant: $showAIAssistant,
                              showCodecSelection: $showCodecSelection,
                              showWebSocketMessages: $showWebSocketMessages,
                              viewModel: viewModel
                          )
                
                RegionMenuView(
                      showRegionMenu: $showRegionMenu,
                      profileViewModel: profileViewModel,
                      isRegionSelectionDisabled: viewModel.isRegionSelectionDisabled
                  )
            }
            .background(Color(hex: "#FEFDF5")).ignoresSafeArea()
            .sheet(isPresented: $showPreCallDiagnosisSheet) {
                PreCallDiagnosisBottomSheet(
                    isPresented: $showPreCallDiagnosisSheet,
                    viewModel: viewModel
                )
            }
            .sheet(isPresented: $showCodecSelection) {
                CodecSelectionView(
                    isPresented: $showCodecSelection,
                    viewModel: viewModel
                )
            }
            .fullScreenCover(isPresented: $showAIAssistant) {
                AIAssistantView(viewModel: aiAssistantViewModel)
            }
            .sheet(isPresented: $showWebSocketMessages) {
                WebSocketMessagesBottomSheet()
            }
        }
    }
    
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
                withAnimation {
                    scrollToKeyboard = true
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            keyboardHeight = 0
            withAnimation {
                scrollToKeyboard = false
            }
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @ViewBuilder
    private func statesView() -> some View {
        VStack {
            Text("Socket")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(Color(hex: "#525252"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)
            
            HStack {
                Circle()
                    .fill(viewModel.socketState == .connected || viewModel.socketState == .clientReady ? Color(hex: "00E3AA") : Color(hex: "D40000"))
                    .frame(width: 8, height: 8)
                Text(socketStateText(for: viewModel.socketState))
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(hex: "1D1D1D"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 5)
            
            // Call State
            if viewModel.socketState == .connected || viewModel.socketState == .clientReady {
                let stateInfo = callStateInfo(for: viewModel.callState)
                Text("Call State")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(hex: "1D1D1D"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 10)
                
                HStack(spacing: 8) {
                    
                    Circle()
                        .fill(stateInfo.color)
                        .frame(width: 8, height: 8)
                    
                    Text(stateInfo.text)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(hex: "1D1D1D"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
            }
            
            // Session
            VStack {
                Text("Session ID")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(Color(hex: "#525252"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 10)
                
                Text(viewModel.sessionId)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(hex: "1D1D1D"))
                    .padding(.top, 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 16)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
        .padding(.horizontal, 30)
    }
    
    
    @ViewBuilder
    private func profileOrCallView(for state: SocketState) -> some View {
        switch state {
            case .disconnected:
                profileView
            case .connected, .clientReady:
                callView
        }
    }
    
    private func socketStateText(for state: SocketState) -> String {
        switch state {
            case .disconnected:
                return "Disconnected"
            case .connected:
                return "Connected"
            case .clientReady:
                return "Client-ready"
        }
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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(
            viewModel: HomeViewModel(),
            profileViewModel: ProfileViewModel(),
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
                    viewModel: CallViewModel(), isPhoneNumber: false,
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
            )
        )
    }
}

