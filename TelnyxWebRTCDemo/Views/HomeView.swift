import SwiftUI

enum SocketState {
    case connected
    case disconnected
}


struct HomeView: View {
    @State private var logoPosition: CGFloat = 0
    @State private var isAnimating: Bool = false
    @State private var textOpacity: Double = 0.0
    
    @Binding var socketState: SocketState
    @Binding var selectedProfile: SipCredential?
    @Binding var sessionId: String

    let onAddProfile: () -> Void
    let onSwitchProfile: () -> Void
    let onConnect: () -> Void
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                VStack {
                    Spacer()
                        .frame(height: isAnimating ? 50 : (geometry.size.height / 2 - 100))
                    Image("telnyx-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                    Spacer()
                        .frame(height: isAnimating ? 0 : (geometry.size.height / 2 - 100))
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
                                        .fill(socketState == .connected ? Color(hex: "00E3AA") : Color(hex: "D40000"))
                                        .frame(width: 8, height: 8)
                                    Text(socketState == .connected ? "Connected" : "Disconnected")
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
                                
                                Text(sessionId)
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundColor(Color(hex: "1D1D1D"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.leading, 30)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Profile
                            VStack {
                                Text("Profile")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundColor(Color(hex: "#525252"))
                                    .padding(.top, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                ZStack {
                                    if selectedProfile == nil {
                                        Button(action: onAddProfile) {
                                            Text("+ Add new profile")
                                                .font(.system(size: 14).bold())
                                                .foregroundColor(Color(hex: "#1D1D1D"))
                                                .frame(width: 150)
                                                .padding(.vertical, 8)
                                                .background(Color(hex: "#F5F3E4"))
                                                .cornerRadius(16)
                                        }
                                    } else {
                                        HStack {
                                            Text(selectedProfile?.username ?? "")
                                                .font(.system(size: 18, weight: .regular))
                                                .foregroundColor(Color(hex: "1D1D1D"))
                                                .frame(maxWidth: 200)
                                                .lineLimit(1)
                                            
                                            Button(action: onSwitchProfile) {
                                                Text("Switch Profile")
                                                    .font(.system(size: 14).bold())
                                                    .foregroundColor(Color(hex: "#1D1D1D"))
                                                    .padding(.vertical, 8)
                                                    .padding(.horizontal, 12)
                                                    .background(Color(hex: "#EBEBEB"))
                                                    .cornerRadius(16)
                                            }
                                            
                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        Spacer()
                                    }
                                }.frame(maxWidth: .infinity, alignment: .leading)
                                
                            }
                            .padding(.leading, 30)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Spacer()
                        }
                        .opacity(textOpacity)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    Spacer()
                    Button(action: onConnect) {
                        Text("Connect")
                            .font(.system(size: 16).bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: 300)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#1D1D1D"))
                            .cornerRadius(20)
                    }.padding(.horizontal, 60)
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
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(
            socketState: .constant(.disconnected),
            selectedProfile: .constant(nil),
            sessionId: .constant("-"),
            onAddProfile: {},
            onSwitchProfile: {},
            onConnect: {}
        )
    }
}
