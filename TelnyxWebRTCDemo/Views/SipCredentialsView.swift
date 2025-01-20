import SwiftUI

struct SipCredentialsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var credentialsList: [SipCredential] = []
    @State private var selectedCredential: SipCredential?
    @State private var tempSelectedCredential: SipCredential?
    @State private var isSelectedCredentialChanged = false
    @State private var isShowingCredentialsInput = false
    @State private var viewHeight: CGFloat = 0
    
    let onCredentialSelected: (SipCredential?) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            SipCredentialHeader(
                title: "SIP Credentials",
                subtitle: UserDefaults.standard.getEnvironment().toString(),
                onClose: { dismiss() },
                onAddProfile: {
                    withAnimation {
                        isShowingCredentialsInput.toggle()
                    }
                }
            )
            if isShowingCredentialsInput {
                SipInputCredentialsView(
                    username: "",
                    password: "",
                    isPasswordVisible: false,
                    hasError: false,
                    onSignIn: {
                        // Logic for signing in
                    },
                    onCancel: {
                        withAnimation {
                            isShowingCredentialsInput = false
                        }
                    }
                )
                .transition(.move(edge: .top))
                .frame(height: isShowingCredentialsInput ? viewHeight : 0)
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .onAppear {
                    viewHeight = 300 // Set the height you want for the form
                }
            }
            
            List {
                Section {
                    if credentialsList.isEmpty && !isShowingCredentialsInput {
                        Text("No SIP credentials available. Credentials will appear here after using them to connect.")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .listRowBackground(Color.clear)
                            .padding(.vertical, 20)
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(credentialsList, id: \.username) { credential in
                            SipCredentialRow(
                                credential: credential,
                                isSelected: credential.username == tempSelectedCredential?.username,
                                onDelete: {
                                    withAnimation {
                                        if selectedCredential?.username == credential.username {
                                            isSelectedCredentialChanged = true
                                        }
                                        SipCredentialsManager.shared.removeCredential(username: credential.username)
                                        credentialsList = SipCredentialsManager.shared.getCredentials()
                                    }
                                }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                tempSelectedCredential = credential
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(.white)
            .applyScrollContentBackground()

            HStack(spacing: 12) {
                Spacer()
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#1D1D1D"))
                        .frame(width: 100)
                        .padding(.vertical, 12)
                        .background(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "#1D1D1D"), lineWidth: 1)
                        )
                }
                
                Button(action: {
                    if let credential = tempSelectedCredential {
                        SipCredentialsManager.shared.saveSelectedCredential(credential)
                        isSelectedCredentialChanged = true
                    }
                    dismiss()
                }) {
                    Text("Confirm")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 100)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#1D1D1D"))
                        .cornerRadius(20)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.white)
        }
        .onAppear {
            credentialsList = SipCredentialsManager.shared.getCredentials()
            selectedCredential = SipCredentialsManager.shared.getSelectedCredential()
            tempSelectedCredential = selectedCredential
        }
        .onDisappear {

            if isSelectedCredentialChanged {
                selectedCredential = SipCredentialsManager.shared.getSelectedCredential()
                onCredentialSelected(selectedCredential)
            }
        }
    }
       
}

#Preview {
    SipCredentialsView { credential in
        print("Selected credential: \(String(describing: credential?.username))")
    }
}
