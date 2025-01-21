import SwiftUI

struct SipCredentialsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var credentialsList: [SipCredential] = []
    @State private var selectedCredential: SipCredential?
    @State private var tempSelectedCredential: SipCredential?
    @State private var isSelectedCredentialChanged = false
    @Binding var isShowingCredentialsInput: Bool
    @State private var internalIsShowingCredentialsInput: Bool
    @State private var viewHeight: CGFloat = 0
    
    let kViewHeight: CGFloat = 300.0
    
    let onCredentialSelected: (SipCredential?) -> Void
    let onSignIn: (SipCredential?) -> Void
    
    init(isShowingCredentialsInput: Binding<Bool>,
         onCredentialSelected: @escaping (SipCredential?) -> Void,
         onSignIn: @escaping (SipCredential?) -> Void) {
        self._isShowingCredentialsInput = isShowingCredentialsInput
        self._internalIsShowingCredentialsInput = State(initialValue: isShowingCredentialsInput.wrappedValue)
        self.onCredentialSelected = onCredentialSelected
        self.onSignIn = onSignIn
    }
    
    var body: some View {
        VStack(spacing: 0) {
            SipCredentialHeader(
                title: "SIP Credentials",
                subtitle: UserDefaults.standard.getEnvironment().toString(),
                onClose: { dismiss() },
                onAddProfile: {
                    withAnimation {
                        internalIsShowingCredentialsInput.toggle()
                        isShowingCredentialsInput = internalIsShowingCredentialsInput
                    }
                }
            )
            if internalIsShowingCredentialsInput {
                SipInputCredentialsView(
                    username: "",
                    password: "",
                    isPasswordVisible: false,
                    hasError: false,
                    onSignIn: { newCredential in
                        onSignIn(newCredential)
                    },
                    onCancel: {
                        withAnimation {
                            internalIsShowingCredentialsInput = false
                            isShowingCredentialsInput = false
                        }
                    }
                )
                .transition(.move(edge: .top))
                .frame(height: viewHeight)
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .offset(y: 0)
                .onAppear {
                    withAnimation{
                        viewHeight = kViewHeight
                    }
                }
                .onDisappear {
                    withAnimation{
                        viewHeight = 0
                    }
                }
                Spacer()
            } else {
                List {
                    Section {
                        if credentialsList.isEmpty && !internalIsShowingCredentialsInput {
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
                                .listRowBackground(Color.white)
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
            
        }
        .onAppear {
            credentialsList = SipCredentialsManager.shared.getCredentials()
            selectedCredential = SipCredentialsManager.shared.getSelectedCredential()
            tempSelectedCredential = selectedCredential
            internalIsShowingCredentialsInput = isShowingCredentialsInput
        }
        .onDisappear {
            if isSelectedCredentialChanged {
                selectedCredential = SipCredentialsManager.shared.getSelectedCredential()
                onCredentialSelected(selectedCredential)
            }
            internalIsShowingCredentialsInput = false
            isShowingCredentialsInput = false
        }
    }
}

// MARK: -
struct SipCredentialsView_Previews: PreviewProvider {
    @State static var isShowingCredentialsInput = true
    
    static var previews: some View {
        SipCredentialsView(
            isShowingCredentialsInput: $isShowingCredentialsInput,
            onCredentialSelected: { _ in },
            onSignIn: { _ in }
        )
    }
}
